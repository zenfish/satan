 /*
  * print_data - print random data in printable form
  * 
  * Author: Wietse Venema.
  */

#include <stdio.h>
#include <ctype.h>

#include "lib.h"

void    print_data(fp, buf, len)
FILE   *fp;
char   *buf;
int     len;
{
    int     c;

    while (len-- > 0) {
	c = (*buf++ & 0377);
	if (c == '\t') {
	    fputs("\\t", fp);
	} else if (c == '\n') {
	    fputs("\\n", fp);
	} else if (c == '\r') {
	    fputs("\\r", fp);
	} else if (c == '\\') {
	    fputs("\\\\", fp);
	} else if ((c & 0177) == c && isprint(c)) {
	    putc(c, fp);
	} else {
	    fprintf(fp, "\\%03d", c);
	}
    }
}
