#
# rewrite satan.cf after the user changes it.
#
# suck in the changes, then just cycle through each line of the .cf file.
# if there is a match, put the new value in there.
#
sub write_config_file {
local($new_values) = @_;
local(%new_values, $variable, $old_variable, $old_value);

#
# split the strings into something easier to handle
for ( split(/\n/, $new_values) ) {
	next if !$_;

	($variable, $value) = split(/=/, $_);

	# need to stick a dollar sign in front of var
	$variable = "\$" . "$variable";
	# and quotes around non-numbers
	if ($value !~ /^\d+$/) { $value = "\"$value\""; }

	$new_values{$variable} = $value;
	}

#
# open the config and the scratch file
#
die "Can't read $SATAN_CF file!\n" unless open(CF, "$SATAN_CF");
die "Can't write $SATAN_CF.new file!\n" unless open(CFN, ">$SATAN_CF.new");

while (<CF>) {
	# punt if the going gets too tough...
	if (!/^\$/) {
		print CFN $_;
		next;
		}
	
	chop;
	($old_variable, $old_value) = split(/=\s+/, $_);

	# kill spaces and semicolons
	$old_variable =~ s/\s//g;
	$old_value =~ s/;//g;

	# suck in the lines, compare them to each of the vars gotten from user
	for $variable (keys %new_values) {
		if ($variable eq $old_variable) {
			$old_value = $new_values{$variable};
			}
		}

	print "CF: $_ ($old_variable, $old_value)\n";
	print CFN "$old_variable = $old_value;\n";
	}

close(CF);
close(CFN);

# move the evidence to where it belongs... old to .old, new to .cf:
system("mv $SATAN_CF $SATAN_CF.old");
system("mv $SATAN_CF.new $SATAN_CF");

}

1;
