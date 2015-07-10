 /*
  * tcp_scan - determine available tcp services, optionally collect banners
  * and detect telnet options
  * 
  * Author: Wietse Venema.
  */

#include <sys/types.h>
#include <sys/param.h>
#include <sys/time.h>
#include <sys/socket.h>

#include <netinet/in.h>
#include <netinet/in_systm.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#include <netinet/tcp.h>

#include <arpa/telnet.h>

#include <stdio.h>
#include <signal.h>
#include <netdb.h>
#include <string.h>
#include <errno.h>

extern int errno;
extern char *optarg;
extern int optind;

#ifndef __STDC__
extern char *strerror();
#endif

#define offsetof(t,m)	(size_t)(&(((t *)0)->m))

#ifndef IPPORT_TELNET
#define IPPORT_TELNET	23
#endif

#ifndef FD_SET
#include <sys/select.h>
#endif

#include "lib.h"

#define BANNER_LENGTH	2048		/* upper bound on banner info */
#define BANNER_TIME	10		/* time for host to send banner */
#define BANNER_IDLE	1		/* delay after last banner info */

#define YES     1
#define NO      0

#define WAIT	1
#define NOWAIT	0

int     verbose;			/* default silent mode */
int     banner_time = BANNER_TIME;	/* banner timeout */
int     open_file_limit;		/* max nr of open files */
int     load_limit;			/* max nr of open sockets */

struct timeval now;			/* banner_info last update time */
fd_set  write_socket_mask;		/* sockets with connect() in progress */
fd_set  read_socket_mask;		/* sockets with connect() finished */
int     ports_busy;			/* number of open sockets */
int     ports_done;			/* number of finished sockets */
int     max_sock;			/* max socket file descriptor */
int     want_err;			/* want good/bad news */
int     show_all;			/* report all ports */

int    *socket_to_port;			/* socket to port number */

typedef struct {
    unsigned char *buf;			/* banner information or null */
    int     count;			/* amount of banner received sofar */
    int     flags;			/* see below */
    struct timeval connect_time;	/* when connect() finished */
    struct timeval read_time;		/* time of last banner update */
} BANNER_INFO;

BANNER_INFO *banner_info = 0;

#define F_TELNET	(1<<0)		/* telnet options seen */

int     icmp_sock;			/* for unreachable reports */
static struct sockaddr_in sin;		/* remote endpoint info */

static char *send_string;		/* string to send */
int response_time;			/* need some response */

#define NEW(type, count) (type *) mymalloc((count) * sizeof(type))

#define time_since(t) (now.tv_sec - t.tv_sec + 1e-6 * (now.tv_usec - t.tv_usec))

/* main - command-line interface */

main(argc, argv)
int     argc;
char   *argv[];
{
    int     c;
    struct protoent *pe;
    char  **ports;

    progname = argv[0];
    if (geteuid())
	error("This program needs root privileges");

    open_file_limit = open_limit();
    load_limit = open_file_limit - 10;

    while ((c = getopt(argc, argv, "abl:s:t:uUvw:")) != EOF) {
	switch (c) {
	case 'a':
	    show_all = 1;
	    break;
	case 'b':
	    if (banner_info == 0)
		banner_info = NEW(BANNER_INFO, open_file_limit);
	    break;
	case 'l':
	    if ((load_limit = atoi(optarg)) <= 0)
		usage("invalid load limit");
	    if (load_limit > open_file_limit - 10)
		load_limit = open_file_limit - 10;
	    break;
	case 's':
	    send_string = optarg;
	    signal(SIGPIPE, SIG_IGN);
	    break;
 	case 't':
	    if ((response_time = atoi(optarg)) <= 0)
		usage("invalid timeout");
	    break;
	case 'u':
	    want_err = EHOSTUNREACH;
	    break;
	case 'U':
	    want_err = ~EHOSTUNREACH;
	    break;
	case 'v':
	    verbose = 1;
	    break;
	case 'w':
	    if ((banner_time = atoi(optarg)) <= 0)
		usage("invalid timeout");
	    break;
	default:
	    usage((char *) 0);
	    break;
	}
    }
    argc -= (optind - 1);
    argv += (optind - 1);
    if (argc < 3)
	usage("missing host or service argument");

    socket_to_port = NEW(int, open_file_limit);

    FD_ZERO(&write_socket_mask);
    FD_ZERO(&read_socket_mask);
    ports_busy = 0;

    /*
     * Allocate the socket to read ICMP replies.
     */
    if ((pe = getprotobyname("icmp")) == 0)
	error("icmp: unknown protocol");
    if ((icmp_sock = socket(AF_INET, SOCK_RAW, pe->p_proto)) < 0)
	error("icmp socket: %m");
    FD_SET(icmp_sock, &read_socket_mask);

    /*
     * Scan the ports.
     */
    memset((char *) &sin, 0, sizeof(sin));
    sin.sin_addr = find_addr(argv[1]);
    sin.sin_family = AF_INET;

    if (response_time > 0)
	alarm(response_time);

    for (ports = argv + 2; *ports; ports++)
	scan_ports(*ports);
    while (ports_busy > 0)
	monitor_ports(WAIT);

    return (0);
}

