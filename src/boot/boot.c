 /*
  * Usage: boot bootclient bootserver
  * 
  * Executes a bootparam WHOAMI request and print the results.
  */

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <rpc/rpc.h>
#include "bootparam_prot.h"

main(argc, argv)
int     argc;
char   *argv[];
{
    int     stat;
    char    host[256];
    struct hostent *hp;
    static struct bp_whoami_arg bp_arg;
    static struct bp_whoami_res bp_res;
    char   *domain;
    char   *strchr();
    char   *clnt_sperrno();
    char   *me = argv[0];
    char   *client = argv[1];
    char   *server = argv[2];
    long    addr;

    if (argc != 3) {
	fprintf(stderr, "Usage: %s bootclient bootserver\n", me);
	exit(1);
    }
    /* Find out the bootserver's official host name. */
    if ((hp = gethostbyname(server)) == NULL) {
	fprintf(stderr, "Host %s not found.\n", server);
	exit(1);
    }
    /* If bootclient name isn't in FQDN form, append domain from server. */
    if (strchr(client, '.') == 0 && (domain = strchr(hp->h_name, '.')) != 0) {
	sprintf(host, "%s%s", client, domain);
	client = host;
    }
    /* Find out the bootclient's address. Assume it has only one. */
    if ((hp = gethostbyname(client)) != NULL) {
	memcpy((caddr_t) & bp_arg.client_address.bp_address_u.ip_addr,
	       hp->h_addr_list[0], hp->h_length);
    } else if ((addr = inet_addr(client)) != -1) {
	memcpy((caddr_t) & bp_arg.client_address.bp_address_u.ip_addr,
	       &addr, sizeof(addr));
    } else {
	fprintf(stderr, "Host %s not found.\n", client);
	return (1);
    }
    bp_arg.client_address.address_type = IP_ADDR_TYPE;
    bp_res.client_name = 0;			/* allocate buffer */
    bp_res.domain_name = 0;			/* allocate buffer */

    if (stat = callrpc(server,
		       BOOTPARAMPROG, BOOTPARAMVERS,
		       BOOTPARAMPROC_WHOAMI,
		       xdr_bp_whoami_arg, &bp_arg,
		       xdr_bp_whoami_res, &bp_res)) {
	fprintf(stderr,
		"me: cannot contact bootparam server at %s for %s: %s\n",
		server, client, clnt_sperrno(stat));
	return (1);
    }
    printf("client_name: %s\n", bp_res.client_name);
    printf("domain_name: %s\n", bp_res.domain_name);
    printf("router_addr: %d.%d.%d.%d\n",
	   (bp_res.router_address.bp_address_u.ip_addr.net & 0377),
	   (bp_res.router_address.bp_address_u.ip_addr.host & 0377),
	   (bp_res.router_address.bp_address_u.ip_addr.lh & 0377),
	   (bp_res.router_address.bp_address_u.ip_addr.impno & 0377));
    return (0);
}
