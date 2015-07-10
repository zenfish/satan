#
# Report host by name
#
print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Hosts - By Name </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Hosts - By Name </H1>
<hr>

<FORM METHOD=POST ACTION="satan_info_host_action.pl">

<strong>Enter a host name (<I>host.domain</I> preferred):</strong>
<h3>
<INPUT TYPE="reset" VALUE=" Reset ">
<INPUT SIZE="30" NAME="_query_host" Value="$_query_host">
<INPUT TYPE="submit" VALUE=" Display host ">
</h3>

</FORM>

<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
