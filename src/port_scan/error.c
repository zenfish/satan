 /*
  * remark, error, panic - diagnostics handlers
  * 
  * Feature: %m is expanded to the system errno text.
  * 
  * Author: Wietse Venema.
  */

#include <stdio.h>
#include <errno.h>

#ifdef __STDC__
#include <stdarg.h>
#define VARARGS(func,type,arg) func(type arg, ...)
#define VASTART(ap,type,name)  va_start(ap,name)
#define VAEND(ap)              va_end(ap)
#else
#include <varargs.h>
#define VARARGS(func,type,arg) func(va_alist) va_dcl
#define VASTART(ap,type,name)  {type name; va_start(ap); name = va_arg(ap, type)
#define VAEND(ap)              va_end(ap);}
#endif

char   *progname = "unknown";

extern int errno;
extern char *strerror();
extern char *strcpy();

#include "lib.h"

/* percentm - replace %m by error message associated with value in err */

char   *percentm(buf, str, err)
char   *buf;
char   *str;
int     err;
{
    char   *ip = str;
    char   *op = buf;

    while (*ip) {
	switch (*ip) {
	case '%':
	    switch (ip[1]) {
	    case '\0':				/* don't fall off end */
		*op++ = *ip++;
		break;
	    case 'm':				/* replace %m */
		strcpy(op, strerror(err));
		op += strlen(op);
		ip += 2;
		break;
	    default:				/* leave %<any> alone */
		*op++ = *ip++, *op++ = *ip++;
		break;
	    }
	default:
	    *op++ = *ip++;
	}
    }
    *op = 0;
    return (buf);
}

/* error - print warning on stderr and terminate */

void    VARARGS(error, char *, fmt)
{
    va_list ap;
    int     err = errno;
    char    buf[BUFSIZ];

    VASTART(ap, char *, fmt);
    fprintf(stderr, "%s: ", progname);
    vfprintf(stderr, percentm(buf, fmt, err), ap);
    fprintf(stderr, "\n");
    VAEND(ap);
    exit(1);
}

/* remark - print warning on stderr and continue */

void    VARARGS(remark, char *, fmt)
{
    va_list ap;
    int     err = errno;
    char    buf[BUFSIZ];

    VASTART(ap, char *, fmt);
    fprintf(stderr, "%s: ", progname);
    vfprintf(stderr, percentm(buf, fmt, err), ap);
    fprintf(stderr, "\n");
    VAEND(ap);
}

/* panic - print warning on stderr and dump core */

void    VARARGS(panic, char *, fmt)
{
    va_list ap;
    int     err = errno;
    char    buf[BUFSIZ];

    VASTART(ap, char *, fmt);
    fprintf(stderr, "%s: ", progname);
    vfprintf(stderr, percentm(buf, fmt, err), ap);
    fprintf(stderr, "\n");
    VAEND(ap);
    abort();
}
