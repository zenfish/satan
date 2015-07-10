 /*
  * strerror - translate error number to string
  * 
  * Author: Wietse Venema.
  */

extern char *sys_errlist[];
extern int sys_nerr;

char   *strerror(err)
int     err;
{
    static char buf[20];

    if (err < sys_nerr && err > 0) {
	return (sys_errlist[err]);
    } else {
	sprintf(buf, "Unknown error %d", err);
	return (buf);
    }
}
