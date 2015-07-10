#
# Usage: &infer_todo()
# 
# Applies rules in $infer_todo_files to the global $target..$text
# variables (and to all other globals that are available) and
# generates new probes for the data collection engine.
# 
# Standalone usage: perl infer_todo.pl [satan_record_files...]
#
# version 1, Tue Mar 21 20:25:31 1995, last mod by wietse
#

$infer_todo_files = "rules/todo";

sub build_infer_todo{
    local($files) = @_;
    local($cond, $todo, $func, $host, $tool, $args, $args1, $args2);

    $code = "sub infer_todo {\n";
    $code .= "	local(\$junk);\n";

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
	    ($cond, $todo) = split(/\t+/, $_, 2);
	    ($host, $tool, $args) = split(/\s+/, $todo, 3);
	    $host ne "" || die "no host in $file: cond=$cond, todo=$todo\n";
	    $tool ne "" || die "no tool in $file: cond=$cond, todo=$todo\n";
	    if ($args =~ /\*\s*(.+)/) {
		$func = "add_todo_ignore_args";
		$args = $1;
	    } else {
		$func = "add_todo";
	    }
	    $code .= "\tif ($cond) {\n\t\t&$func($host,$tool";
	    ($args ne "") && ($code .= ",$args");
	    $code .= ");\n\t}\n";
	}
	close(RULES);
    }
    $code .= "\n}\n";
    return $code;
}

#
# Some scaffolding for stand-alone operation
#
if ($running_under_satan) {
    eval &build_infer_todo($infer_todo_files);
    die "error in $infer_todo_files: $@" if $@;
} else {
    $running_under_satan = -1;

    require 'perl/misc.pl';
    require 'perl/fix_hostname.pl';

    warn "infer_todo.pl running in test mode";

    eval "sub add_todo { local(\$target,\$tool,\$args) = \@_;
	print \"add_todo: \$target \$tool \$args\\n\"; }\n";

    eval "sub add_todo_ignore_args { local(\$target,\$tool,\$args) = \@_;
	print \"add_todo_ignore_args: \$target \$tool \$args\\n\"; }\n";

    #
    # Build satan rules and include them into the running code.
    #
    $code = &build_infer_todo($infer_todo_files);
    print "Code generated from $infer_todo_files:\n\n";
    print $code;
    eval $code;
    die "error in $infer_todo_files: $@" if $@;

    #
    # Apply rules.
    #
    print "\nApplying rules to all SATAN records...\n";
    while (<>) {
	chop;
	if (&satan_split($_)) {
	    warn "Ill-formed record: $_\n";
	} else {
	    &infer_todo();
	}
    }
}

1;
