 /*
  * rex - simplified rexd client. Usage: rex [-a authinfo] server command...
  * 
  * Author: Wietse Venema
  */

/* System libraries. */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <netdb.h>
#include <memory.h>
#include <string.h>

 /*
  * Sun now wants us to #define PORTMAP or things fall apart.
  */
#define PORTMAP
#include <rpc/rpc.h>

extern int optind;
extern char *optarg;

 /*
  * Many <rpc/rex.h> versions depend on the historical sgttyb
  * terminal control structure. We must use our on version.
  */

#include "rex.h"

/* Local stuff. */

static char *progname;
static CLIENT *rex_server();
static AUTH *rex_auth();
static int rex_command();
static void rex_startup();
static void do_io();
static int rex_exit();
static int stream_port();

/* Defaults. */

static struct timeval timeout = {10, 0};

static char *serv_env[] = {
    "PATH=/usr/ucb:/bin:/usr/bin",
    0,
};

static void usage()
{
    printf("Usage: %s [-a authinfo] server command...\n", progname);
    exit(1);
}

main(argc, argv)
int     argc;
char  **argv;
{
    int     c;
    CLIENT *client;
    int     server_sock;
    char   *auth = 0;

    progname = argv[0];

    while ((c = getopt(argc, argv, "a:")) != EOF) {
	switch (c) {
	case 'a':
	    auth = optarg;
	    break;
	default:
	    usage();
	}
    }
    argc -= optind;
    argv += optind;
    if (argc < 2)
	usage();

    /* Establish rexd server, run command, and clean up. */

    client = rex_server(argv[0]);
    client->cl_auth = (auth == 0) ? authunix_create_default() : rex_auth(auth);
    server_sock = rex_command(client, argv[0], argv + 1);
    do_io(server_sock);
    return (rex_exit(client, server_sock));
}

/* rex_server - establish rexd server instance */

static CLIENT *rex_server(server_name)
char   *server_name;
{
    struct hostent *hp;
    struct sockaddr_in server_addr;
    int     sock = RPC_ANYSOCK;
    CLIENT *client;

    /* Find server's IP address. */

    if ((hp = gethostbyname(server_name)) == 0) {
	fprintf(stderr, "%s: host not found\n", server_name);
	exit(1);
    }
    /* XXX should iterate over all IP addresses. */

    server_addr.sin_family = AF_INET;
    memcpy((caddr_t) & server_addr.sin_addr, hp->h_addr, hp->h_length);
    server_addr.sin_port = 0;

    if ((client = clnttcp_create(&server_addr,
				 REXPROG, REXVERS,
				 &sock, 0, 0)) == 0) {
	fprintf(stderr, "%s: ", server_name);
	clnt_pcreateerror(server_name);
	fprintf(stderr, "\n");
	exit(1);
    }
    return (client);
}

/* rex_auth - handle explicit credentials */

static AUTH *rex_auth(auth)
char   *auth;
{
    char    host[BUFSIZ];
    int     uid;
    AUTH_GID_T gid;

    if (sscanf(auth, "%[^,],%d,%d", host, &uid, &gid) != 3)
	usage();
    return (authunix_create(host, uid, gid, 1, &gid));
}

/* rex_command - open socket to remote command */

static int rex_command(client, server_name, command)
CLIENT *client;
char   *server_name;
char  **command;
{
    static rex_start rx_start;
    static rex_result rx_result;
    enum clnt_stat stat;
    int     sock;
    int     server_sock;
    char    cwd_host[BUFSIZ];
    char  **cpp;

    sscanf(server_name, "%[^.]", cwd_host);	/* XXX for old servers */

    rx_start.rst_cmd.rst_cmd_val = command;
    for (cpp = command; *cpp; cpp++)
	 /* void */ ;
    rx_start.rst_cmd.rst_cmd_len = cpp - command;
    rx_start.rst_host = cwd_host;		/* cwd server */
    rx_start.rst_fsname = "";			/* cwd file system */
    rx_start.rst_dirwithin = "";		/* cwd offset */
    rx_start.rst_env.rst_env_val = serv_env;
    for (cpp = serv_env; *cpp; cpp++)
	 /* void */ ;
    rx_start.rst_env.rst_env_len = cpp - serv_env;
    rx_start.rst_port0 = stream_port(&sock);
    rx_start.rst_port1 = rx_start.rst_port0;
    rx_start.rst_port2 = rx_start.rst_port1;
    rx_start.rst_flags = 0;

    if (stat = clnt_call(client, REXPROC_START,
			 xdr_rex_start, (void *) &rx_start,
			 xdr_rex_result, (void *) &rx_result,
			 timeout)) {
	fprintf(stderr, "%s: ", progname);
	clnt_perrno(stat);
	fprintf(stderr, "\n");
	exit(1);
    }
    if (rx_result.rlt_stat) {
	fprintf(stderr, "%s: %s\n", progname, rx_result.rlt_message);
	exit(1);
    }
    if ((server_sock = accept(sock, (struct sockaddr *) 0, (int *) 0)) < 0) {
	perror("accept");
	exit(1);
    }
    close(sock);
    return (server_sock);
}

/* do_io - shuffle bits across the network */

static void do_io(sock)
int     sock;
{
    char    buf[BUFSIZ];
    int     count;

    shutdown(sock, 1);				/* make server read EOF */
    while ((count = read(sock, buf, sizeof(buf))) > 0)
	write(1, buf, count);
}

/* rex_exit - terminate remote command and get its exit status */

static int rex_exit(client, server_sock)
CLIENT *client;
int     server_sock;
{
    static struct rex_result rx_result;
    enum clnt_stat stat;

    close(server_sock);
    if (stat = clnt_call(client, REXPROC_WAIT,
			 xdr_void, (void *) 0,
			 xdr_rex_result, (void *) &rx_result,
			 timeout)) {
	fprintf(stderr, "%s ", progname);
	clnt_perrno(stat);
	fprintf(stderr, "\n");
	exit(1);
    }
    return (rx_result.rlt_stat);
}

/* stream_port - create ready-to-accept socket and return port number */

static int stream_port(sockp)
int    *sockp;
{
    struct sockaddr_in sin;
    int     sock;
    int     len;

    /* Create socket. */

    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
	perror("socket");
	exit(1);
    }
    /* Bind the socket to some random port. */

    memset((char *) &sin, 0, sizeof(sin));
    sin.sin_family = AF_INET;
    if (bind(sock, (struct sockaddr *) & sin, sizeof(sin)) < 0) {
	perror("bind");
	exit(1);
    }
    /* Find out the socket's port number. */

    len = sizeof(sin);
    if (getsockname(sock, (struct sockaddr *) & sin, &len) < 0) {
	perror("getsockname");
	exit(1);
    }
    /* Make the socket ready to receive connections. */

    if (listen(sock, 1) < 0) {
	perror("listen");
	exit(1);
    }
    *sockp = sock;
    return (htons(sin.sin_port));
}
