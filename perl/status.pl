#
# Maintain time, date, satan status file and GUI feedback.
#

require 'perllib/ctime.pl';
require $SATAN_CF;

#
# Convert to time of day.
#
sub hhmmss {
	local($time) = @_;
	local($sec, $min, $hour);
	
	($sec, $min, $hour) = localtime($time);
	return sprintf "%02d:%02d:%02d", "$hour", "$min", "$sec";
}

sub update_status {
	local($text) = @_;

	$now = &hhmmss(time());

	# GUI feedback.
	print CLIENT "$now $text<br>\n" if $running_from_html;

	# Status file.
	die "Can't open status file $status_file\n" 
		unless open(STATUS, ">>$status_file");
	print STATUS "$now $text\n";
	close STATUS;
}
