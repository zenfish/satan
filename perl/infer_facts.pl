#
# Usage: &infer_facts();
# 
# Apply the rules in $infer_fact_files to the global $target..$text variables
# (and to any other globals that happen to be available) and generate new
# facts.
# 
# Standalone usage: perl infer_fact.pl [satan_record_files...]
# 

$infer_fact_files = "rules/facts";

sub build_infer_facts {
    local($files) = @_;
    local($code, $cond, $fact);

    $code = "sub infer_facts {\n";

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
	    ($cond, $fact) = split(/\t+/, $_, 2);
	    $code .= "\tif ($cond) {\n\t\t&add_fact(\"$fact\");\n\t}\n";
	}
	close(RULES);
    }

    $code .= "}\n";

    return $code;
}

#
# Some scaffolding for stand-alone operation
#
if ($running_under_satan) {
    eval &build_infer_facts($infer_fact_files);
    die "error in $infer_fact_files: $@" if $@;
} else {
    $running_under_satan = -1;

    require 'perl/misc.pl';

    eval "sub add_fact { local(\$fact) = \@_; print \"Add-fact: \$fact\n\"; }";
    die "error in $infer_fact_files: $@" if $@;

    #
    # Build satan rules and include them into the running code.
    #
    $code = &build_infer_facts($infer_fact_files);
    print "Code generated from $infer_fact_files:\n\n";
    print $code;
    eval $code;

    #
    # Apply rules.
    #
    print "\nApplying rules to all SATAN records...\n";
    while (<>) {
	chop;
	if (&satan_split($_)) {
	    warn "Ill-formed fact: $_\n";
	} else {
	    &infer_facts();
	}
    }
}

1;
