#
# List all hosts in a subnet
#
($_subnet, $_sort_order) = split(/,/, $html_script_args);

print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Host Table - Subnet $_subnet</title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Host Table - Subnet $_subnet</h1>
<hr>

<h3> 
$subnet_severities{$_subnet} Vulnerable/$subnet_count{$_subnet} total.
Vulnerability counts in parentheses.
</h3>

<H4> Sort hosts by:
<A HREF="satan_results_subnet.pl,$_subnet,name,">name</a> |
<A HREF="satan_results_subnet.pl,$_subnet,domain,">domain</a> |
<A HREF="satan_results_subnet.pl,$_subnet,type,">system type</a> |
<A HREF="satan_results_subnet.pl,$_subnet,severity,">problem count</a> |
<A HREF="satan_results_subnet.pl,$_subnet,severity_type,">problem type</a>
</H4>
EOF

@_hosts = split(/\s/, $all_subnets{$_subnet});
do "$html_root/reporting/sort_hosts.pl";
print CLIENT $@ if $@;

print CLIENT <<EOF;
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
