#
# SATAN data management routines.
#
require 'perl/targets.pl';
require 'perl/todo.pl';
require 'perl/facts.pl';

#
# Reset and point path names to new or existing data directory.
#
sub init_satan_data {
	local($directory);

	&clear_satan_data();
	&find_satan_data();
}

#
# Point path names to new or existing data directory.
#
sub find_satan_data {
	if ($satan_data =~ /\// ) {
		$directory = $satan_data;
	} else {
		(-d "results") || mkdir("results",0700) 
			|| die "results: invalid directory: $!\n";
		$directory = "results/$satan_data";
	}
	(-d "$directory") || mkdir("$directory",0700) 
		|| die "$satan_data: invalid directory: $!\n";

	$todo_file = "$directory/todo";
	$facts_file = "$directory/facts";
	$all_hosts_file = "$directory/all-hosts";
}

#
# Erase all in-core satan data structures.
#
sub clear_satan_data {
	&clear_all_hosts();
	&clear_facts();
	&clear_todos();
}

#
# Forget non-inference stuff we know about these hosts. We must save/reload
# the tables later, or memory will be polluted with stale inferences.
#
sub drop_satan_data {
	local($hosts) = @_;
	local($host);

	for $host (split(/\s+/, $hosts)) {
		&drop_all_hosts($host);
		&drop_old_todos($host);
		&drop_old_facts($host);
	}
}

#
# Read satan data from file. Existing in-core data is lost.
#
sub read_satan_data {

	&clear_satan_data();

	print "Reading $satan_data files...\n" if (-s $facts_file && $debug);

	&read_all_hosts($all_hosts_file) if -f $all_hosts_file;
	&read_facts($facts_file) if -f $facts_file;
	&read_todos($todo_file) if -f $todo_file;

	print "Done reading $satan_data files\n" if (-s $facts_file && $debug);
}

#
# Save satan data to file. Order may matter, in case we crash.
#
sub save_satan_data {
	&save_facts("$facts_file.new");
	rename("$facts_file.new", $facts_file)
		|| die "rename $facts_file.new -> $facts_file: $!\n";

	&save_todos("$todo_file.new");
	rename("$todo_file.new", $todo_file)
		|| die "rename $todo_file.new -> $todo_file: $!\n";

	&save_all_hosts("$all_hosts_file.new");
	rename("$all_hosts_file.new", $all_hosts_file)
		|| die "rename $all_hosts_file.new -> $all_hosts_file: $!\n";
}

#
# Merge data with in-core tables.
#
sub merge_satan_data {
	&merge_all_hosts($all_hosts_file) if -f $all_hosts_file;
	&merge_facts($facts_file) if -f $facts_file;
	&merge_todos($todo_file) if -f $todo_file;
}
