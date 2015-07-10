#
# Report all versions of the specified operating system class.
#
&make_hosttype_info();

($_class) = split(/,/, $html_script_args);
$_class =~ tr /?!/ \//;
print CLIENT <<EOF;
<HTML>
<HEAD>
<title> System type - $_class </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> System type - $_class </H1>
<hr>
<h3>Number of hosts per operating system version (vulnerable/total).</h3>
<ul>
EOF

for (sort split(/\n/, $systypes_by_class{$_class})) {
	# Mask possible blanks and slashes in the system type names.
	($_type = $_) =~ tr / \//?!/;
	$_dot = $systype_severities{$_} ? "reddot" : "blackdot";
	$_alt = $systype_severities{$_} ? "*" : "-";
	print CLIENT <<EOF;
	<dt><IMG SRC=$HTML_ROOT/dots/$_dot.gif ALT="$_alt"> 
	<a href="satan_info_OStype.pl,$_type,"> $_</a>
	($systype_severities{$_}/$systype_counts{$_})
EOF
}
print CLIENT <<EOF
</ul>
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
