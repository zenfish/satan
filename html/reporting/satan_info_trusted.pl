#
# Report which hosts are trusted how many times
#
sub sort_numerically {
	$total_trustee_count{$b} <=> $total_trustee_count{$a};
}

print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Trust - Trusted Hosts</title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Trust - Trusted Hosts</H1>
<hr>
<h3>Trusted hosts (by number of trusting hosts).</h3>
<ul>
EOF

&make_severity_info();

for (sort sort_numerically keys %total_trustee_count) {
	$_dot = exists($severity_host_type_info{$_}) ? "reddot" : "blackdot";
	$_alt = exists($severity_host_type_info{$_}) ? "*" : "-";
	print CLIENT <<EOF;
	<dt><IMG SRC=$HTML_ROOT/dots/$_dot.gif ALT="$_alt"> 
	<A HREF="satan_info_host.pl,$_,">$_</A> -
	<A HREF="satan_results_trusting.pl,$_,trustee_type,"> $total_trustee_count{$_} host(s)</A>
EOF
}

print CLIENT <<EOF;
</ul>
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
