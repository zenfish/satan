#
# update_trust - maintain trust statistics
#
# Output to: 
#
# $total_trusted_count{host} number of non-ANY trust relationships
# $total_trusted_names{host} names of trusted hosts
#
# $total_trustee_count{host} number of non-ANY trust relationships
# $total_trustee_names{host} names of trustee hosts
#
# $trust_host_type{trusted trustee}{type} all facts about this relationship.
# $trust_type_host{type}{trusted trustee} all facts about this relationship.
# 

$trust_files = "rules/trust";
$trust_other = "other";

sub build_update_trust {
    local($files) = @_;
    local($code, $type);

    $code = '
sub update_trust {
    local($td_host, $te_host);
    ($td_host = $trusted) =~ s/(.*@)?(.*)/$2/;
    ($te_host = $trustee) =~ s/(.*@)?(.*)/$2/;

    return 
	if $td_host eq "" || $te_host eq ""
	|| $td_host eq "ANY" || $td_host eq $te_host;

    if (!exists($trust_host_type{"$td_host $te_host"})) {
	$total_trustee_names{$td_host} .= "$te_host ";
	$total_trustee_count{$td_host}++;
	$total_trusted_names{$te_host} .= "$td_host ";
	$total_trusted_count{$te_host}++;
    }
';

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
	    s/@/\\@/g;
	    ($cond, $type) = split(/\t+/, $_, 2);
	    die "missing trust type" if $type eq "";
	    $code .= "\
    if ($cond) {
	\$trust_host_type{\"\$td_host \$te_host\"}{\"$type\"} .= \$_ . \"\\n\";
	\$trust_type_host{\"$type\"}{\"\$td_host \$te_host\"} .= \$_ . \"\\n\";
	return;
    }\
";
	}
	close(RULES);
    }
    $code .= "\
    \$trust_host_type{\"\$trustee \$trusted\"}{\"other\"} .= \$_ . \"\\n\";
    \$trust_type_host{\"other\"}{\"\$trustee \$trusted\"} .= \$_ . \"\\n\";
}\n";
    return $code;
}

#
# Reset all trust information tables.
#
sub clear_trust_info {
	%total_trust_pair = ();
	%total_trustee_names = ();
	%total_trustee_count = ();
	%total_trusted_names = ();
	%total_trusted_count = ();
	%trust_host_type = ();
}

#
# Some scaffolding for stand-alone operation
#
if ($running_under_satan) {
    eval &build_update_trust($trust_files);
    die "error in $trust_files: $@" if $@;
} else {
    $running_under_satan = -1;
    $debug = 1;

    require 'perl/misc.pl';

    #
    # Generate code from rules files.
    #
    $code = &build_update_trust($trust_files);
    print "Code generated from $trust_files:\n\n";
    print $code;
    eval $code; 
    die "error in $trust_files: $@" if $@;

    #
    # Apply rules.
    #
    print "\nApplying rules to all SATAN records...\n";
    while (<>) {
        chop;
        if (&satan_split($_) == 0) {
            &update_trust($_);
        }
    }

    print "Trusted Trustee Type...\n";
    for $pair (sort keys %trust_host_type) {
	print $pair,' ',sort(join(' ', keys %{$trust_host_type{$pair}})),"\n";
    }

    print "\nType Trusted Trustee...\n";
    for $type (sort keys %trust_type_host) {
	for $pair (sort keys %{$trust_type_host{$type}}) {
	    print "$type $pair\n";
	}
    }
}

1;
