#
# sift by subnets
#
# Output to: 
#
# $all_subnets{subnet}: hosts per subnet
#
# $host_subnet{host}: subnet of this host
#
# $subnet_count{subnet}: number of hosts in this subnet
#
# $subnet_severities{subnet}: nr of vulnerable hosts in subnet
#
# $subnet_flag: reset whenever the tables are updated. To recalculate,
# invoke make_subnet_info().
#
# Standalone usage: perl subnets.pl [data directory]
# 

#
# Generate subnet statistics.
#
sub make_subnet_info {
local($subnet, $host);

if ($subnet_flag > 0) {
	return;
	}
$subnet_flag = time();
%all_subnets = ();

&make_severity_info();

print "Rebuild subnet type statistics...\n" if $debug;

%all_subnets = ();
%host_subnet = ();

for $host (keys %all_hosts) {
	if ($host) {
		($subnet = $all_hosts{$host}{'IP'}) =~ s/\.[^.]*$//;
		$subnet = "unknown" unless $subnet;
		$all_subnets{$subnet} .= "$host ";
		$host_subnet{$host} = $subnet;
		}
	}

# Cheat in case the facts file has names not in all-hosts.

for $host (keys %hosttype, keys %severity_host_count) {
	next unless $host;
	next if defined($host_subnet{$host});
	if ($host =~ /^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+$/) {
		$subnet = $1;
	} else {
		$subnet = "unknown";
	}
	$all_subnets{$subnet} .= "$host ";
	$host_subnet{$host} = $subnet;
}

for $subnet (keys %all_subnets) {
	$subnet_count{$subnet} = split(/\s+/, $all_subnets{$subnet});
	$subnet_severities{$subnet} = 0;
	for $host (split(/\s+/, $all_subnets{$subnet})) {
		$subnet_severities{$subnet}++ if exists($severity_host_type_info{$host});
		}
	}
}

#
# erase the subnet info tables
#
sub clear_subnet_info {
	%all_subnets = ();
	%host_subnet = ();
	%subnet_count = ();
	%subnet_severities = ();
	$subnet_flag = 0;
}

#
# Stand-alone mode
#
if ($running_under_satan == 0) {
warn "subnets.p in stand-alone mode...";
$running_under_satan = 1;
$debug = 1;
require 'perl/targets.pl';
require 'perl/severities.pl';
require 'perl/facts.pl';

&read_all_hosts("$ARGV[0]/all-hosts");
&read_facts("$ARGV[0]/facts");
&make_subnet_info();

print "Subnet info\n";

for (keys %all_subnets) {
	print "Subnet: $_ $subnet_severities{$_}/$subnet_count{$_}\n";
	for (split(/\s/, $all_subnets{$_})) {
		print "\t$_\n";
		}
	}
}

1;
