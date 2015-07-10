#
# Report vulnerability classes
#
sub sort_numeric {
	$severity_type_count{$b} <=> $severity_type_count{$a};
}

print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Vulnerabilities - By Type</title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Vulnerabilities - By Type</H1>
<hr>
<h3>Number of hosts per vulnerability type.</h3>
EOF

&make_severity_info();

if (sizeof(*severity_type_host_info) > 0) {
    print CLIENT <<EOF;
<ul>
EOF
    for (sort sort_numeric keys %severity_type_host_info) {
	($_type = $_) =~ tr / \//?!/;

	print CLIENT <<EOF;
	<li> 
	<a href="satan_severity_hosts.pl,$_type,">
	$_ - $severity_type_count{$_} host(s)</a>
EOF
    }
    print CLIENT <<EOF;
</ul>
	<strong>Note: hosts may appear in multiple categories. </strong>
EOF
} else {
    print CLIENT <<EOF
No vulnerability information found.
EOF
}

print CLIENT <<EOF
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
