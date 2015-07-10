 /*
  * nfs-chk - report on nfs file accessibility
  * 
  * Tries to mount via the portmapper.
  * 
  * Tries to mount as unprivileged user.
  * 
  * Needs to be run by superuser.
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
#include <rpc/pmap_prot.h>

#ifdef TIRPC
#include <sys/tiuser.h>
#include <stropts.h>
#endif

#ifndef  INADDR_NONE
#define  INADDR_NONE     (-1)		/* XXX should be 0xffffffff */
#endif

extern int getopt();
extern int optind;
extern char *optarg;

#include "mount.h"
#include "nfs_prot.h"

static struct timeval timeout = {5, 0};
static int verbose = 0;
static int portmap = 1;
static char *progname;

#define debug if (verbose) printf

#define UNPRIVILEGED_PORT	0
#define PRIVILEGED_PORT		1

struct hostinfo {
    char   *hostname;
    struct sockaddr_in sin;
    CLIENT *mountd_clnt;		/* privileged mount */
    CLIENT *nfsd_clnt;			/* privileged nfs */
    CLIENT *umountd_clnt;		/* unprivileged mount */
    CLIENT *unfsd_clnt;			/* privileged nfs */
};

/* usage - explain and terminate */

void    usage()
{
    fprintf(stderr, "Usage: %s [-p] [-v] [-t timeout] hostname\n", progname);
    exit(1);
}

/* perrorexit - print error and exit */

void    perrorexit(text)
char   *text;
{
    perror(text);
    exit(1);
}

/* clnt_pcreateerrorexit - print error and exit */

void    clnt_pcreateerrorexit(text)
char   *text;
{
    clnt_pcreateerror(text);
    exit(1);
}

/* clnt_perrorexit - print error and exit */

void    clnt_perrorexit(client, text)
CLIENT *client;
char   *text;
{
    clnt_perror(client, text);
    exit(1);
}

/* nfs_perror - print nfs error */

void    nfs_perror(status, text)
int     status;
char   *text;
{
    errno = status;				/* XXX */
    perror(text);
}

/* nfs_perrorexit - print nfs error and exit */

void    nfs_perrorexit(status, text)
int     status;
char   *text;
{
    errno = status;				/* XXX */
    perrorexit(text);
}

/* reserved_port - allocate a privileged port or bust */

int     reserved_port(type, protocol)
int     type;
int     protocol;
{
    struct sockaddr_in sin;
    int     port;
    int     sock;

    if ((sock = socket(AF_INET, type, protocol)) < 0)
	perrorexit("nfs-chk: socket");
    memset((char *) &sin, 0, sizeof(sin));
    sin.sin_family = AF_INET;
    sin.sin_addr.s_addr = 0;

    for (port = IPPORT_RESERVED - 1; port > IPPORT_RESERVED / 2; port--) {
	sin.sin_port = htons((u_short) port);
	if (bind(sock, (struct sockaddr *) & sin, sizeof(sin)) >= 0) {
	    debug("Using privileged port %d\n", port);
	    return (sock);
	}
	if (errno != EADDRINUSE && errno != EADDRNOTAVAIL)
	    break;
    }
    perrorexit("nfs-chk: bind privileged port");
}

/* make_client - create client handle to talk to rpc server */

CLIENT *make_client(addr, program, version, privileged)
struct sockaddr_in *addr;
u_long  program;
u_long  version;
int     privileged;
{
    CLIENT *client;
    int     sock;
    AUTH_GID_T nul = 0;

#if 0
    debug("Trying to set up TCP client handle\n");
    addr->sin_port = 0;
    if (privileged) {
	sock = reserved_port(SOCK_STREAM, IPPROTO_TCP);
    } else {
	sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    }
    if (sock < 0)
	perrorexit("nfs-chk: socket");
#ifdef TIRPC
    ioctl(sock, I_PUSH, "timod");
#endif
    if (client = clnttcp_create(addr, program, version, &sock, 0, 0)) {
	connect(sock, (struct sockaddr *) addr, sizeof(*addr));
	client->cl_auth = authunix_create("", 0, 0, 1, &nul);
	return (client);
    }
    close(sock);
#endif

    debug("Trying to set up UDP client handle\n");
    addr->sin_port = 0;
    if (privileged) {
	sock = reserved_port(SOCK_DGRAM, IPPROTO_UDP);
    } else {
	sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    }
    if (sock < 0)
	perrorexit("nfs-chk: socket");
#ifdef TIRPC
    ioctl(sock, I_PUSH, "timod");
#endif
    if (client = clntudp_create(addr, program, version, timeout, &sock)) {
	client->cl_auth = authunix_create("", 0, 0, 1, &nul);
	return (client);
    }
    close(sock);
    return (0);
}

