#
# List hosts that provide a specific service.
#
($_SERVICE, $_sort_order) = split(/,/, $html_script_args);
($_service = $_SERVICE) =~ tr/?!/ \//;

print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Host Table - $_service Servers </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Host Table - $_service Servers </H1>
<hr>

<h3> 
$server_severities{$_service} Vulnerable/$server_counts{$_service} total.
Vulnerability counts in parentheses.
</h3>

<H4> Sort hosts by:
<a href="satan_info_servers.pl,$_SERVICE,name,">name</a> |
<a href="satan_info_servers.pl,$_SERVICE,domain,">domain</a> |
<a href="satan_info_servers.pl,$_SERVICE,type,">system type</a> |
<a href="satan_info_servers.pl,$_SERVICE,subnet,">subnet</a> |
<a href="satan_info_servers.pl,$_SERVICE,severity,">problem count</a> |
<a href="satan_info_servers.pl,$_SERVICE,severity_type,">problem type</a>
</H4>
EOF

@_hosts = keys %{$servers{$_service}};
do "$html_root/reporting/sort_hosts.pl";
print CLIENT $@ if $@;

print CLIENT <<EOF;
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
