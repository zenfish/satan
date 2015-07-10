 /*
  * udp-scan - determine available udp services
  * 
  * Author: Wietse Venema.
  */

#include <sys/types.h>
#include <sys/param.h>
#include <sys/socket.h>
#include <sys/time.h>

#include <netinet/in_systm.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#include <netinet/udp.h>

#include <errno.h>
#include <netdb.h>
#include <stdio.h>
#include <string.h>

extern int errno;

#ifndef __STDC__
extern char *strerror();
#endif

extern char *optarg;
extern int optind;

#define offsetof(t,m)	(size_t)(&(((t *)0)->m))

#ifndef FD_SET
#include <sys/select.h>
#endif

#include "lib.h"

#define LOAD_LIMIT	100		/* default max nr of open sockets */
#define AVG_MARGIN	10		/* safety margin */

 /*
  * In order to protect ourselves against dead hosts, we first probe UDP port
  * 1. If we do not get an ICMP error (no listener or host unreachable) we
  * assume this host is dead. If we do get an ICMP error, we have an estimate
  * of the roundtrip time. The test port can be changed with the -p option.
  */
char   *test_port = "1";
int     test_portno;

#define YES     1
#define NO      0

int     verbose = 0;			/* default silent mode */
int     open_file_limit;		/* max nr of open files */

 /*
  * We attempt to send as many probes per roundtrip time as network capacity
  * permits. With UDP we must do our own retransmission and congestion
  * handling.
  */
int     hard_limit = LOAD_LIMIT;	/* max nr of open sockets */
int     soft_limit;			/* slowly-moving load limit */

struct timeval now;			/* global time after select() */
int     ports_busy;			/* number of open sockets */
int     want_err = 0;			/* show reachable/unreachable */
int     show_all = 0;			/* show all ports */

 /*
  * Information about ongoing probes is sorted by time of last transmission.
  */
struct port_info {
    RING    ring;			/* round-robin linkage */
    struct timeval last_probe;		/* time of last probe */
    int     port;			/* port number */
    int     pkts;			/* number of packets sent */
};

struct port_info *port_info = 0;
RING    active_ports;			/* active sockets list head */
RING    dead_ports;			/* dead sockets list head */
struct port_info *find_port_info();	/* retrieve port info */

 /*
  * Performance statistics. These are used to update the transmission window
  * size depending on transmission error rates.
  */
double  avg_irt = 0;			/* inter-reply arrival time */
double  avg_rtt = 0;			/* round-trip time */
double  avg_pkts = 1;			/* number of packets sent per reply */
int     probes_sent = 0;		/* probes sent */
int     probes_done = 0;		/* finished probes */
int     replies;			/* number of good single probes */
struct timeval last_reply;		/* time of last reply */

int     send_sock;			/* send probes here */
int     icmp_sock;			/* read replies here */
fd_set  icmp_sock_mask;			/* select() read mask */
static struct sockaddr_in sin;

 /*
  * Helpers...
  */