/* usage - explain command syntax */

usage(why)
char   *why;
{
    if (why)
	remark(why);
    error("usage: %s [-abuU] [-l load] [-w time] host ports...", progname);
}

/* scan_ports - scan ranges of ports */

scan_ports(service)
char   *service;
{
    char   *cp;
    int     min_port;
    int     max_port;
    int     port;
    int     sock;

    /*
     * Translate service argument to range of port numbers.
     */
    if ((cp = strchr(service, '-')) != 0) {
	*cp++ = 0;
	min_port = (service[0] ? ntohs(find_port(service, "tcp")) : 1);
	max_port = (cp[0] ? ntohs(find_port(cp, "tcp")) : 65535);
    } else {
	min_port = max_port = ntohs(find_port(service, "tcp"));
    }

    /*
     * Iterate over each port in the given range. Try to keep as many sockets
     * open at the same time as possible. Gradually increase the number of
     * probes so that they will be spread in time.
     */
    for (port = min_port; port <= max_port; port++) {
	if (verbose)
	    remark("connecting to port %d", port);
	sin.sin_port = htons(port);
	while ((sock = socket(sin.sin_family, SOCK_STREAM, 0)) < 0) {
	    remark("socket: %m");
	    monitor_ports(WAIT);
	}
	add_socket(sock, port);
	non_blocking(sock, YES);
	if (connect(sock, (struct sockaddr *) & sin, sizeof(sin)) < 0
	    && errno != EINPROGRESS) {
	    report_and_drop_socket(sock, errno);
	    continue;
	}
	if (ports_busy < load_limit && ports_busy < ports_done) {
	    monitor_ports(NOWAIT);
	} else {
	    while (ports_busy >= load_limit || ports_busy >= ports_done)
		monitor_ports(WAIT);
	}
    }
}

/* monitor_ports - watch for socket activity */

monitor_ports(wait)
int     wait;
{
    fd_set  read_mask;
    fd_set  write_mask;
    static struct timeval waitsome = {1, 1,};
    static struct timeval waitnot = {0, 0,};
    int     sock;
    char    ch;

    if (banner_info == 0) {

	/*
	 * When a connect() completes, report the socket and get rid of it.
	 */
	write_mask = write_socket_mask;
	read_mask = read_socket_mask;
	if (select(max_sock + 1, &read_mask, &write_mask, (fd_set *) 0,
		   wait ? (struct timeval *) 0 : &waitnot) < 0)
	    error("select: %m");
	if (FD_ISSET(icmp_sock, &read_mask))
	    receive_icmp(icmp_sock);
	for (sock = 0; ports_busy > 0 && sock <= max_sock; sock++) {
	    if (FD_ISSET(sock, &write_mask)) {
		if (read(sock, &ch, 1) < 0 && errno != EWOULDBLOCK && errno != EAGAIN) {
		    report_and_drop_socket(sock, errno);
		} else {
		    report_and_drop_socket(sock, 0);
		}
	    }
	}
    } else {

	/*
	 * When a connect() completes, try to receive some data within
	 * banner_time seconds. Assume we have received all banner data when
	 * a socket stops sending for BANNER_IDLE seconds.
	 */
	write_mask = write_socket_mask;
	read_mask = read_socket_mask;
	if (select(max_sock + 1, &read_mask, &write_mask, (fd_set *) 0,
		   wait ? &waitsome : &waitnot) < 0)
	    error("select: %m");
	if (FD_ISSET(icmp_sock, &read_mask))
	    receive_icmp(icmp_sock);
	gettimeofday(&now, (struct timezone *) 0);
	for (sock = 0; ports_busy > 0 && sock <= max_sock; sock++) {
	    if (sock == icmp_sock)
		continue;
	    if (FD_ISSET(sock, &write_mask)) {
		FD_CLR(sock, &write_socket_mask);
		FD_SET(sock, &read_socket_mask);
		banner_info[sock].connect_time = now;
		if (send_string)
		    do_send_string(sock);
	    } else if (FD_ISSET(sock, &read_mask)) {
		switch (read_socket(sock)) {
		case -1:
		    if (errno != EWOULDBLOCK && errno != EAGAIN)
			report_and_drop_socket(sock, errno);
		    break;
		case 0:
		    report_and_drop_socket(sock, 0);
		    break;
		}
	    } else if (FD_ISSET(sock, &read_socket_mask)) {
		if (time_since_connect(sock) > banner_time
		    || time_since_read(sock) > BANNER_IDLE)
		    report_and_drop_socket(sock, 0);
	    }
	}
    }
}

