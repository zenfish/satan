#
# Collect data and keep the user informed.
#

#
# Make sure they specified a host at all.
#
if ($primary_target eq "") {
	print CLIENT <<EOF
<HTML>
<HEAD>
<TITLE>Error - Missing input </TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Error - Missing input </H1>
<hr>
No primary host or network was specified.
</BODY>
</HTML>
EOF
;
	die "\n";
}

#
# If a host name was specified look up the official name.
#
if ($primary_target !~ /^\d+\./) {
	$tmp_target = &getfqdn(&get_host_name(&get_host_addr($primary_target)));
	if ($tmp_target eq "") {
		print CLIENT <<EOF
<HTML>
<HEAD>
<TITLE>Error - Unknown host</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Error - Unknown host</H1>
<hr>
Unable to look up host <TT> $primary_target </TT>
</BODY>
</HTML>
EOF
;	
		die "\n";
	}
	$primary_target = $tmp_target;
}

#
# Primary target is OK, start data collection.
#
print CLIENT <<EOF
<HTML>
<HEAD>
<TITLE>SATAN data collection </TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> SATAN data collection</H1>
<hr>
<B>Data collection in progress...</B>

<P>

EOF
;

$_live_hosts = $live_hosts;

&run_satan($primary_target);

$_live_hosts = $live_hosts - $_live_hosts;

print CLIENT <<EOF;
<P>

<B>Data collection completed ($_live_hosts host(s) visited).</B>
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=../reporting/analysis.pl>Continue with report and analysis</a>
EOF

if (&getfqdn($tmp_target)) {
	print CLIENT <<EOF;
| <a href="../reporting/satan_info_host.pl,$tmp_target,">
View primary target results</a>
EOF
}
print CLIENT <<EOF
</BODY>
</HTML>
EOF