/* portmap_mount - mount via portmapper */

fhstatus *portmap_mount(path, addr)
char   *path;
struct sockaddr_in *addr;
{
    static fhstatus mount_status;
    u_long  port;

    memset((char *) &mount_status, 0, sizeof(mount_status));
    addr->sin_port = htons(PMAPPORT);

    if (pmap_rmtcall(addr, MOUNTPROG, MOUNTVERS, MOUNTPROC_MNT,
		     xdr_dirpath, &path,
		     xdr_fhstatus, &mount_status,
		     timeout, &port) == 0) {
	return (&mount_status);
    }
    return (0);
}

/* print_attributes - display file modes */

void    print_attributes(ap, path)
fattr  *ap;
char   *path;
{
    char   *cp;
    time_t  seconds;

    switch (ap->type) {
    case NFREG:
	putchar('-');
	break;
    case NFDIR:
	putchar('d');
	break;
    default:
	putchar('?');
	break;
    }
    putchar((ap->mode & 0400) ? 'r' : '-');
    putchar((ap->mode & 0200) ? 'w' : '-');
    putchar((ap->mode & 0100) ?
	    ((ap->mode & 04000) ? 's' : 'x') :
	    ((ap->mode & 04000) ? 'S' : '-'));
    putchar((ap->mode & 040) ? 'r' : '-');
    putchar((ap->mode & 020) ? 'w' : '-');
    putchar((ap->mode & 010) ?
	    ((ap->mode & 02000) ? 's' : 'x') :
	    ((ap->mode & 02000) ? 'S' : '-'));
    putchar((ap->mode & 04) ? 'r' : '-');
    putchar((ap->mode & 02) ? 'w' : '-');
    putchar((ap->mode & 01) ?
	    ((ap->mode & 01000) ? 't' : 'x') :
	    ((ap->mode & 01000) ? 'T' : '-'));
    seconds = ap->ctime.seconds;
    cp = ctime(&seconds);
    printf("%3d %8d %5d %9d %-7.7s %-4.4s %s\n",
	   ap->nlink, ap->uid, ap->gid, ap->size, cp + 4, cp + 20, path);
}

/* show_mount_point - display mount point info */

int     show_mount_point(path, mount_status, client)
char   *path;
fhstatus *mount_status;
CLIENT *client;
{
    attrstat *attr_status;

    if ((attr_status = nfsproc_getattr_2(mount_status->fhstatus_u.fhs_fhandle,
					 client)) == 0) {
	clnt_perror(client, path);
	return (0);
    } else if (attr_status->status != NFS_OK) {
	nfs_perror(attr_status->status, path);
	return (0);
    } else {
	print_attributes(&(attr_status->attrstat_u.attributes), path);
	return (1);
    }
}

/* examine_filesystem - examine exported file system */

