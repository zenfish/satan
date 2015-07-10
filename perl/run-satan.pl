require 'perl/satan-data.pl';
require 'perl/misc.pl';
require 'perl/getfqdn.pl';
require 'perl/get_host.pl';
require 'perl/suser.pl';

sub run_satan {
	local($primaries) = @_;
	local($target);

	#
	# Don't die silently when tools cannot be run with sufficient privilege.
	#
	die "SATAN needs root privileges for data collection.\n" if $>;

	#
	# Clear the table with alive hosts.
	#
	%host_is_alive = ();

	#
	# Set up a list of primary target hosts.
	#
	die "no primary target was specified" if $primaries eq "";
	for $primary_target (split(/\s+/, $primaries)) {
		#
		# Jump hoops to get at the official host name in case foo.com is
		# in reality called bar.foo.com.
		#
		if ($primary_target =~ /^[a-zA-Z]+.*|^\d+\.\d+\.\d+\.\d+$/) {
			$primary_target = $target
			    if ($target = &getfqdn(&get_host_name(
				    &get_host_addr($primary_target))));
		}

		# schedule probe assignments...
		&add_primary_target($primary_target, 0);
	}
	#
	# In case we must do something special with primary target hosts.
	#
	&fix_primary_targets();

	#
	# Switch control between the data collection engine and the
	# inference engine until both run out of new ideas. Checkpoint
	# after each iteration.
	#
	while(sizeof(*new_targets)||sizeof(*new_todos)||sizeof(*new_facts)) {
		&process_targets();
		&process_todos();
		&process_facts();
		&save_satan_data();
	}
	&update_status("SATAN run completed");
}

1;
