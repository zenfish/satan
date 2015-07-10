 /*
  * md5 - trivial command-line driver for the MD5 hash function.
  * 
  * usage: md5 [files...]
  * 
  * Author: Wietse Venema.
  */
#include <stdio.h>
#include "global.h"
#include "md5.h"

#define MD5_HASH_LENGTH	16

main(argc, argv)
int     argc;
char  **argv;
{
    char   *crunch();
    FILE   *fp;

    if (argc < 2) {
	printf("%s\n", crunch(stdin));
    } else {
	while (--argc && *++argv) {
	    if ((fp = fopen(*argv, "r")) == 0) {
		perror(*argv);
		return (1);
	    }
	    printf("%s	%s\n", crunch(fp), *argv);
	    fclose(fp);
	}
    }
    return (0);
}

char   *crunch(fp)
FILE   *fp;
{
    MD5_CTX md;
    unsigned char sum[MD5_HASH_LENGTH];
    unsigned char buf[BUFSIZ];
    static char result[2 * MD5_HASH_LENGTH + 1];
    static char hex[] = "0123456789abcdef";
    int     buflen;
    int     i;

    MD5Init(&md);
    while ((buflen = fread(buf, 1, BUFSIZ, fp)) > 0)
	MD5Update(&md, buf, buflen);
    MD5Final(sum, &md);

    for (i = 0; i < MD5_HASH_LENGTH; i++) {
	result[2 * i] = hex[(sum[i] >> 4) & 0xf];
	result[2 * i + 1] = hex[sum[i] & 0xf];
    }
    return (result);
}
