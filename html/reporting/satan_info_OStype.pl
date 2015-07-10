#
# List all hosts that run a specific operating system version.
#

&make_hosttype_info();

($_TYPE, $_sort_order) = split(/,/, $html_script_args);
($_type = $_TYPE) =~ tr/?!/ \//;

print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Host Table - $_type Systems </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Host Table - $_type Systems </H1>
<hr>

<h3> 
$systype_severities{$_type} Vulnerable/$systype_counts{$_type} total.
Vulnerability counts in parentheses.
</h3>

<H4> Sort hosts by:
<a href="satan_info_OStype.pl,$_TYPE,name,">name</a> |
<a href="satan_info_OStype.pl,$_TYPE,domain,">domain</a> |
<a href="satan_info_OStype.pl,$_TYPE,subnet,">subnet</a> |
<a href="satan_info_OStype.pl,$_TYPE,severity,">problem count</a> |
<a href="satan_info_OStype.pl,$_TYPE,severity_type,">problem type</a>
</H4>

</FORM>
EOF

@_hosts = split(/\n/, $hosts_by_systype{$_type});
do "$html_root/reporting/sort_hosts.pl";
print CLIENT $@ if $@;

print CLIENT <<EOF;
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
