#
# Translate HMTL arg list form.
#
if ($_query_host eq "") {
    print CLIENT <<EOF;
<HTML>
<HEAD>
<title>Error - No Host </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Error - No Host </H1>
<hr>
<h2>Error: no host name specified. Try again.</h2>
EOF
} else {
    $_query_host =~ tr /A-Z/a-z/;
    $_query_host = &getfqdn($_query_host) if (&getfqdn($_query_host));
    if (defined($all_hosts{$_query_host})) {
	$html_script_args = $_query_host;
	do "$html_root/reporting/satan_info_host.pl";
	print CLIENT $@ if $@;
    } else {
	print CLIENT <<EOF;
<HTML>
<HEAD>
<title>Error - Unknown Host </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Error - Unknown Host </H1>
<hr>
<h2>Error: unknown host name specified: $_query_host. Try again.</h2>
EOF
    }
}
print CLIENT <<EOF
</BODY>
</HTML>
EOF
