require 'perl/socket.pl';

#  Lookup the FQDN for a host name or address with cacheing.
#
sub get_host_name {
	local($host) = @_;
	local($aliases, $type, $len, @ip, $a,$b,$c,$d);

	# do cache lookup first
	if (exists($host_name_cache{$host})) {
		return($host_name_cache{$host});
		}

	# if host is ip address
	if ($host =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
		($a,$b,$c,$d) = split(/\./, $host);
		@ip = ($a,$b,$c,$d);
		($host) = gethostbyaddr(pack("C4", @ip), &AF_INET);
		}
	# if host is name, not ip address
	else {
		($host, $aliases, $type, $len, @ip) = gethostbyname($host);
		($a,$b,$c,$d) = unpack('C4',$ip[0]);
		}

	# success:
	if ($host && @ip) {
		$host =~ tr /A-Z/a-z/;
		return $host_name_cache{$host} = $host;
		}
	# failure:
	else {
		return $host_name_cache{$host} = "";
		}
	}

#
# Look up host address wich cacheing
#
sub get_host_addr {
	local($host) = @_;
	local($aliases, $type, $len, @ip, $a,$b,$c,$d);

	# do cache lookup first
	if (exists($host_addr_cache{$host})) { 
		return($host_addr_cache{$host}); 
		}

	# if host is name, not ip address
	if ($host =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
		return $host;
		} 
	else {
		($host, $aliases, $type, $len, @ip) = gethostbyname($host);
		($a,$b,$c,$d) = unpack('C4',$ip[0]);
		}

	# success; want IP address
	if (@ip) { 
		return "$a.$b.$c.$d";
		}
	# failure:
	else { 
		return $host_addr_cache{$host} = "";
		}
	}

#
# Some scaffolding code for stand-alone testing.
#
if ($running_under_satan == 0) {
	$running_under_satan = -1;

	warn "get_host.pl running in test mode";

	$host = &get_host_name($ARGV[0]); print "get_host_name: $host\n";
	$host = &get_host_addr($ARGV[0]); print "get_host_addr: $host\n";
}

1;
