 /*
  * Simple NIS map accessibility checker. Prints the first record when it
  * succeeds.
  * 
  * Author: Wietse Venema.
  */

#define PORTMAP

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <rpc/rpc.h>

#ifndef  INADDR_NONE
#define  INADDR_NONE     (-1)		/* XXX should be 0xffffffff */
#endif

extern int getopt();
extern int optind;
extern char *optarg;

#include "yp.h"

static struct timeval timeout = {5, 0};
static int verbose = 0;
static char *progname;

#define debug if (verbose) printf

static void usage()
{
    fprintf(stderr, "usage: %s domain map server\n", progname);
    exit(0);
}

/* perrorexit - print error and exit */

static void perrorexit(text)
char   *text;
{
    perror(text);
    exit(1);
}

/* make_tcp_client - create client handle to talk to rpc server */

static CLIENT *make_tcp_client(addr, program, version)
struct sockaddr_in *addr;
u_long  program;
u_long  version;
{
    int     sock;

    debug("Trying to set up TCP client handle\n");
    addr->sin_port = 0;
    sock = RPC_ANYSOCK;
    return (clnttcp_create(addr, program, version, &sock, 0, 0));
}

/* make_udp_client - create client handle to talk to rpc server */

static CLIENT *make_udp_client(addr, program, version)
struct sockaddr_in *addr;
u_long  program;
u_long  version;
{
    int     sock;

    debug("Trying to set up UDP client handle\n");
    addr->sin_port = 0;
    sock = RPC_ANYSOCK;
    return (clntudp_create(addr, program, version, timeout, &sock));
}

/* find_host - look up host information */

static int find_host(sin, host)
char   *host;
struct sockaddr_in *sin;
{
    struct hostent *hp;

    /*
     * Look up IP address information. XXX with multi-homed hosts, should try
     * all addresses until we succeed.
     */

    memset((char *) sin, 0, sizeof(*sin));
    sin->sin_family = AF_INET;

    debug("Looking up host %s\n", host);
    if ((sin->sin_addr.s_addr = inet_addr(host)) != INADDR_NONE) {
	return (1);
    } else if ((hp = gethostbyname(host)) == 0 || hp->h_addrtype != AF_INET) {
	return (0);
    } else {
	memcpy((char *) &sin->sin_addr, hp->h_addr, sizeof(sin->sin_addr));
	return (1);
    }
}

/* try_map - transfer first map entry */

static int try_map(client, domain, map)
CLIENT *client;
char   *domain;
char   *map;
{
    struct YPreq_nokey nokey;
    struct YPresp_key_val key_val;
    char    keybuf[1024];
    char    valbuf[1024];
    enum clnt_stat status;

    nokey.domain = domain;
    nokey.map = map;

    key_val.key.keydat_val = keybuf;
    key_val.key.keydat_len = sizeof(keybuf);
    key_val.val.valdat_val = valbuf;
    key_val.val.valdat_len = sizeof(valbuf);

    /*
     * Look up the first entry. Sending the call may fail.
     */
    debug("Trying: %s %s\n", domain, map);
    if ((status = clnt_call(client, YPPROC_FIRST, xdr_YPreq_nokey,
			    (char *) &nokey, xdr_YPresp_key_val,
			    (char *) &key_val, timeout)) != RPC_SUCCESS) {
	clnt_perrno(status);
	return (0);
    }

    /*
     * The call itself may fail (wrong domain or map).
     */
    if (key_val.stat != YP_TRUE) {
	fprintf(stderr, "%s: domain %s map %s: failed\n",
		progname, domain, map);
	exit(1);
    }

    /*
     * Show just one entry as proof.
     */
    printf("%.*s\n", key_val.key.keydat_len, key_val.key.keydat_val);
    return (1);
}

main(argc, argv)
int     argc;
char  **argv;
{
    struct sockaddr_in sin;
    CLIENT *client;
    char   *domain;
    char   *map;
    char   *host;
    int     success = 0;
    int     opt;

    progname = argv[0];

    /*
     * Parse JCL.
     */
    while ((opt = getopt(argc, argv, "vt:")) != EOF) {
	switch (opt) {
	case 'v':				/* turn on verbose mode */
	    verbose = 1;
	    break;
	case 't':				/* change timeout */
	    timeout.tv_sec = atoi(optarg);
	    break;
	default:
	    usage();
	    /* NOTREACHED */
	}
    }

    if (argc != optind + 3)
	usage();
    domain = argv[optind];
    map = argv[optind + 1];
    host = argv[optind + 2];

    if (find_host(&sin, host) == 0) {
	fprintf(stderr, "%s: unknown host: %s\n", progname, host);
	exit(1);
    }

    /*
     * Now try each transport until we succeed.
     */
    if ((client = make_tcp_client(&sin, YPPROG, YPVERS)) == 0
	|| (success = try_map(client, domain, map)) == 0)
	if ((client = make_udp_client(&sin, YPPROG, YPVERS)) != 0)
	    success = try_map(client, domain, map);
    exit(success == 0);
}
