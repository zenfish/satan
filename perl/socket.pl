#
# Some PERL installations have no sys/*.ph, and on some sites the
# sys/*.ph files are busted. Since we need this only for a few things we
# Even grabbing the definitions directly from sys/socket.h is problematic
# on SYSV4 where the include files are messed up by recursive defines. So
# we revert to running a C program that emits PERL code.
#

require 'config/paths.pl';

die "$SYS_SOCKET: $!. Did you run 'reconfig' and 'make'?\n" 
	unless -x "$SYS_SOCKET";

eval `$SYS_SOCKET`;

#
# When that failed, die a horrible death.
#
die "./$SYS_SOCKET: $@.\n" if $@;

1;
