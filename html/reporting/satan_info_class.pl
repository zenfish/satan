#
# Report services and host counts.
#
print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Host Tables - by Class of Service </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Host Tables - by Class of Service </H1>
<hr>
EOF

&make_service_info() ;

if (sizeof(*servers) > 0) {
    print CLIENT "<p> <h3> Number of server systems (vulnerable/total) </h3> <ul>\n";
    for (sort keys %servers) {
	# Mask possible blanks or slashes in service names.
	($_service = $_) =~ tr / \//?!/;
	$_dot = $server_severities{$_} ? "reddot" : "blackdot";
	$_alt = $server_severities{$_} ? "*" : "-";
	if ($server_counts{$_} > 0) {
	    print CLIENT <<EOF;
	    <dt><IMG SRC=$HTML_ROOT/dots/$_dot.gif ALT="$_alt"> 
	    <a href="satan_info_servers.pl,$_service,"> $_</a>
	    ($server_severities{$_}/$server_counts{$_}) 
EOF
#	} else {
#	    print CLIENT <<EOF;
#	    <dt><IMG SRC=$HTML_ROOT/dots/blackdot.gif ALT="-"> $_
#EOF
	}
    }
    print CLIENT "</ul>\n";
}

if (sizeof(*clients) > 0) {
    print CLIENT "<p> <h3> Number of client systems (vulnerable/total) </h3> <ul>\n";
    for (sort keys %clients) {
	# Mask possible blanks or slashes in service names.
	($_service = $_) =~ tr / \//?!/;
	$_dot = $client_severities{$_} ? "reddot" : "blackdot";
	$_alt = $client_severities{$_} ? "*" : "-";
	if ($client_counts{$_} > 0) {
	    print CLIENT <<EOF;
	    <dt><IMG SRC=$HTML_ROOT/dots/$_dot.gif ALT="$_alt"> 
	    <a href="satan_info_clients.pl,$_service,"> $_</a>
	    ($client_severities{$_}/$client_counts{$_})
EOF
#	} else {
#	    print CLIENT <<EOF;
#	    <dt><IMG SRC=$HTML_ROOT/dots/blackdot.gif ALT="-"> $_
#EOF
	}
    }
    print CLIENT "</ul>\n";
}

if (sizeof(*servers) > 0 || sizeof(*clients) > 0) {
    print CLIENT <<EOF;
	<strong>Note: hosts may appear in multiple categories. </strong>
	<HL>
	<strong>Service types with a red dot next to them have a vulnerable host contained within</strong>
EOF
} else {
    print CLIENT <<EOF;
	No service information found.
EOF
}

print CLIENT <<EOF
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
