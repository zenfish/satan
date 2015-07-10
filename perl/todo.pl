#
# add_todo($record) add one record to the new todo list.
#
# process_todos() iterates over the new todo list and generates new facts.
#
# save_todos($path) saves the old todos to the named file.
#
# drop_old_todos($host) forget everything we know about a host.
#
# read_todos($path) load tables from file.
#
# merge_todos($path) merge with in-core tables.
#
# version 2, Mon Mar 20 19:47:07 1995, last mod by wietse
#
require 'perl/shell.pl';

#
# Add one probe to the new todo list.
#
sub add_todo {
local($host, $tool, $args) = @_;
local($record);

$record = "$host|$tool|$args";

if (!exists($old_todos{$record}) && !exists($new_todos{$record})) { 
	$new_todos{$record} = $record; 
	print "Add-todo: $record\n" if $debug;
	}
}

#
# Add one probe to the new todo list, ignore args when looking for dups.
#
sub add_todo_ignore_args {
local($host, $tool, $args) = @_;
local($key, $record);

$key = "$host|$tool";
$record = "$host|$tool|$args";

if (!exists($old_todos{$key})) { 
	$new_todos{$key} = $record; 
	print "Add-todo: $key ($args)\n" if $debug;
	}
}

#
# Iterate over the new todo list until nothing new shows up. Skip tools
# that we aren't supposed to run at this attack level.
#
sub process_todos {
local($key,%temp_todos,$allowed_tools);
local($target, $tool, $args, $level, $probe);

while (sizeof(*new_todos) > 0) {
	%temp_todos = %new_todos;
	%new_todos = ();
	for $key (keys %temp_todos) {
		($target, $tool, $args) = split(/\|/, $temp_todos{$key}, 3);
		next unless exists($all_hosts{$target});
		$level = $all_hosts{$target}{'attack'};
		next unless $level >= 0;
		for $probe (@{$all_attacks[$level]}) {
			if ($tool eq $probe || "$tool?" eq $probe || $probe eq "*?") {
				$old_todos{$key} = 1;
				&run_next_todo($target, $tool, $args);
				last;
				}
			}
		}
	}
}

#
# Save old todo list to file.
#
sub save_todos {
local($path) = @_;

open(TODO, ">$path") || die "cannot save old todo list to $path: $!";
for $key (keys %old_todos) {
	print TODO "$key\n";
	}
close(TODO);
}

#
# Reset todo tables and derivatives
#
sub clear_todos {
%new_todos = ();
%old_todos = ();
}

#
# Drop old entries on a specific host.
#
sub drop_old_todos {
	local($host) = @_;
	local($key, $target, $tool, $args);

	for $key (keys %old_todos) {
		($target, $tool, $args) = split(/\|/, $key);
		delete $old_todos{$key} if $target eq $host;
	}
}

#
# Read old todo list from file.
#
sub read_todos {
local($path) = @_;

&clear_todos();
&merge_todos($path);
}

#
# Merge old todo list with in-core table.
#
sub merge_todos {
local($path) = @_;

open(TODO, $path) || die "cannot read old todo list from $path: $!";
print "Reading old todo list from $path...\n" if $debug;
while (<TODO>) {
	chop;
	$old_todos{$_} = 1;
	}
close(TODO);
}

#
# Run a tool and collect its output.
#
sub run_next_todo
{
local($target, $tool, $args) = @_;
local($text, $ttl);

$ttl = (defined($timeouts{$tool}) ? $timeouts{$tool} : $timeout);

$command = "bin/$tool $args $target";

# Update host last access time.
&set_host_time($target);

# Damn the torpedoes!
die "Can't run $tool\n" unless &open_cmd(TOOL, $ttl, $command);

while (<TOOL>) {
	chop;
	&add_fact($_);
	}

close(TOOL);

# Did we fly like the mighty turkey or soar like an...?
# If the former, assume that we need to output an error record...
if ($?) {
	# based on exit value, decide what happened:
	if ($? == $timeout_kill) { $text = "program timed out"; }
	elsif ($? > 0 && $? < $timeout_kill) {
		$text = "internal program error $?";
		}
	else { $text = "unknown error #$?"; }
 
	&add_fact("$target|$tool|u|||||$text");
	}

}

1;
