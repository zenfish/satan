 /*
  * find_addr, find_port - map internet hosts and services to internal form
  * 
  * Author: Wietse Venema.
  */

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#include "lib.h"

/* find_addr - translate numerical or symbolic host name */

struct in_addr find_addr(host)
char   *host;
{
    struct in_addr addr;
    struct hostent *hp;

    addr.s_addr = inet_addr(host);
    if ((addr.s_addr == -1) || (addr.s_addr == 0)) {
	if ((hp = gethostbyname(host)) == 0)
	    error("%s: host not found", host);
	if (hp->h_addrtype != AF_INET)
	    error("unexpected address family: %d", hp->h_addrtype);
	memcpy((char *) &addr, hp->h_addr, hp->h_length);
    }
    return (addr);
}

/* find_port - translate numerical or symbolic service name */

int     find_port(service, protocol)
char   *service;
char   *protocol;
{
    struct servent *sp;
    int     port;

    if ((port = atoi(service)) != 0) {
	return (htons(port));
    } else {
	if ((sp = getservbyname(service, protocol)) == 0)
	    error("%s/%s: unknown service", service, protocol);
	return (sp->s_port);
    }
}