void    examine_filesystem(h, path, client_info)
struct hostinfo *h;
char   *path;
groups  client_info;
{
    fhstatus *mount_status;

    if (client_info == 0) {
	printf("Warning: host %s exports %s to the world\n", h->hostname, path);
    } else {
	printf("Examining: %s:%s\n", h->hostname, path);
    }

    if (portmap) {
	debug("Trying to mount %s via portmapper\n", path);
	mount_status = portmap_mount(path, &h->sin);
	if (mount_status != 0 && mount_status->fhs_status == NFS_OK) {
	    if (show_mount_point(path, mount_status, h->nfsd_clnt))
		printf("Warning: host %s exports %s via portmapper\n",
		       h->hostname, path);
	    debug("Unmounting: %s\n", path);
	    mountproc_umnt_1(&path, h->mountd_clnt);
	}
    }
    debug("Trying to mount %s via mountd\n", path);
    mount_status = mountproc_mnt_1(&path, h->mountd_clnt);
    if (mount_status != 0 && mount_status->fhs_status == NFS_OK) {
	if (show_mount_point(path, mount_status, h->nfsd_clnt))
	    printf("Mounted: %s via mount daemon\n", path);
	debug("Unmounting: %s\n", path);
	mountproc_umnt_1(&path, h->mountd_clnt);

	mount_status = mountproc_mnt_1(&path, h->umountd_clnt);
	if (mount_status != 0 && mount_status->fhs_status == NFS_OK) {
	    if (show_mount_point(path, mount_status, h->unfsd_clnt))
		printf("Warning: host %s exports %s to unprivileged programs\n",
		       h->hostname, path);
	    debug("Unmounting: %s\n", path);
	    mountproc_umnt_1(&path, h->umountd_clnt);
	}
    }
}

/* find_host - look up host information */

void    find_host(h)
struct hostinfo *h;
{
    struct hostent *hp;
    long    addr;

    /*
     * Look up IP address information. XXX with multi-homed hosts, should try
     * all addresses until we succeed.
     */

    memset((char *) &h->sin, 0, sizeof(h->sin));
    h->sin.sin_family = AF_INET;

    if ((addr = inet_addr(h->hostname)) != INADDR_NONE) {
	h->sin.sin_addr.s_addr = addr;
    } else if ((hp = gethostbyname(h->hostname)) == 0) {
	fprintf(stderr, "%s: host not found: %s\n", progname, h->hostname);
	exit(1);
    } else {
	memcpy((char *) &h->sin.sin_addr, hp->h_addr, sizeof(h->sin));
    }

    /*
     * Look up mountd and nfsd information.
     */

    debug("Setting up mountd clients\n");
    if ((h->mountd_clnt =
	 make_client(&h->sin, MOUNTPROG, MOUNTVERS, PRIVILEGED_PORT)) == 0)
	clnt_pcreateerrorexit("privileged mountd client create");
    if ((h->umountd_clnt =
	 make_client(&h->sin, MOUNTPROG, MOUNTVERS, UNPRIVILEGED_PORT)) == 0)
	clnt_pcreateerrorexit("unprivileged mountd client create");

    debug("Setting up nfsd clients\n");
    if ((h->nfsd_clnt =
      make_client(&h->sin, NFS_PROGRAM, NFS_VERSION, PRIVILEGED_PORT)) == 0)
	clnt_pcreateerrorexit("privileged nfsd client create");
    if ((h->unfsd_clnt =
    make_client(&h->sin, NFS_PROGRAM, NFS_VERSION, UNPRIVILEGED_PORT)) == 0)
	clnt_pcreateerrorexit("unprivileged nfsd client create");
}

main(argc, argv)
int     argc;
char   *argv[];
{
    exports exp;
    exports *exp_list;
    int     opt;
    struct hostinfo h;

    progname = argv[0];

    /*
     * Parse JCL.
     */

    while ((opt = getopt(argc, argv, "pvt:")) != EOF) {
	switch (opt) {
	case 'p':				/* don't try portmap bug */
	    portmap = 0;
	    break;
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

    if (argc != optind + 1)
	usage();
    h.hostname = argv[optind];

    /*
     * Look up host information. Only the name is stolen from RJN.
     */

    find_host(&h);

    /*
     * For each exported file system, report if we can access it. By way of
     * proof, show an "ls -l" like listing.
     */

    debug("Retrieving exports list\n");
    if ((exp_list = mountproc_export_1(NULL, h.mountd_clnt)) == 0)
	clnt_perrorexit(h.mountd_clnt, "mount export list");
    for (exp = *exp_list; exp; exp = exp->ex_next) {
	examine_filesystem(&h, exp->ex_dir, exp->ex_groups);
    }
}
