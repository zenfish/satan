#
# Open a data base and keep the user informed.
#
($_directory) = split(/,/, $html_script_args);

#
# Make sure they specified a directory at all.
#
$_directory = $_satan_dir if $_directory eq "";

if ($_directory eq "") {
	print CLIENT <<EOF;
<HTML>
<HEAD>
<TITLE>Error - Missing input </TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Error - Missing input </H1>
<hr>
No data base name was specified.
</BODY>
</HTML>
EOF
	die "\n";
}

#
# Create data base when it does not exist
#
$satan_data = $_directory;
&find_satan_data();

#
# Read the data base, after resetting the in-core data structures.
#
print CLIENT <<EOF;
<HTML>
<HEAD>
<TITLE>SATAN Data Management</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> SATAN Data Management</H1>
<HR>
EOF

if (-s "$facts_file") {
	print CLIENT <<EOF;
<strong>merging data from <i> $_directory. </i> This may take some time. <p>
EOF
}

&merge_satan_data();

print CLIENT <<EOF;
<strong>Data base selection completed successfully.</strong>
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a>
| <a href=../reporting/analysis.pl>Continue with report and analysis</a>
</BODY>
</HTML>
EOF
