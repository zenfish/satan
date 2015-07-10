#
# Display a list of hosts sorted on some attribute; hosts may be member
# of more than group.
#

&make_severity_info();

$_sort_title = "";
%_sort_group = ();
$_sort_sub = "";
%_not_linked = ();
$_sort_note = "";

#
# Factor out sort-order dependent code.
#

sub sort_alpha {
        $a cmp $b;
}

sub sort_severity {
	$_res = ($severity_host_count{$b} <=> $severity_host_count{$a});
	return ($_res != 0) ? $_res : $a cmp $b;
}

sub sort_ip {
	local($aip,$bip);
	for $ip (split(/\./,$a)) { $aip = $aip * 256 + $ip; }
	for $ip (split(/\./,$b)) { $bip = $bip * 256 + $ip; }
	return $aip <=> $bip;
}

$_sort_toc = "sort_alpha";

if ($_sort_order eq "" || $_sort_order eq "name") {
	$_sort_group{""} = join(' ', @_hosts);
} elsif ($_sort_order eq "severity") {
	$_sort_group{""} = join(' ', @_hosts);
	$_sort_sub = "sort_severity";
} elsif ($_sort_order eq "subnet") {
	&make_subnet_info();
	$_sort_title = "Subnet";
	$_sort_link = "satan_results_subnet.pl";
	for (@_hosts) { $_sort_group{$host_subnet{$_}} .= "$_ "; }
	$_sort_toc = "sort_ip";
} elsif ($_sort_order eq "type") {
	&make_hosttype_info();
	$_sort_title = "System type";
	$_sort_link = "satan_info_OStype.pl";
	for (@_hosts) { $_sort_group{$hosttype{$_}} .= "$_ "; }
} elsif ($_sort_order eq "domain") {
	&make_domain_info();
	$_sort_title = "Internet domain";
	$_sort_link = "satan_results_domain.pl";
	for (@_hosts) { $_sort_group{$host_domain{$_}} .= "$_ "; }
} elsif ($_sort_order eq "severity_type") {
	$_sort_title = "Problem type";
	$_sort_link = "satan_severity_hosts.pl";
	for $_host (@_hosts) {
		if (exists($severity_host_type_info{$_host})) {
			for $_type (keys %{$severity_host_type_info{$_host}}) {
				$_sort_group{$_type} .= "$_host ";
			}
		} else {
			$_type = "(none)";
			$_sort_group{$_type} .= "$_host ";
			$_not_linked{$_type} = 1;
		}
	}
	$_sort_note = "Note: a host may appear in more than one category.";
} elsif ($_sort_order eq "trusted_type") {
	$_sort_title = "Hosts trusted by $_trustee";
	for $_host (@_hosts) {
		for $_type (keys %{$trust_host_type{"$_host $_trustee"}}) {
			$_sort_group{$_type} .= "$_host ";
			$_not_linked{$_type} = 1;
		}
	}
	$_sort_note = "Note: a host may appear in more than one category.";
} elsif ($_sort_order eq "trustee_type") {
	$_sort_title = "Hosts trusting $_trusted";
	for $_host (@_hosts) {
		for $_type (keys %{$trust_host_type{"$_trusted $_host"}}) {
			$_sort_group{$_type} .= "$_host ";
			$_not_linked{$_type} = 1;
		}
	}
	$_sort_note = "Note: a host may appear in more than one category.";
}

#
# Make a nice table of contents.
#

if ($_sort_title) {
	print CLIENT <<EOF;
	<hr>
	<h3>$_sort_title: table of contents.</h3>
	<ul>
EOF
	for $_group (sort $_sort_toc keys %_sort_group) {
		$_count = $_bad = 0;
		for $_host (split(/\s/, $_sort_group{$_group})) {
			$_count++;
			$_bad++ if exists($severity_host_type_info{$_host});
		}
		$_dot = $_bad ? "reddot" : "blackdot";
		$_alt = $_bad ? "*" : "-";
		$_counts = ($_bad != $_count) ? "($_bad/$_count)" : "($_count)";
		print CLIENT <<EOF;
		<dt><IMG SRC="$HTML_ROOT/dots/$_dot.gif" ALT="$_alt"> 
		<a href="#$_group">$_group</a> $_counts
EOF
	}
	print CLIENT <<EOF;
	</ul>
	$_sort_note
	<hr>
EOF
}

#
# Finally, list all those groups and their respective host members.
#

$_sort_sub = "sort_alpha" if $_sort_sub eq "";

for $_group (sort $_sort_toc keys %_sort_group) {
	if ($_sort_title) {
		print CLIENT <<EOF;
		<h3>
		<a name="$_group">
		$_sort_title: 
EOF
		if ($_not_linked{$_group}) {
			print CLIENT <<EOF;
			$_group.
EOF
		} else {
			($_GROUP = $_group) =~ tr / \//?!/;
			print CLIENT <<EOF;
			<a href="$_sort_link,$_GROUP,">$_group</a>.
EOF
		}
		print CLIENT <<EOF;
		</h3>
EOF
	}
	print CLIENT <<EOF;
	<ul>
EOF
	for (sort $_sort_sub split(/\s/, $_sort_group{$_group})) {
		if ($severity_host_count{$_}) {
			$_dot = "reddot";
			$_alt = "*";
			$_bad = "($severity_host_count{$_})";
		} else {
			$_dot = "blackdot";
			$_alt = "-";
			$_bad = "";
		}
		print CLIENT <<EOF;
		<dt><IMG SRC=$HTML_ROOT/dots/$_dot.gif ALT="$_alt"> 
		<a href="satan_info_host.pl,$_,"> $_</a> $_bad
EOF
	}
	print CLIENT <<EOF;
	</ul>
EOF
}