/* read_socket - read data from server */

read_socket(sock)
int     sock;
{
    BANNER_INFO *bp = banner_info + sock;
    unsigned char *cp;
    int     len;
    int     count;

    if (bp->buf == 0)
	bp->buf = (unsigned char *) mymalloc(BANNER_LENGTH);
    cp = bp->buf + bp->count;
    len = BANNER_LENGTH - bp->count;

    if (len == 0)
	return (0);

    bp->read_time = now;

    /*
     * Process banners with one-character reads so that we can detect telnet
     * options.
     */

    if ((count = read(sock, cp, 1)) == 1) {
	if (cp[0] == IAC) {
	    if ((count = read(sock, cp + 1, 2)) == 2) {
		if (cp[1] == WILL || cp[1] == WONT) {
		    cp[1] = DONT;
		    bp->flags |= F_TELNET;
		    write(sock, cp, 3);
		} else if (cp[1] == DO || cp[1] == DONT) {
		    cp[1] = WONT;
		    bp->flags |= F_TELNET;
		    write(sock, cp, 3);
		}
	    }
	} else {				/* cp[0] != IAC */
	    bp->count++;
	}
    }
    return (count);
}

/* report_and_drop_socket - report what we know about this service */

report_and_drop_socket(sock, err)
int     sock;
int     err;
{
    alarm(0);

    if (show_all || want_err == err || (want_err < 0 && want_err != ~err)) {
	struct servent *sp;
	int     port = socket_to_port[sock];

	printf("%d:%s:", port, (sp = getservbyport(htons(port), "tcp")) != 0 ?
	       sp->s_name : "UNKNOWN");
	if (banner_info) {
	    BANNER_INFO *bp = banner_info + sock;

	    if (bp->flags & F_TELNET)
		putchar('t');
	    putchar(':');
	    if (bp->count > 0)
		print_data(stdout, bp->buf, bp->count);
	}
	if (err && show_all)
	    printf("%s", strerror(err));
	printf("\n");
	fflush(stdout);
    }
    drop_socket(sock);
}

/* add_socket - say this socket is being connected */

add_socket(sock, port)
int     sock;
int     port;
{
    BANNER_INFO *bp;

    socket_to_port[sock] = port;
    if (banner_info) {
	bp = banner_info + sock;
	bp->count = 0;
	bp->buf = 0;
	bp->flags = 0;
    }
    FD_SET(sock, &write_socket_mask);
    if (sock > max_sock)
	max_sock = sock;
    ports_busy++;
}

/* drop_socket - release socket resources */

drop_socket(sock)
int     sock;
{
    BANNER_INFO *bp;

    if (banner_info && (bp = banner_info + sock)->buf)
	free((char *) bp->buf);
    close(sock);
    FD_CLR(sock, &read_socket_mask);
    FD_CLR(sock, &write_socket_mask);
    ports_busy--;
    ports_done++;
}

/* time_since_read - how long since read() completed? */

time_since_read(sock)
int     sock;
{
    BANNER_INFO *bp = banner_info + sock;

    return (bp->count == 0 ? 0 : time_since(bp->read_time));
}

