#
# Look up a host name the hard way, using nsloookup. Don't rely on the
# gethostbyname() library routine, as there are too many broken NIS
# setups.  Return an empty string in case of errors.
#
# Stand-alone usage: getfqdn.pl hostname.
#
# version 1, Tue Mar 21 19:31:03 1995, last mod by wietse
#
require 'config/paths.pl';
require 'config/satan.cf';

sub getfqdn {
	local($host) = @_;
	local($result, $temp);

	if ($host =~ /^[0-9.]+$/) {
		return $host unless ($temp = &get_host_name($host));
		$host = $temp;
	}
	if ($dont_use_nslookup) {
		return &get_host_name($host);
	}

	if (!exists($getfqdn_cache{$host})) {
		open(NSLOOKUP, "$NSLOOKUP 2>/dev/null <<EOF\n$host\nEOF|") 
			|| die "cannot run $NSLOOKUP: $!";
		$result = "";
		while(<NSLOOKUP>) {
			if (/name:\s+(\S+)/i) {
				($result = $1) =~ tr /A-Z/a-z/;
				last;
			}
		}
		close(NSLOOKUP);
		$getfqdn_cache{$host} = $result;
	}
	return($getfqdn_cache{$host});
}

#
# Some scaffolding code for stand-alone testing.
#
if ($running_under_satan == 0) {
	$running_under_satan = 1;
	require 'perl/get_host.pl';
	$host = &getfqdn($ARGV[0]);
	print "$host\n";
}

1;
