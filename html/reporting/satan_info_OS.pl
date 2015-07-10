#
# Report all operating system classes.  On the fly evaluate the number of
# hosts per class, per operating system version and related statistics.
#
print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Host Tables - by System Type </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Host Tables - by System Type </H1>
<hr>
<h3>Number of hosts per system type (vulnerable/total).</h3>
<ul>
EOF

&make_hosttype_info() ;

for (sort keys %systypes_by_class) {
	# Mask possible blanks in the system class names.
	($_class = $_) =~ tr / \//?!/;
	$sysclass_severities{$_class} = 0 
		unless defined($sysclass_severities{$_class});
	$_dot = $sysclass_severities{$_} ? "reddot" : "blackdot";
	$_alt = $sysclass_severities{$_} ? "*" : "-";
	print CLIENT <<EOF
	<dt><IMG SRC=$HTML_ROOT/dots/$_dot.gif ALT="$_alt"> 
	<a href="satan_info_OSclass.pl,$_class,"> $_</a>
	($sysclass_severities{$_}/$sysclass_counts{$_})
EOF
	unless /other/;
}
if (sizeof(*hosttype) > 0) {
	$_class = "other";
	$sysclass_severities{$_class} = 0 
		unless defined($sysclass_severities{$_class});
	$_dot = $sysclass_severities{$_class} ? "reddot" : "blackdot";
	$_alt = $sysclass_severities{$_class} ? "*" : "-";
	print CLIENT <<EOF;
	<dt><IMG SRC=$HTML_ROOT/dots/$_dot.gif ALT="$_alt">
	<a href="satan_info_OSclass.pl,other,"> Other/unknown</a>
	($sysclass_severities{$_class}/$sysclass_counts{$_class})
	</ul>
	<HL><strong>System types with a red dot next to them have a vulnerable host contained within.</strong>
EOF
} else {
	print CLIENT <<EOF;
	</ul>
	No system type information available.
EOF
}

print CLIENT <<EOF;
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