#define time_since(t) (now.tv_sec - t.tv_sec + 1e-6 * (now.tv_usec - t.tv_usec))
#define sock_age(sp) time_since(sp->last_probe)
double  average();
struct port_info *add_port();

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

    while ((c = getopt(argc, argv, "al:p:uUv")) != EOF) {
	switch (c) {
	case 'a':
	    show_all = 1;
	    break;
	case 'l':
	    if ((hard_limit = atoi(optarg)) <= 0)
		usage("invalid load limit");
	    break;
	case 'p':
	    test_port = optarg;
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
	default:
	    usage((char *) 0);
	    break;
	}
    }
    argc -= (optind - 1);
    argv += (optind - 1);
    if (argc < 3)
	usage("missing argument");

    if (hard_limit > open_file_limit - 10)
	hard_limit = open_file_limit - 10;
    soft_limit = hard_limit + 1;
    init_port_info();

    if ((pe = getprotobyname("icmp")) == 0)
	error("icmp: unknown protocol");
    if ((icmp_sock = socket(AF_INET, SOCK_RAW, pe->p_proto)) < 0)
	error("icmp socket: %m");
    FD_ZERO(&icmp_sock_mask);
    FD_SET(icmp_sock, &icmp_sock_mask);

    if ((send_sock = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
	error("socket: %m");

    /*
     * First do a test probe to see if the host is up, and to establish the
     * round-trip time. This requires that the test port is not used.
     */
    memset((char *) &sin, 0, sizeof(sin));
    sin.sin_addr = find_addr(argv[1]);
    sin.sin_family = AF_INET;

    gettimeofday(&now, (struct timezone *) 0);
    last_reply = now;

    /*
     * Calibrate round-trip time and dead time.
     */
    for (;;) {
	scan_ports(test_port);
	while (ports_busy > 0)
	    monitor_ports();
	if (avg_rtt)
	    break;
	sleep(1);
    }
    scan_ports(test_port);

    /*
     * Scan those ports.
     */
    for (ports = argv + 2; *ports; ports++)
	scan_ports(*ports);

    /*
     * All ports probed, wait for replies to trickle back.
     */
    while (ports_busy > 0)
	monitor_ports();

    return (0);
}

/* usage - explain command syntax */

usage(why)
char   *why;
{
    if (why)
	remark(why);
    error("usage: %s [-apuU] [-l load] host ports...", progname);
}

/* scan_ports - scan ranges of ports */

scan_ports(service)
char   *service;
{
    char   *cp;
    int     min_port;
    int     max_port;
    int     port;
    struct port_info *sp;

    if (service == test_port)
	test_portno = atoi(test_port);

    /*
     * Translate service argument to range of port numbers.
     */
    if ((cp = strchr(service, '-')) != 0) {
	*cp++ = 0;
	min_port = (service[0] ? ntohs(find_port(service, "udp")) : 1);
	max_port = (cp[0] ? ntohs(find_port(cp, "udp")) : 65535);
    } else {
	min_port = max_port = ntohs(find_port(service, "udp"));
    }

    /*
     * Iterate over each port in the given range. Adjust the number of
     * simultaneous probes to the capacity of the network.
     */
    for (port = min_port; port <= max_port; port++) {
	sp = add_port(port);
	write_port(sp);
	monitor_ports();
    }
}

/* monitor_ports - watch for socket activity */

monitor_ports()
{
    do {
	struct port_info *sp;

	/*
	 * When things become quiet, examine the port that we haven't looked
	 * at for the longest period of time.
	 */
	receive_answers();

	if (ports_busy == 0)
	    return;

	sp = (struct port_info *) ring_succ(&active_ports);
	if (sp->pkts > avg_pkts * AVG_MARGIN) {
	    report_and_drop_port(sp, 0);
	} else

	    /*
	     * Strategy depends on whether transit times dominate (probe
	     * multiple ports in parallel, retransmit when no reply was
	     * received for at least one round-trip period) or by dead time
	     * (probe one port at a time, retransmit when no reply was
	     * received for some fraction of the inter-reply period).
	     */
	    if (sock_age(sp) > (avg_rtt == 0 ? 1 :
				2 * avg_rtt < avg_irt ? avg_irt / 4 :
				1.5 * avg_rtt)) {
	    write_port(sp);
	}

	/*
	 * When all ports being probed seem to be active, send a test probe
	 * to see if the host is still alive.
	 */
	if (time_since(last_reply) > 3 * (avg_rtt == 0 ? 1 :
				      avg_rtt < avg_irt ? avg_irt : avg_rtt)
	    && find_port_info(test_portno) == 0) {
	    last_reply = now;
	    write_port(add_port(test_portno));
	}
    } while (ports_busy && (ports_busy >= hard_limit
			    || ports_busy >= probes_done
			    || ports_busy >= soft_limit));
}

/* receive_answers - receive reactions to probes */

receive_answers()
{
    fd_set  read_mask;
    struct timeval waitsome;
    double  delay;
    int     answers;

    /*
     * The timeout is less than the inter-reply arrival time or we would not
     * be able to increase the load.
     */
    delay = (2 * avg_rtt < avg_irt ? avg_irt / 3 : avg_rtt / (1 + ports_busy * 4));
    waitsome.tv_sec = delay;
    waitsome.tv_usec = (delay - waitsome.tv_sec) * 1000000;

    read_mask = icmp_sock_mask;
    if ((answers = select(icmp_sock + 1, &read_mask, (fd_set *) 0, (fd_set *) 0,
			  &waitsome)) < 0)
	error("select: %m");

    gettimeofday(&now, (struct timezone *) 0);

    /*
     * For each answer that we receive without retransmissions, update the
     * average roundtrip time.
     */
    if (answers > 0) {
	if (FD_ISSET(icmp_sock, &read_mask))
	    receive_icmp(icmp_sock);
    }
    return (answers);
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
    struct udphdr *udp;
    struct port_info *sp;

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
     * Extract the offending IP header.
     */
    if (data_len < offsetof(struct icmp, icmp_ip) + sizeof(icmp->icmp_ip)) {
	remark("short IP header in ICMP");
	return;
    }
    ip = &(icmp->icmp_ip);
    if (ip->ip_p != IPPROTO_UDP)
	return;
    if (ip->ip_dst.s_addr != sin.sin_addr.s_addr)
	return;

    /*
     * Extract the offending UDP header.
     */
    hdr_len = ip->ip_hl << 2;
    udp = (struct udphdr *) ((char *) ip + hdr_len);
    data_len -= hdr_len;
    if (data_len < sizeof(struct udphdr)) {
	remark("short UDP header in ICMP");
	return;
    }

    /*
     * Process ICMP subcodes.
     */
    switch (icmp->icmp_code) {
    case ICMP_UNREACH_NET:
	error("error: network unreachable");
	/* NOTREACHED */
    case ICMP_UNREACH_HOST:
	if (sp = find_port_info(ntohs(udp->uh_dport)))
	    process_reply(sp, EHOSTUNREACH);
	break;
    case ICMP_UNREACH_PROTOCOL:
	error("error: protocol unreachable");
	/* NOTREACHED */
    case ICMP_UNREACH_PORT:
	if (sp = find_port_info(ntohs(udp->uh_dport)))
	    process_reply(sp, ECONNREFUSED);
	break;
    }
}

/* process_reply - process reply */

process_reply(sp, err)
struct port_info *sp;
int     err;
{
    double  age = sock_age(sp);
    int     pkts = sp->pkts;
    double  irt = time_since(last_reply);

    /*
     * Don't believe everything.
     */
    if (age > 5) {
	age = 5;
    } else if (age < 0) {
	age = 1;
    }
    if (irt > 5) {
	irt = 5;
    } else if (irt < 0) {
	irt = 1;
    }

    /*
     * We jump some hoops for calibration purposes. First we estimate the
     * round-trip time: we use this to decide when to retransmit when network
     * transit time dominates.
     * 
     * Next thing to do is to estimate the inter-reply time, in case the sender
     * has a "dead time" for ICMP replies; I have seen this happen with some
     * Cisco routers and with Solaris 2.4. The first reply will come fast;
     * subsequent probes will be ignored for a period of up to one second.
     * When this happens the retransmission period should be based on the
     * inter-reply time and not on the average round-trip time.
     */
    last_reply = now;
    replies++;
    if (pkts == 1)
	avg_rtt = (avg_rtt == 0 ? age :		/* adopt initial rtt */
		   average(age, avg_rtt));	/* normal processing */
    avg_irt = (avg_irt == 0 ? 1 :		/* prepare for irt
						 * calibration */
	       avg_irt == 1 ? irt :		/* adopt initial irt */
	       average(irt, avg_irt));		/* normal processing */
    avg_pkts = average((double) pkts, avg_pkts);
    if (verbose)
	printf("%d:age %.3f irt %.3f pkt %d ports %2d soft %2d done %2d avrtt %.3f avpkt %.3f avirt %.3f\n",
	       sp->port, age, irt, pkts,
	       ports_busy, soft_limit,
	       probes_done, avg_rtt, avg_pkts, avg_irt);
    report_and_drop_port(sp, err);
}

/* report_and_drop_port - report what we know about this service */

report_and_drop_port(sp, err)
struct port_info *sp;
int     err;
{
    struct servent *se;

    if (probes_done == 0) {
	if (err == 0)
	    error("are we talking to a dead host or network?");
    } else if (show_all || want_err == err || (want_err < 0 && want_err != ~err)) {
	printf("%d:%s:", sp->port,
	       (se = getservbyport(htons(sp->port), "udp")) ?
	       se->s_name : "UNKNOWN");
	if (err && show_all)
	    printf("%s", strerror(err));
	printf("\n");
	fflush(stdout);
    }
    drop_port(sp);
}

/* average - quick-rise, slow-decay moving average */

double  average(new, old)
double  new;
double  old;
{
    if (new > old) {				/* quick rise */
	return ((new + old) / 2);
    } else {					/* slow decay */
	return (0.1 * new + 0.9 * old);
    }
}

/* add_port - say this port is being probed */

struct port_info *add_port(port)
int     port;
{
    struct port_info *sp = (struct port_info *) ring_succ(&dead_ports);

    ring_detach((RING *) sp);
    sp->port = port;
    sp->pkts = 0;
    ports_busy++;
    ring_append(&active_ports, (RING *) sp);
    return (sp);
}

/* write_port - write to port, update statistics */

write_port(sp)
struct port_info *sp;
{
    char    ch = 0;

    ring_detach((RING *) sp);
    sin.sin_port = htons(sp->port);
    sp->last_probe = now;
    sendto(send_sock, &ch, 1, 0, (struct sockaddr *) & sin, sizeof(sin));
    probes_sent++;
    sp->pkts++;
    ring_prepend(&active_ports, (RING *) sp);

    /*
     * Reduce the sending window when the first retransmission happens. Back
     * off when retransmissions dominate. Occasional retransmissons will keep
     * the load unchanged.
     */
    if (sp->pkts > 1) {
	replies--;
	if (soft_limit > hard_limit) {
	    soft_limit = (ports_busy + 1) / 2;
	} else if (replies < 0 && avg_irt) {
	    soft_limit = 0.5 + 0.5 * (soft_limit + avg_rtt / avg_irt);
	    replies = soft_limit / 2;
	}
    }
}

/* drop_port - release port info, update statistics */

drop_port(sp)
struct port_info *sp;
{
    ports_busy--;
    probes_done++;
    ring_detach((RING *) sp);
    ring_append(&dead_ports, (RING *) sp);

    /*
     * Increase the load when a sufficient number of probes succeeded.
     * Occasional retransmissons will keep the load unchanged.
     */
    if (replies > soft_limit) {
	replies = soft_limit / 2;
	if (soft_limit < hard_limit)
	    soft_limit++;
    }
}

/* init_port_info - initialize port info pool */

init_port_info()
{
    struct port_info *sp;

    port_info = (struct port_info *) mymalloc(hard_limit * sizeof(*port_info));
    ring_init(&active_ports);
    ring_init(&dead_ports);
    for (sp = port_info; sp < port_info + hard_limit; sp++)
	ring_append(&dead_ports, (RING *) sp);
}

/* find_port_info - lookup port info */

struct port_info *find_port_info(port)
int     port;
{
    struct port_info *sp;

    for (sp = (struct port_info *) ring_succ(&active_ports);
	 sp != (struct port_info *) & active_ports;
	 sp = (struct port_info *) ring_succ((RING *) sp))
	if (sp->port == port)
	    return (sp);
    return (0);
}
