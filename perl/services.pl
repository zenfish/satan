#
# infer_services - classify host by services used and provided. Output to: 
#
# $servers{service}{host}, $clients{service}{host}: Service is, for
# example, "anonymous FTP". The servers (clients) table holds per service
# and host, all SATAN records on that topic.
#
# $server_counts{service}, $client_counts{service}: host counts of the
# corresponding entries in $servers and $clients.
#
# $server_severities{service}, $client_severities{service}: ditto, with
# at least one vulnerability.
#
# $server_info{host}: newline-delimited list of services provided per host.
# $client_info{host}: newline-delimited list of services consumed per host.
#
# $service_flag: reset whenever the tables are updated. To recalculate,
# invoke make_service_info().
#
# Standalone usage: perl services.pl [satan_record_files...]
# 

$services_files = "rules/services";

sub build_infer_services {
    local($files) = @_;
    local($service, $code, $file, $cond, $class, $host);

    $code = "sub infer_services {\n";
    $code .= "\tlocal(\$type);\n";

    foreach $file (split(/\s+/, $files)) {
	open(RULES, $file) || die "cannot open $file: $!";
	while (<RULES>) {
	    chop;
	    while (/\\$/) {
		chop;
		$_ .= <RULES>;
		chop;
	    }
	    s/#.*$//;
	    s/\s+$//;
	    next if /^$/;
	    if (/^(servers|clients)/i) {
		($class = $1) =~ tr /A-Z/a-z/;
	    } else {
		s/@/\\@/g;
		($cond, $type, $host) = split(/\t+/, $_, 3);
		die "missing service name" if $type eq "";
		$host = "\$target" if $host eq "";
		$code .= "\
	if ($cond) {
		\$$class\{\"$type\"}{$host} .= \$_ . \"\\n\";
		\$service_flag = 0;
	}
";
		# %{${$class}{$type}} = ();
	    }
	}
	close(RULES);
    }
    $code .= "}\n";
    return $code;
}

#
# Generate services-dependent statistics.
#
sub make_service_info {
    local($service, $host, %junk);

    if ($service_flag > 0) {
	return;
    }
    $service_flag = time();
    &make_severity_info();

    print "Rebuild service type statistics...\n" if $debug;

    %server_info = ();
    for $service (keys %servers) {
	%junk = %{$servers{$service}};
	$server_counts{$service} = sizeof(*junk);
	$server_severities{$service} = 0;
	for $host (keys %junk) {
	    $server_info{$host} .= $service . "\n";
	    if (exists($severity_host_type_info{$host})) {
		$server_severities{$service}++;
	    }
	}
    }
    %client_info = ();
    for $service (keys %clients) {
	%junk = %{$clients{$service}};
	$client_counts{$service} = sizeof(*junk);
	$client_severities{$service} = 0;
	for $host (keys %junk) {
	    $client_info{$host} .= $service . "\n";
	    if (exists($severity_host_type_info{$host})) {
		$client_severities{$service}++;
	    }
	}
    }
}

#
# Reset the service information tables.
#
sub clear_service_info {
    %servers = ();
    %clients = ();
    %server_severities = ();
    %client_severities = ();
    %server_info = ();
    %client_info = ();
    $service_flag = 0;
}

#
# Some scaffolding for stand-alone operation
#
if ($running_under_satan) {
    eval &build_infer_services($services_files);
    die "error in $services_files: $@" if $@;
} else {
    $running_under_satan = -1;
    $debug = 1;

    require 'perl/misc.pl';

    #
    # Generate code from rules files.
    #
    $code = &build_infer_services($services_files);
    print "Code generated from $services_files:\n\n";
    print $code;
    eval $code; 
    die "error in $services_files: $@" if $@;

    #
    # Apply rules.
    #
    print "\nApplying rules to all SATAN records...\n";
    while (<>) {
	chop;
	if (&satan_split($_) == 0) {
	    &infer_services(_);
	}
    }
    &make_service_info();

    print "Servers\n";
    for $service (sort keys %servers) {
       print "\t$service ($server_counts{$service})\n";
	for (sort keys %{$servers{$service}}) {
	    print "\t\t$_\n";
	}
    }
    print "Clients\n";
    for $service (sort keys %clients) {
       print "\t$service ($client_counts{$service})\n";
	for (sort keys %{$clients{$service}}) {
	    print "\t\t$_\n";
	}
    }
}

1;
