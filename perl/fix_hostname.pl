# fix possibly unqualified or truncated hostname, given the fqdn of the
# host that we got the information from.
#

sub fix_hostname {
    local ($host, $origin) = @_;
    local ($fqdn, $dot, $old, $frag, $n, $trial);

    # First see if the name (or IP address) is in the DNS.
    if ($host =~ /\./ && ($frag = &get_host_name(&get_host_addr($host)))) {
	$host = $frag;
    }

    # Can't do anything else for IP addresses.
    if ($host =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
	return "";
    }

    # Can't do hostname completion when the originator is an IP address.
    if ($origin =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
	return $host;
    }

    # Assume an unqualified name is in the same domain as the originator.
    # 
    if (($dot = index($host, ".")) < $[) {
	return &get_host_name($host . substr($origin, index($origin, ".")));
    }
    $old = $dot;

    # Assume the hostname is trucated.
    foreach $trial ($origin, ".mil", ".edu", ".gov", ".net", ".org", ".com") {
        for ($dot = $old; length($frag = substr($host,$dot-$[)) > 1; $dot += $n) {
            # Match .fragment with (upper domain) of trial domain.
            if (($n = index($trial, $frag)) >= $[) {
                if ($fqdn = &get_host_name(substr($host, $[, $dot - $[) . substr($trial, $n))) {
		    return $fqdn;
		}
	    }
            # Strip lowest .subdomain from .fragment and retry.
            last if (($n = index(substr($frag, $[ + 1), ".") + 1 - $[) < 1);
        }
    }

    # Unable to fix the hostname.
    #
    return "";
}

#
# Some scaffolding for stand-alone testing.
#
if ($running_under_satan) {
    require 'perl/get_host.pl';
} else {
    $running_under_satan = -1;

    require 'perllib/getopts.pl';
    require 'perl/get_host.pl';

    warn "fix_hostname.pl running in test mode";

    $usage = "usage: fix_hostname partial_name complete_name\n";
    &Getopts("v");

    if ($#ARGV != 1) {
	print STDERR $usage;
	exit 1;
    }

    print &fix_hostname($ARGV[0], $ARGV[1]),"\n";
}

1;
