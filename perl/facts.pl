#
# add_fact($record) add one record to the new facts list.
#
# process_facts() iterates over all new facts and generates new facts or
# new todo items. It keeps looping until the new facts list becomes empty.
#
# save_facts($path) saves the old facts to the named file.
#
# read_facts($path) reads the old facts from the named file.
#
# merge_facts($path) merge with i-core tables.
#
# redo_old_facts() re-applies the todo/fact rules in case the probe
# level or rule base have changed (or we would never see any effect
# of changing todo/fact rules with already collected data).
#
# drop_old_facts() forgets all old facts we have about a host.
#
# Warning: all facts processing that invokes inference engines MUST set $_.
#
# version 1, Sun Mar 19  9:48:44 1995, last mod by zen
#

#
# Add one fact to the new facts list, with duplicate suppression.
#
sub add_fact {
	local($fact) = @_;

	if (!exists($old_facts{$fact}) && !&drop_fact($fact) && !exists($new_facts{$fact})) { 
		$new_facts{$fact} = 1;
		print "Add-fact: $fact\n" if $debug;
	}
}

#
# Iterate over the new facts list until nothing new shows up.
#
sub process_facts {
	local(%temp_facts);

	while(&sizeof(*new_facts) > 0) {
		%temp_facts = %new_facts;
		%new_facts = ();
		for (keys %temp_facts) {
			if (&satan_split($_)) {
				warn "Ill-formatted fact: $_\n";
				next;
			}
			$old_facts{$_} = 1;
			if ($status ne "u") {
				#
				# Stage 1: update the per-host tables. 
				#
				&infer_hosttype($_);
				&infer_services($_);
				&update_severities($_);
				&update_trust($_);

				#
				# Stage 2: generate new probes and derive
				# new facts, using all information that
				# has been collected sofar.  Derive new
				# targets from trust relationships
				# (ignore localhost).
				#
				&infer_todo($_);
				&infer_facts($_);
				if (($trusted =~ /([^@]+)$/) && ($1 ne "ANY")
				    && ($1 !~ /^localhost\.?/i)) {
					&new_target(&fix_hostname($1, $target),
						&get_proximity($target) + 1);
				}
			}
		}
	}
}

#
# Save facts to named file.
#
sub save_facts {
	local($path) = @_;

	open(FACTS, ">$path") || die "cannot save facts to $path: $!";
	for (keys %old_facts) {
		print FACTS "$_\n";
	}
	close(FACTS);
}

#
# Reset facts tables and derivatives
#
sub clear_facts {
	%old_facts = ();
	%new_facts = ();
	&clear_hosttype_info();
	&clear_service_info();
	&clear_severity_info();
	&clear_trust_info();
}

#
# Load facts from named file.
#
sub read_facts {
	local($path) = @_;

	&clear_facts();
	&merge_facts($path);
}

#
# Merge facts with in-core tables.
#
sub merge_facts {
	local($path) = @_;

	open(FACTS, $path) || die "Cannot read facts file $path: $!";
	print "Reading facts from $path...\n" if $debug;
	while (<FACTS>) {
		chop;
		if (!exists($old_facts{$_})) {
			if (&satan_split($_)) {
				warn "Warning - corrupted $path record: $_\n";
				next;
			}
			$old_facts{$_} = 1;
			if ($status ne "u") {
				&infer_hosttype($_);
				&infer_services($_);
				&update_severities($_);
				&update_trust($_);
				&infer_facts($_);
			}
		}
	}
	&process_facts();
	close(FACTS);
}

#
# Forget all old facts we have on a specific host.
#
sub drop_old_facts {
	local($host) = @_;
	local($fact, $target);

	for $fact (keys %old_facts) {
		($target) = split(/\|/, $fact);
		if ($target eq $host) {
			print "Deleting: $fact\n" if $debug;
			delete $old_facts{$fact};
		}
	}
}

#
# Re-apply todo/fact rules in case attack level or rule base has changed.
#
sub redo_old_facts {

	for (keys %old_facts) {
		&satan_split($_);
		&infer_todo($_);
		&infer_facts($_);
	}
	&process_facts();
}

#
# Some scaffolding code for stand-alone testing.
#
if ($running_under_satan) {
	require 'perl/misc.pl';
	require 'perl/fix_hostname.pl';
	require 'perl/infer_todo.pl';
	require 'perl/infer_facts.pl';
	require 'perl/drop_fact.pl';
	require 'perl/hosttype.pl';
	require 'perl/services.pl';
	require 'perl/severities.pl';
	require 'perl/trust.pl';
} else {
	$running_under_satan = -1;
	$debug = 1;

	require 'perl/misc.pl';
	require 'perl/fix_hostname.pl';
	require 'perl/infer_todo.pl';
	require 'perl/infer_facts.pl';
	require 'perl/drop_fact.pl';
	require 'perl/hosttype.pl';
	require 'perl/services.pl';
	require 'perl/severities.pl';
	require 'perl/trust.pl';

	warn "facts.pl running in stand-alone mode\n";

	eval "sub add_todo { local(\$target,\$tool,\$args) = \@_;
		print \"add_todo: \$target,\$tool,\$args\\n\"; }\n";
	eval "sub new_target { local(\$new,\$old) = \@_;
		print \"new_target: \$new,\$old\\n\"; }\n";
	print "Adding new facts...\n";
	while (<>) {
		chop;
		&add_fact($_);
	}

	print "Processing new facts...\n";
	&process_facts();
}

1;
