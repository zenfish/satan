#
# Collect data and keep the user informed.
#

require "perl/config.pl";

#
# Make sure they specified a data file
if ($satan_data eq "") {
	print CLIENT <<EOF;
<HTML>
<HEAD>
<TITLE>Error - Missing input (no SATAN data file found)</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Error - Missing input </H1>
<hr>
No data directory was specified.
</BODY>
</HTML>
EOF
	die "\n";
	}

#
# Write the data...
&write_config_file($html_post_attributes);

print CLIENT <<EOF;
<HTML>
<HEAD>
<TITLE>SATAN Configuration Management</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> SATAN Configuration Management </H1>
<hr>
<B>Configuration file changed</B>
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a>
</BODY>
</HTML>
EOF
