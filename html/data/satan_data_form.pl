#
# Select SATAN data base
#
$_satan_dir = "";
@_results = `ls results`;
for (@_results) { chop; }

print CLIENT <<EOF;
<HTML>
<HEAD>
<title> SATAN Data Management </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> SATAN Data Management </H1>
<hr>

<ul>
<p><li><a href="#open">Open or create SATAN database</a>
<p><li><a href="#merge">Merge existing SATAN database</a>
</ul>
<hr>

<FORM METHOD=POST ACTION="satan_open_action.pl">

<a name="open-or-create"><h3>Open existing or create new SATAN data base</h3>

<h3>
<INPUT TYPE="reset" VALUE=" Reset ">
<INPUT SIZE="28" NAME="_satan_dir" Value="$satan_data">
<INPUT TYPE="submit" VALUE=" Open or create ">
</h3>

</FORM>

EOF

if (@_results) {
	print CLIENT <<EOF;
	<h3>Existing data bases...</h3>
EOF
}

print CLIENT <<EOF;
<ul>
EOF
for (@_results) {
	if (-d "results/$_") {
		print CLIENT <<EOF;
		<li> <a href="satan_open_action.pl,$_,">$_</a>
EOF
	}
}

print CLIENT <<EOF;
</ul>

<hr>

<FORM METHOD=POST ACTION="satan_merge_action.pl">

<a name="merge"><h3>Merge with existing SATAN data base</h3>

<h3>
<INPUT TYPE="reset" VALUE=" Reset ">
<INPUT SIZE="28" NAME="_satan_dir" Value="">
<INPUT TYPE="submit" VALUE=" Merge ">
</h3>

</FORM>

EOF

if (@_results) {
	print CLIENT <<EOF;
	<h3>Existing data bases...</h3>
EOF
}

print CLIENT <<EOF;
<ul>
EOF

for (@_results) {
	if (-d "results/$_") {
		print CLIENT <<EOF;
		<li> <a href="satan_merge_action.pl,$_,">$_</a>
EOF
	}
}

print CLIENT <<EOF;
</ul>
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a>
</BODY>
</HTML>
EOF
