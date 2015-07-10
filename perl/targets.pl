#
# get_proximity(target) returns proximity by hostname.
#
# new_target(target, proximity) figures out what (still) needs to be done.
#
# save_all_hosts(path) saves the all_hosts table to file.
#
# read_all_hosts(path) reads the all_hosts table from file.
#
# drop_all_hosts(host) forget this host.
#
# merge_all_hosts(path) merge with in-core tables.
#
# set_host_time(host) set host access time (UTC).
#
# get_host_time(host) get host access time (UTC).
#
# version 3, Mon Mar 20 19:43:59 1995, last mod by wietse
#

require 'perl/policy-engine.pl';
require 'perl/subnets.pl';
require 'perl/domains.pl';
require 'perl/get_host.pl';
require 'perl/shell.pl';

#
# Get proximity for this host.
#
sub get_proximity
{
	local($target) = @_;

	return 100 unless defined($all_hosts{$target});
	return $all_hosts{$target}{'proximity'};
}

#
# Set up a list of primary targets. Primaries are special. They may be
# expanded. After all the primaries are known we may have to do something
# special, like forgetting everything we know about them.
#
sub add_primary_target {
	local($target) = @_;

	# Do we expand or do we scan a host.
	if ($target =~ /^\d+\.\d+\.\d+$/ || $attack_proximate_subnets) {
		print "Add-primary: expand $target...\n" if $debug;
		&target_acquisition($target, 0, $attack_level);
	} else {
		print "Add-primary: $target\n" if $debug;
		&new_target($target, 0);
	}
}

#
# Forget everything we know about primary targets (well, almost everything).
# We must re-read the data base, or memory would be polluted with stale
# inferences.
#
sub fix_primary_targets {
	local(%temp_targets);

	if ($primaries_deleted) {
		print "Primaries being rescanned, rebuilding tables.\n" if $debug;
		%temp_targets = %new_targets;
		&save_satan_data();
		&read_satan_data();
		%new_targets = %temp_targets;
		$primaries_deleted = 0;
	}
}

#
# Take a new potential target and let it cool down. This saves lots of
# duplicate work.
#
sub new_target
{
	local($target, $proximity) = @_;

	return unless $target;

	# Make sure all current primaries are rescanned, not the hosts that
	# were primaries during some earlier scan.
	if ($proximity == 0) {
		$primaries_deleted = defined($all_hosts{$target});
		drop_old_todos($target);
		drop_old_facts($target);
	}

	# Toss circular paths.
	if (defined($all_hosts{$target})
	    && $all_hosts{$target}{'proximity'} < $proximity) {
		return;
	}
	if (exists($new_targets{$target}) 
	    && $new_targets{$target} <= $proximity) {
		return;
	}

	# Keep primary, keep shortest path.
	if ($proximity == 0 || !exists($new_targets{$target}) 
	    || !defined($all_hosts{$target}) 
	    || $all_hosts{$target}{'proximity'} > $proximity) {
		$new_targets{$target} = $proximity;
		print "Add-target: $target prox $proximity\n" if $debug;
	}
}

#
# Probe targets.
#
sub process_targets
{
local($target, $proximity, $level, %temp_targets, %probe_targets);

while(sizeof(*new_targets) > 0) {
	%temp_targets = %new_targets;
	%new_targets = ();
	%probe_targets = ();

	# Generate probes according to policy restrictions.
	for $target (keys %temp_targets) {
		$proximity = $temp_targets{$target};

		# Instantiate new host.
		if (!defined($all_hosts{$target})) {
			&add_new_host($target, $proximity);
			}

		# Proximity may have changed.
		if ($all_hosts{$target}{'proximity'} > $proximity) {
			$all_hosts{$target}{'proximity'} = $proximity;
			}

		# Skip attack and target expansion if this host is off-limits.
		if (($level = &policy_engine($target, $proximity)) < 0) {
			print "process_targets: skip $target...\n" if $debug;
			next;
			}

		# Attack level contents may have changed.
		$all_hosts{$target}{'attack'} = $level;
		$check_alive_list .= "$target "
			if !defined($host_is_alive{$target});
		$probe_targets{$target} = $level;
		}
	}

	# Parallelize liveness checks.
	&check_alive();

	# Generate the probes.
	for $target (keys %probe_targets) {
		print "process_targets: probe $target...\n" if $debug;
		&target_attack($target, $probe_targets{$target});
	}
}

#
# Add one target to the %all_hosts list. Set proximity, IP, preliminary
# attack level, preliminary expansion flag.
#
sub add_new_host
{
local($target, $proximity) = @_;

$all_hosts{$target}{'proximity'} = $proximity;
$all_hosts{$target}{'attack'} = -1;
$all_hosts{$target}{'expand'} = 0;
$all_hosts{$target}{'IP'} = &get_host_addr($target);
$subnet_flag = 0;
$domain_flag = 0;
}

