#
# List all hosts in an internet domain
#
($_domain, $_sort_order) = split(/,/, $html_script_args);

print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Host Table - Domain $_domain</title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Host Table - Domain $_domain</h1>
<hr>

<h3> 
$domain_severities{$_domain} Vulnerable/$domain_count{$_domain} total.
Vulnerability counts in parentheses.
</h3>

<H4> Sort hosts by:
<A HREF="satan_results_domain.pl,$_domain,name,">name</a> |
<A HREF="satan_results_domain.pl,$_domain,type,">system type</a> |
<A HREF="satan_results_domain.pl,$_domain,subnet,">subnet</a> |
<A HREF="satan_results_domain.pl,$_domain,severity,">problem count</a> |
<A HREF="satan_results_domain.pl,$_domain,severity_type,">problem type</a>
</H4>
EOF

@_hosts = split(/\s+/, $all_domains{$_domain});
do "$html_root/reporting/sort_hosts.pl";
print CLIENT $@ if $@;

print CLIENT <<EOF;
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
