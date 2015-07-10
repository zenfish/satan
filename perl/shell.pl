#
# Run a command with extreme prejudice and make sure it finishes.
#
#
# version 1, Mon Mar 20 14:09:35 1995, last mod by wietse
#

require 'config/paths.pl';
require 'perl/status.pl';

sub bad_cmd {
	local($command) = @_;

	return ($command =~ /[^-_ ,a-zA-Z0-9:.!\/]/);
}
		
sub open_cmd {
	local($handle, $timeout, $command) = @_;
	local($ret, $shell_cmd);

	$shell_cmd = "$TIMEOUT $timeout $command";

	if (&bad_cmd($shell_cmd)) {
		print "==> NOT RUNNING $shell_cmd (illegal characters)\n";
	} elsif ($debug) {
		$ret = open($handle, "$shell_cmd 2>/dev/null|");
	} else {
		$ret = open($handle, "$shell_cmd|");
	}
	&update_status("$shell_cmd");
	print "==> running $shell_cmd\n" if $debug;
	return $ret;
}

1;

