 /*
  * mymalloc, myrealloc, dupstr - memory allocation with error handling
  * 
  * Environment: POSIX, ANSI
  * 
  * Author: Wietse Venema.
  */

#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "lib.h"

/* mymalloc - allocate memory or bust */

char   *mymalloc(len)
int     len;
{
    char   *ptr;

    if ((ptr = malloc(len)) == 0)
	error("Insufficient memory: %m");
    return (ptr);
}

/* myrealloc - reallocate memory or bust */

char   *myrealloc(ptr, len)
char   *ptr;
int     len;
{
    if ((ptr = realloc(ptr, len)) == 0)
	error("Insufficient memory: %m");
    return (ptr);
}

/* dupstr - save string to heap */

char   *dupstr(str)
char   *str;
{
    return (strcpy(mymalloc(strlen(str) + 1), str));
}
