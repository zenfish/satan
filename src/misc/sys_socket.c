 /*
  * Many PERL installations have no sys/socket.ph file, and with many
  * installations, the sys/*.ph files are broken. This is a bizarre
  * workaround: a C program to bootstrap a PERL application.
  * 
  * Author: Wietse Venema.
  */
#include <sys/types.h>
#include <sys/socket.h>

int     main(argc, argv)
int     argc;
char  **argv;
{
    printf("sub AF_INET { %d; }\n", AF_INET);
    printf("sub SOCK_STREAM { %d; }\n", SOCK_STREAM);
    printf("1;\n");
}
