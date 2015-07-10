#
# infer_hosttype - classify host by banner, the dns HINFO record may be wrong.
# Output to: 
#
# $hosttype{$target}		operating system type per host
# $sysclass{$type}		OS class that an OS type belongs to
# $hosttype_flag		(*)
# $systype_counts{type}		number of hosts per OS type
# $systype_severities{type}	ditto, with at least one vulnerability
# $sysclass_counts{class}	number of hosts per OS class
# $sysclass_severities{class}	ditto, with at least one vulnerability
# $hosts_by_systype{type}	string with hosts per OS type
# $systypes_by_class{class}	string with OS types per OS class
#
# (*) Is reset whenever the $hosttype etc. tables are updated. To recalculate,
# invoke make_hosttype_info_flag().
#
# Standalone usage: perl hosttype.pl [satan_record_files...]
# 

$hosttype_files = "rules/hosttype";
$hosttype_unknown = "unknown type";
$hosttype_notprobed = "not scanned";

sub build_infer_hosttype {
    local($files) = @_;
    local($type, $code, $file, $cond, $type, $class);

    $code = "sub infer_hosttype {\n";
    $code .= "\tlocal(\$type);\n";
    $code .= "\tif (\$service !~ /^(smtp|telnet|ftp)\$/) {\n\t\treturn;\n\t}\n";
    $class = "other";

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
	    if (/^CLASS\s+(.+)/i) {
		$class = $1;
	    } else {
		s/\bUNKNOWN\b/(HOSTTYPE eq "" || HOSTTYPE eq \"$hosttype_unknown\" || HOSTTYPE eq \"$hosttype_notprobed\")/;
		s/\bHOSTTYPE\b/\$hosttype{\$target}/g;
		s/@/\\@/g;
		($cond, $type) = split(/\t+/, $_, 2);
		$type = "\$1" if ($type eq "");
		$code .= "\
	if ($cond) {
		\$type = $type;
		\$hosttype{\$target} = \$type; 
		\$sysclass{\$type} = \"$class\";
		\$hosttype_flag = 0;
		return;
	}
";
	    }
	}
	close(RULES);
    }
    $code .= "\t\$hosttype{\$target} = \"\"
		if !exists(\$hosttype{\$target});\n}";
    return $code;
}

#
# Generate hosttype-dependent statistics.
#
sub make_hosttype_info {
    local($host, $class, $type, $count);

    if ($hosttype_flag > 0) {
	return;
    }
    $hosttype_flag = time();

    print "Rebuild host type statistics...\n" if $debug;
    &make_severity_info();

    %hosts_by_systype = ();
    %systypes_by_class = ();
    %systype_severities = ();
    %systype_counts = ();
    %sysclass_severities = ();
    %sysclass_counts = ();

    for $host (keys %all_hosts) {
	$hosttype{$host} = $hosttype_unknown 
	    if ($host && $hosttype{$host} eq "" && &get_host_time($host) > 1);
	$hosttype{$host} = $hosttype_notprobed 
	    if ($host && $hosttype{$host} eq "");
    }
    $sysclass{$hosttype_unknown} = "other";
    $sysclass{$hosttype_notprobed} = "other";

    for $type (sort keys %sysclass) {
	$systype_severities{$type} = 0;
	$sysclass_severities{$sysclass{$type}} = 0;
    }
    for $host (sort keys %hosttype) {
	$type = $hosttype{$host};
	if ($type eq "") {
	    $type = $hosttype{$host} = $hosttype_unknown;
	}
	if (exists($severity_host_type_info{$host})) {
	     $systype_severities{$type}++;
	}
	$hosts_by_systype{$type} .= $host . "\n";
	$systype_counts{$type}++;
    }

    for $type (sort keys %sysclass) {
	if (($count = $systype_counts{$type}) > 0) {
	    $class = $sysclass{$type};
	    $systypes_by_class{$class} .= $type . "\n";
	    $sysclass_counts{$class} += $count;
	    if ($systype_severities{$type}) {
		$sysclass_severities{$class} += $systype_severities{$type};
	    }
	} else {
	    delete($sysclass{$type});
	}
    }
}

#
# Reset the host type tables.
#
sub clear_hosttype_info {
    %hosttype = ();
    %systype = ();
    %hosts_by_systype = ();
    %systypes_by_class = ();
    %systype_severities = ();
    %systype_counts = ();
    %sysclass_severities = ();
    %sysclass_counts = ();
    $hosttype_flag = 0;
}

#
# Some scaffolding for stand-alone operation
#
if ($running_under_satan) {
    eval &build_infer_hosttype($hosttype_files);
    die "error in $hosttype_files: $@" if $@;
} else {
    $running_under_satan = -1;
    $debug = 1;

    require 'perl/misc.pl';

    #
    # Generate code from rules files.
    #
    $code = &build_infer_hosttype($hosttype_files);
    print "Code generated from $hosttype_files:\n\n";
    print $code;
    eval $code; 
    die "error in $hosttype_files: $@" if $@;

    #
    # Apply rules.
    #
    print "\nApplying rules to all SATAN records...\n";
    while (<>) {
	chop;
	if (&satan_split($_) == 0) {
	    &infer_hosttype();
	}
    }
    &make_hosttype_info();
    for (sort keys %hosttype) {
	print "$hosttype{$_}	$_\n";
    }
    print "Host class information:\n";
    for $class (sort keys %systypes_by_class) {
	print "$class	";
	print join('	', split(/\n/, $systypes_by_class{$class}));
	print "\n";
    }
}

1;