#
# ping a list of hosts and find out what hosts are alive.
#
sub check_alive {
	local ($host);

	if ($check_alive_list eq "") {
		return;
	}
	print "Check-pulse: $check_alive_list\n" if $debug;

	#
	# Cheat when ICMP is broken.
	#
	if ($dont_use_ping) {
		for $host (split(/\s+/, $check_alive_list)) {
			$host_is_alive{$host} = 1;
			$live_hosts++;
		}
		$check_alive_list = "";
		return;
	}

	#
	# Fping or bust.
	#
	&open_cmd(FPING, $long_timeout, "$FPING $check_alive_list") 
		|| die "cannot run $FPING: $!\n";
	while(<FPING>) {
		if (/(\S+) is alive/) {
			$host_is_alive{$1} = 1;
			$live_hosts++;
		} elsif ($debug && /(\S+) is unreachable/) {
			print "Skipping dead host - $1\n";
		}
	}
	close(FPING);
	$check_alive_list = "";
}

#
# target attack; assign attacks, throw into todo queue
#
sub target_attack
{
local($target, $level) = @_;

if ($host_is_alive{$target}) {
	print "Prox: $all_hosts{$target}{'proximity'}\n" if $debug;
	print "AL  : $all_hosts{$target}{'attack'}\n" if $debug;
	print "ALC : $all_hosts{$parent}{'attack'}\n" if $parent && $debug;

	for (@{$all_attacks[$level]}) {
		&add_todo($target, $_, "") if ! /\?/;
		}
	}
}

#
# target acq; get subnets
#
sub target_acquisition
{
local($target, $proximity, $level) = @_;
local($targets_found);

# Expand and then collect. Pass results through new_target() for
# consistent handling of constraints and policies.
&open_cmd (TARGETS, 120, "$GET_TARGETS $target");
while (<TARGETS>) {
	chop;
	next unless $_ = getfqdn($_);
	if (!defined($all_hosts{$_})) {
		&add_new_host($_, $proximity);
		}
	$all_hosts{$_}{'proximity'} = $proximity 
		if ($all_hosts{$_}{'proximity'} > $proximity);
	$all_hosts{$_}{'expand'} = 1;
	$host_is_alive{$_} = 1;
	$live_hosts++;
	&new_target($_, $proximity);
	$targets_found++;
	}
close(TARGETS);
die "$GET_TARGETS failed - unable to expand subnet $target\n" 
	if ($? || $targets_found < 1)
}

#
# Save the %all_hosts array
#
sub save_all_hosts {
local($all_hosts_file) = @_;
local($record, $host, $ip, $proximity, $level, $expand, $time);

open(ALL_HOSTS, ">$all_hosts_file") ||
	die "Can't open $all_hosts_file (cache for all-hosts) for writing\n";

for $host (keys %all_hosts) {
	$ip = $all_hosts{$host}{'IP'};
	$proximity = $all_hosts{$host}{'proximity'};
	$level = $all_hosts{$host}{'attack'};
	$expand = $all_hosts{$host}{'expand'};
	$time = $all_hosts{$host}{'time'};
	$record = "$host|$ip|$proximity|$level|$expand|$time";
	print ALL_HOSTS "$record\n";
	# print "save_all_hosts: $record\n" if $debug;
	}
close(ALL_HOSTS);
 
}

#
# Reset host info and derivatives
#
sub clear_all_hosts {
	%all_hosts = ();
	%new_targets = ();
	&clear_subnet_info();
	&clear_domain_info();
}

#
# suck in the all-hosts array from file
#
sub read_all_hosts {
	local($all_hosts_file) = @_;

	&clear_all_hosts();
	&merge_all_hosts($all_hosts_file);
}

#
# merge the in-core all-hosts array with one from file
#
sub merge_all_hosts {
local($all_hosts_file) = @_;
local($count, $host, $ip, $proximity, $level, $time);

open(ALL_HOSTS, $all_hosts_file) ||
	die "Can't open $all_hosts_file (cache for all-hosts) for reading\n";
	print "Reading all hosts info from $all_hosts_file...\n" if $debug;

# read one line at a time, herky jerky motion... one trick pony, man...
while (<ALL_HOSTS>) {
	chop;
	$count = ($host, $ip, $proximity, $level, $expand, $time) = split(/\|/);
	if ($count != 6) {
		warn "corrupted $all_hosts_file: $_\n";
		next;
		}
	if (!defined($all_hosts{$host}{'proximity'})
	    || $all_hosts{$host}{'proximity'} > $proximity) {
		$all_hosts{$host}{'IP'} = $ip;
		$all_hosts{$host}{'proximity'} = $proximity;
		$all_hosts{$host}{'attack'} = $level;
		$all_hosts{$host}{'expand'} = $expand;
		$all_hosts{$host}{'time'} = $time;
		}
	}
close(ALL_HOSTS);
}

#
# set the last access time for this host. Use numerical form for easy sorting.
#
sub set_host_time {
	local($host) = @_;

	$all_hosts{$host}{'time'} = time();
}

#
# get the last access time for this host. Use numerical form for easy sorting.
#
sub get_host_time {
	local($host) = @_;

	return $all_hosts{$host}{'time'};
}


1;
