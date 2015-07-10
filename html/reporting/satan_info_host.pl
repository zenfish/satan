#
# Show information about a specific host.
#
($_host) = split(/,/, $html_script_args);
($_type = $hosttype{$_host}) =~ tr / \//?!/;

print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Results - $_host </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Results - $_host </H1>
<hr>
<h3>General host information:</h3>
<ul>
EOF

#
# Refresh the host type and service tables.
#
&make_hosttype_info();
&make_service_info();
&make_subnet_info();

$_exists = 0;

if (exists($hosttype{$_host})) {
	print CLIENT <<EOF;
	<li>Host type: <A HREF="satan_info_OStype.pl,$_type,">$hosttype{$_host}</A>
EOF
	$_exists = 1;
}

if (exists($server_info{$_host})) {
	for (sort split(/\n/, $server_info{$_host})) {
		# Mask blanks and slashes
		($_service = $_) =~ tr / \//?!/;
		print CLIENT <<EOF;
		<li> <A HREF="satan_info_servers.pl,$_service,"> $_ </A> server
EOF
	}
	$_exists = 1;
}

if (exists($client_info{$_host})) {
	for (sort split(/\n/, $client_info{$_host})) {
		# Mask blanks and slashes
		($_service = $_) =~ tr / \//?!/;
		print CLIENT <<EOF;
		<li> <A HREF="satan_info_clients.pl,$_service,"> $_ </A> client
EOF
	}
	$_exists = 1;
}

if (exists($all_hosts{$_host})) {
	($_subnet = $all_hosts{$_host}{IP}) =~ s/\.[^.]*$//;
	print CLIENT <<EOF;
	<li> Subnet <A HREF="satan_results_subnet.pl,$_subnet,"> $_subnet </A>
EOF
	$_exists = 1;
}

if (exists($total_trustee_count{$_host})) {
	$_count = split(/\s+/, $total_trustee_names{$_host});
	print CLIENT <<EOF;
	<li> $_count
	<A HREF="satan_results_trusting.pl,$_host,trustee_type,"> Trusting host(s) </a>
EOF
	$_exists = 1;
}

if (exists($total_trusted_count{$_host})) {
	$_count = split(/\s+/, $total_trusted_names{$_host});
	print CLIENT <<EOF;
	<li> $_count
	<A HREF="satan_results_trusted.pl,$_host,trusted_type,"> Trusted host(s) </a>
EOF
	$_exists = 1;
}

if (exists($all_hosts{$_host}) && defined($all_hosts{$_host}{'attack'})) {
	@_level = ('none', 'light', 'normal', 'heavy', 'all out');
	print CLIENT <<EOF;
	<li> Scanning level: @_level[1 + $all_hosts{$_host}{'attack'}]
EOF
	$_exists = 1;
}

if (exists($all_hosts{$_host}) && defined($all_hosts{$_host}{'time'})
	&& $all_hosts{$_host}{'time'} > 1) {
	$_time = &ctime($all_hosts{$_host}{'time'});
	print CLIENT <<EOF;
	<li> Last scan: $_time
EOF
	$_exists = 1;
}


print CLIENT "</ul>\n";

if (exists($severity_host_type_info{$_host})) {
	print CLIENT "<h3>Vulnerability information:</h3><ul>\n";
	for (keys %{$severity_host_type_info{$_host}}) {
		($_tutorials = $_) =~ tr / /_/;
		for (sort split(/\n/, $severity_host_type_info{$_host}{$_})) {
			&satan_split($_);
			print CLIENT <<EOF;
	<li> <A HREF="$HTML_ROOT/tutorials/vulnerability/$_tutorials.html">$text</A>
EOF
		}
	}
	$_exists = 1;
}
print CLIENT <<EOF;
</ul>
EOF

if ($_exists) {
	print CLIENT <<EOF;
	<h3>Actions:</h3>
	<ul>
	<li> <A HREF="$HTML_SERVER/running/satan_run_form.pl,$_host,">Scan this host</a>
	</ul>
EOF
} else {
	print CLIENT <<EOF;
	<h3>No information found on host $_host.</h3>
EOF
}

print CLIENT <<EOF;
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
