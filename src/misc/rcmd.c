/* rcmd - remote command execution */

#include <sys/types.h>
#include <stdio.h>
#include <netdb.h>

main(argc, argv)
int     argc;
char  **argv;
{
    char    buffer[BUFSIZ];
    struct servent *sp;
    int     s;
    int     n;

    if (argc != 4) {
	fprintf(stderr, "usage: %s host user 'command'\n", argv[0]);
	return (1);
    }
    if (geteuid()) {
	fprintf(stderr, "test needs root privileges\n");
	return (1);
    }
    sp = getservbyname("shell", "tcp");
    if (sp == 0) {
	fprintf(stderr, "unknown service: shell/tcp\n");
	return (1);
    }
    s = rcmd(argv + 1, sp->s_port, argv[2], argv[2], argv[3], NULL);
    if (s >= 0) {
	while ((n = read(s, buffer, sizeof(buffer))) > 0)
	    write(1, buffer, n);
	return (0);
    } else {
	return (1);
    }
}
