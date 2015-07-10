#
# version 1, Tue Mar 21 20:21:33 1995, last mod by wietse
#
sub policy_engine
{
local($target, $proximity) = @_;

#
# Respect the maximal proximity level.
#
if ($proximity > $max_proximity_level) {
	print "policy: pruning $target via proximity level\n" if $debug;
	return -1;
}

#
# Do not attack "verboten" hosts.
#
if (&target_is_exception($target)) {
	print "policy: pruning $target via exception\n" if $debug;
	return -1;
}

#
# attacks tend to get weaker the farther away from home; do they
# wither and die, or keep going at a low level?
#
$new_attack_level = $attack_level - ($proximity * $proximity_descent);
if ($new_attack_level < 0) {
	if (!$sub_zero_proximity) {
		print "policy: pruning $target via attack level < 0\n";
		return -1;
		}
	else { 
		$new_attack_level = 0; 
		}
	}

print "policy: $target prox $proximity level $new_attack_level\n" if $debug;

return $new_attack_level;

}

#
# Does target match list of shell-like patterns?
#
sub match_host {
    local($target, $patterns) = @_;
    local($pattern);

    for $pattern (split(/(,|\s)+/, $patterns)) {
	$pattern =~ s/\.$//;	# strip trailing dot
	$pattern =~ s/^\.//;	# strip leading dot
	$pattern =~ s/\./\\./g;	# quote dots
	$pattern =~ s/\*/.*/g;	# translate regexp star to shell star
	if ($pattern =~ /^\d+/) {
	    return 1 if ($all_hosts{$target}{'IP'} =~ /^$pattern\b/);
	} else {
	    return 1 if ($target =~ /\b$pattern$/);
	}
    }
    return 0;
}

#
# don't want to attack certain sites, like .mil, etc.
#
sub target_is_exception
{
    local($target) = @_;
    local($pattern);

    #
    # if this is set, only attack things that contain this string:
    if ($only_attack_these && !&match_host($target, $only_attack_these)) {
	return 1;
    }
    #
    # if this is set, don't attack things that contain this string:
    if ($dont_attack_these && &match_host($target, $dont_attack_these)) {
	return 1;
    }
    #
    # else, nothing is wrong, go for it...
    return 0; 
}

1;
