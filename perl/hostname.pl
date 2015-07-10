#
# file: hostname.pl
# usage: $hostname = &'hostname;
#
# purpose: get hostname -- try method until we get an answer 
#	or return "Amnesiac!"
#

package hostname;

sub main'hostname {
    if (!defined $hostname) {
	$hostname =  ( -x '/bin/hostname'     && `/bin/hostname` ) 
		  || ( -x '/usr/ucb/hostname' && `/usr/ucb/hostname` )
		  || ( -x '/bin/uname'        && `/bin/uname -n` )
		  || ( -x '/usr/bin/uuname'   && `/usr/bin/uuname -l`)
		  || 'Amnesiac! ';  # trailing space is for chop
	chop $hostname;
    }
    $hostname;
}

1;
