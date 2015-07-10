 /*
  * non_blocking - set/clear open file non-blocking I/O flag
  * 
  * Environment: POSIX, 43BSD
  * 
  * Author: Wietse Venema.
  */

#include <sys/types.h>
#include <fcntl.h>

/* Backwards compatibility */
#ifdef FNDELAY
#define PATTERN	FNDELAY
#else
#define PATTERN	O_NONBLOCK
#endif

non_blocking(fd, on)
int     fd;
int     on;
{
    int     flags;

    if ((flags = fcntl(fd, F_GETFL, 0)) < 0)
	return -1;
    return fcntl(fd, F_SETFL, on ? flags | PATTERN : flags & ~PATTERN);
}

