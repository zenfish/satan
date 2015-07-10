#
# Usage: $code = &drop_fact()
# 
# Applies the rules in $drop_fact_files to the global $target..$text 
# variables. The result value is nonzero if the record should be ignored.
# 
# Standalone usage: perl drop_fact.pl [satan_record_files...]
# 

$drop_fact_files = "rules/drop";

sub build_drop_fact{
    local($files) = @_;
    local($code);

    $code = "sub drop_fact {\n";

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
	    next if /^\s*$/;
	    s/@/\\@/g;
	    $code .= "\tif ($_) {\n\t\treturn 1;\n\t}\n";
	}
	close(RULES);
    }
    $code .= "\treturn 0;\n}\n";
    return $code;
}

#
# Some scaffolding for stand-alone operation
#
if ($running_under_satan) {
    eval &build_drop_fact($drop_fact_files);
    die "error in $drop_fact_files: $@" if $@;
} else {
    $running_under_satan = -1;

    require 'perl/misc.pl';

    #
    # Build satan rules and include them into the running code.
    #
    $code = &build_drop_fact($drop_fact_files);
    print "Code generated from $drop_fact_files file:\n\n";
    print $code;
    eval $code;
    die "error in $drop_fact_files: $@" if $@;

    #
    # Apply rules.
    #
    print "\nApplying rules to all SATAN records...\n";
    while (<>) {
	chop;
	if (&satan_split($_)) {
	    warn "Ill-formed fact: $_\n";
	} elsif (&drop_fact()) {
	    print "Dropped: $_\n";
	}
    }
}

1;