/* time_since_connect - how long since connect() completed? */

time_since_connect(sock)
int     sock;
{
    BANNER_INFO *bp = banner_info + sock;

    return (time_since(bp->connect_time));
}

/* receive_icmp - receive and decode ICMP message */

receive_icmp(sock)
int     sock;
{
    union {
	char    chars[BUFSIZ];
	struct ip ip;
    }       buf;
    int     data_len;
    int     hdr_len;
    struct ip *ip;
    struct icmp *icmp;
    struct tcphdr *tcp;
    int     port;

    if ((data_len = recv(sock, (char *) &buf, sizeof(buf), 0)) < 0) {
	error("error: recv: %m");
	return;
    }

    /*
     * Extract the IP header.
     */
    ip = &buf.ip;
    if (ip->ip_p != IPPROTO_ICMP) {
	error("error: not ICMP proto (%d)", ip->ip_p);
	return;
    }

    /*
     * Extract the IP payload.
     */
    hdr_len = ip->ip_hl << 2;
    if (data_len - hdr_len < ICMP_MINLEN) {
	remark("short ICMP packet (%d bytes)", data_len);
	return;
    }
    icmp = (struct icmp *) ((char *) ip + hdr_len);
    data_len -= hdr_len;

    if (icmp->icmp_type != ICMP_UNREACH)
	return;

    /*
     * Extract the offending IP packet header.
     */
    if (data_len < offsetof(struct icmp, icmp_ip) + sizeof(icmp->icmp_ip)) {
	remark("short IP header in ICMP");
	return;
    }
    ip = &(icmp->icmp_ip);
    if (ip->ip_p != IPPROTO_TCP)
	return;
    if (ip->ip_dst.s_addr != sin.sin_addr.s_addr)
	return;

    /*
     * Extract the offending TCP packet header.
     */
    hdr_len = ip->ip_hl << 2;
    tcp = (struct tcphdr *) ((char *) ip + hdr_len);
    data_len -= hdr_len;
    if (data_len < offsetof(struct tcphdr, th_dport) + sizeof(tcp->th_dport)) {
	remark("short TCP header in ICMP");
	return;
    }

    /*
     * Process ICMP subcodes.
     */
    switch (icmp->icmp_code) {
    case ICMP_UNREACH_NET:
    case ICMP_UNREACH_PROTOCOL:
	/* error("error: network or protocol unreachable"); */
	/* NOTREACHED */
    case ICMP_UNREACH_PORT:
    case ICMP_UNREACH_HOST:
	port = ntohs(tcp->th_dport);
	for (sock = 0; sock < open_file_limit; sock++)
	    if (socket_to_port[sock] == port) {
		report_and_drop_socket(sock, EHOSTUNREACH);
		return;
	    }
	break;
    }
}

/* do_send_string - send the send string */

do_send_string(sock)
int     sock;
{
    char    buf[BUFSIZ];
    char   *cp = buf;
    char    ch;
    int     c;
    int     i;
    char   *s = send_string;

    while (*s && cp < buf + sizeof(buf) - 1) {	/* don't overflow the buffer */

	if (*s != '\\') {			/* ordinary character */
	    *cp++ = *s++;
	} else if (isdigit(*++s) && *s < '8') {	/* \nnn octal code */
	    sscanf(s, "%3o", &c);
	    *cp++ = c;
	    for (i = 0; i < 3 && isdigit(*s) && *s < '8'; i++)
		s++;
	} else if ((ch = *s++) == 0) {		/* at string terminator */
	    break;
	} else if (ch == 'b') {			/* \b becomes backspace */
	    *cp++ = '\b';
	} else if (ch == 'f') {			/* \f becomes formfeed */
	    *cp++ = '\f';
	} else if (ch == 'n') {			/* \n becomes newline */
	    *cp++ = '\n';
	} else if (ch == 'r') {			/* \r becomes carriage ret */
	    *cp++ = '\r';
	} else if (ch == 's') {			/* \s becomes blank */
	    *cp++ = ' ';
	} else if (ch == 't') {			/* \t becomes tab */
	    *cp++ = '\t';
	} else {				/* \any becomes any */
	    *cp++ = ch;
	}
    }
    write(sock, buf, cp - buf);
}
