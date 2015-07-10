#
# Show all hosts with a specific vulnerability.
#
($_SEVERITY, $_sort_order) = split(/,/, $html_script_args);
($_severity = $_SEVERITY) =~ tr /?!/ \//;
($_tutorial = $_severity) =~ tr / /_/;

print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Host Table - $_severity </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Host Table - $_severity </H1>
<hr>

<h2> 
Tutorial: 
<a href="$HTML_ROOT/tutorials/vulnerability/$_tutorial.html>$_severity</a>.
</h2>

<h3> 
$severity_type_count{$_severity} Host(s). 
Number of vulnerabilities in parentheses. 
</h3>

<H4> Sort hosts by:
<a href="satan_severity_hosts.pl,$_SEVERITY,name,">name</a> |
<a href="satan_severity_hosts.pl,$_SEVERITY,domain,">domain</a> |
<a href="satan_severity_hosts.pl,$_SEVERITY,type,">system type</a> |
<a href="satan_severity_hosts.pl,$_SEVERITY,subnet,">subnet</a> |
<a href="satan_severity_hosts.pl,$_SEVERITY,severity,">problem count</a> 
</H4>
EOF

@_hosts = keys %{$severity_type_host_info{$_severity}};
do "$html_root/reporting/sort_hosts.pl";
print CLIENT $@ if $@;

print CLIENT <<EOF;
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
