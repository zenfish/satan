 /*
  * timeout - run a command for a limited amount of time
  * 
  * Uses POSIX process groups so that we do the right thing when the controlled
  * command forks off child processes.
  * 
  * Author: Wietse Venema.
  */

/* System libraries. */

#include <sys/types.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

extern int optind;

/* Application-specific. */

#define perrorexit(s) { perror(s); exit(1); }

static int kill_signal = SIGKILL;
static char *progname;

static void usage()
{
    fprintf(stderr, "usage: %s [-signal] time command...\n", progname);
    exit(1);
}

static void terminate(sig)
int     sig;
{
    kill(0, kill_signal);
}

int     main(argc, argv)
int     argc;
char  **argv;
{
    int     time_to_run;
    pid_t   pid;
    pid_t   child_pid;
    int     status;

    progname = argv[0];

    /*
     * Parse JCL.
     */
    while (--argc && *++argv && **argv == '-')
	if ((kill_signal = atoi(*argv + 1)) <= 0)
	    usage();

    if (argc < 2 || (time_to_run = atoi(argv[0])) <= 0)
	usage();

    /*
     * Run the command and its watchdog in a separate process group so that
     * both can be killed of with one signal.
     */
    setsid();
    switch (child_pid = fork()) {
    case -1:					/* error */
	perrorexit("timeout: fork");
    case 00:					/* run controlled command */
	execvp(argv[1], argv + 1);
	perrorexit(argv[1]);
    default:					/* become watchdog */
	(void) signal(SIGALRM, terminate);
	alarm(time_to_run);
	while ((pid = wait(&status)) != -1 && pid != child_pid)
	     /* void */ ;
	return (pid == child_pid ? status : -1);
    }
}
