#
# sift by domains
#
# Output to: 
#
# $all_domains{domain}: hosts in this domain
#
# host_domain{host}: the domain of this host
#
# $domain_count{domain}: number of hosts in this domain
#
# $domain_severities{domain}: nr of vulnerable hosts in domain
#
# $domain_flag: reset whenever the tables are updated. To recalculate,
# invoke make_domain_info().
#
# Standalone usage: perl domains.pl [data directory]
# 

#
# Generate domain statistics.
#
sub make_domain_info {
    local($domain, $host);

    if ($domain_flag > 0) {
	return;
    }
    $domain_flag = time();

    print "Rebuild domain type statistics...\n" if $debug;

    %all_domains = ();
    for $host (keys %all_hosts) {
	if ($host =~ /^[\[\]0-9.]+$/) {
	    $domain = "unknown";
	} else {
	    ($domain = $host) =~ s/^[^.]+\.//;
	}
	$all_domains{$domain} .= "$host ";
	$host_domain{$host} = $domain;
    }

    # Cheat, in case the facts file has names not in all-hosts.

    for $host (keys %hosttype, keys %severity_host_count) {
	if ($host =~ /^[0-9.]+$/) {
	    $domain = "unknown";
	} else {
	    ($domain = $host) =~ s/^[^.]+\.//;
	}
	if (!exists($host_domain{$host})) {
	    $all_domains{$domain} .= "$host ";
	    $host_domain{$host} = $domain;
	}
    }

    for $domain (keys %all_domains) {
	$domain_count{$domain} = split(/\s+/, $all_domains{$domain});
	$domain_severities{$domain} = 0;
	for $host (split(/\s+/, $all_domains{$domain})) {
	    $domain_severities{$domain}++ if exists($severity_host_type_info{$host});
	}
    }
}

#
# erase the domain info tables
#
sub clear_domain_info {
    %all_domains = ();
    %host_domain = ();
    %domain_count = ();
    %domain_severities = ();
    $domain_flag = 0;
}

#
# Stand-alone mode
#
if ($running_under_satan == 0) {
    warn "domains.pl in stand-alone mode...";
    $running_under_satan = 1;
    $debug = 1;
    require 'perl/targets.pl';
    require 'perl/severities.pl';
    require 'perl/facts.pl';

    &read_all_hosts("$ARGV[0]/all-hosts");
    &read_facts("$ARGV[0]/facts");
    &make_domain_info();
    &make_hosttype_info();

    print "Missing domain info\n";

    for (keys %hosttype) {
	print "\t$_\n" if !exists($host_domain{$_});
    }

    print "\nDomain info\n";

    for (keys %all_domains) {
	    print "Domain: $_ $domain_severities{$_}/$domain_count{$_}\n";
	    for (split(/\s/, $all_domains{$_})) {
		    print "\t$_\n";
	    }
    }
}

1;
