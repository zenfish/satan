#
# update_severities - classify vulnerabilities.
#
# type is taken from the $service_info field; level is taken from the
# $severity field.
#
# Output to: 
#
# $severity_type_host_info{type}{host}: all SATAN records on that topic.
#
# $severity_type_count{type}: number of hosts with this severity.
#
# $severity_host_type_info{host}{type}: all SATAN records on that topic.
#
# $severity_host_count{host}: number of vulnerabilities per host.
#
# $severity_levels{severity}: host names per severity level.
#
# $severity_flag: reset whenever the tables are updated. To recalculate,
# invoke make_severity_info().
#
# Standalone usage: perl severities.pl [satan_record_files...]
# 

sub update_severities {
    if ($trusted =~ /\bANY\b/) {
	$type = "other vulnerabilities" if ($type = $service_output) eq "";
	if (index($severity_host_type_info{$target}{$type}, $_) < $[) {
	    $severity_host_type_info{$target}{$type} .= $_ . "\n";
	    $severity_type_host_info{$type}{$target} .= $_ . "\n";
	    $severity_levels{$severity}{$target} .= $_ . "\n";
	    $severity_host_count{$target}++;
	    $severity_flag = 0;
	}
    }
}

#
# Generate severities-dependent statistics.
#
sub make_severity_info {
    local($severity, $host, %junk);

    if ($severity_flag > 0) {
	return;
    }
    $severity_flag = time();

    print "Rebuild severity type statistics...\n" if $debug;

    for $severity (keys %severity_type_host_info) {
	%junk = %{$severity_type_host_info{$severity}};
	$severity_type_count{$severity} = sizeof(*junk);
    }
}

#
# Reset all severity information
#
sub clear_severity_info {
    %severity_host_type_info = ();
    %severity_type_host_info = ();
    %severity_levels = ();
    %severity_host_count = ();
    %severity_type_count = ();
    $severity_flag = 0;
}

#
# Some scaffolding for stand-alone operation
#
if ($running_under_satan == 0) {
    $running_under_satan = -1;
    $debug = 1;
    require 'perl/misc.pl';
    warn "severities.pl running in stand-alone mode";

    #
    # Sort severity information and do some counting.
    #
    while (<>) {
	chop;
	if (&satan_split($_) == 0) {
	    &update_severities($_);
	}
    }
    &make_severity_info();

    print "Hosts grouped by severity\n";
    for $severity (sort keys %severity_type_host_info) {
       print "$severity ($severity_type_count{$severity})\n";
	for (sort keys %{$severity_type_host_info{$severity}}) {
	    print "\t$_\n";
	}
    }

    print "Severities grouped by host\n";
    for $host (sort keys %severity_host_type_info) {
	print "$host\n";
	for $type (sort keys %{$severity_host_type_info{$host}}) {
	    for (split(/\n/, $severity_host_type_info{$host}{$type})) {
		print "\t$_\n";
	    }
	}
    }
}

# UPC Code:

1;
