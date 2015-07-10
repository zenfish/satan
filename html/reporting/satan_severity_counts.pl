#
# Sort hosts by number of vulnerabilties.
#
&make_severity_info();

print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Vulnerabilities - By Counts </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Vulnerabilities - By Counts </H1>
<hr>
<h3> Hosts by descending vulnerability counts. </h3>
EOF

$_sort_order = "severity";
@_hosts = keys %severity_host_count;
do "$html_root/reporting/sort_hosts.pl";
print CLIENT $@ if $@;

print CLIENT <<EOF
No vulnerability information found.
EOF
	if @_hosts == 0;

print CLIENT <<EOF;
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
