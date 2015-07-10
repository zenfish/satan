#
#
#

print CLIENT <<EOF;
<HTML>
<HEAD>
<TITLE>Vulnerabilities - Danger Levels</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC="$HTML_ROOT/images/satan.gif" ALT="*"> Vulnerabilities - Danger Levels</H1>
<HR>
EOF
;

$_rs = $_us = $_ns = $_uw = $_ur = $_nw = $_nr = $_nfs = "";

# make some indices...
if (sizeof(*severity_levels) > 0) {
	for $_type (sort keys %severity_levels) {
	if ($_type eq "rs") {
		$_rs  = "<LI><A HREF=\"#root\">Root shell</A>"; }
	elsif ($_type eq "us") {
		$_us  = "<LI><A HREF=\"#user\">User shell</A>"; }
	elsif ($_type eq "ns") {
		$_ns  = "<LI><A HREF=\"#unprivileged\">Unprivileged shell</A>";}
	elsif ($_type eq "uw") {
		$_uw = "<LI><A HREF=\"#user file write\">User file write</A>"; }
	elsif ($_type eq "uw") {
		$_ur = "<LI><A HREF=\"#user file read\">User file read</A>"; }
	elsif ($_type eq "nr") {
		$_nr  = "<LI><A HREF=\"#unpriv file read\">Unprivileged file read</A>"; }
	elsif ($_type eq "nw") {
		$_nw  = "<LI><A HREF=\"#unpriv file write\">Unprivileged file write</A>"; }
	elsif ($_type eq "x") {
		$_nfs  = "<LI><A HREF=\"#NFS\">NFS</A>"; }
		}

print CLIENT <<EOF;
<h3>Table of contents</h3>
<ul>
$_rs
$_us
$_ns
$_uw
$_ur
$_nr
$_nw
$_nfs
</ul>
Note: hosts may appear in multiple categories. 
EOF
	}

&make_severity_info();

if (sizeof(*severity_levels) > 0) {
	for $_type (sort keys %severity_levels) {

		# how serious is it?
		if ($_type eq "rs") {
			print CLIENT <<EOF;
			<HR>
			<A NAME="root"><H3> Root shell Problems </H3></A>
			<HL>
			<UL>
EOF
			}
		elsif ($_type eq "us") {
			print CLIENT <<EOF;
			<HR>
			<A NAME="user"><H3> User shell Problems </H3></A>
			<HL>
			<UL>
EOF
			}
		elsif ($_type eq "ns") {
			print CLIENT <<EOF;
			<HR>
			<A NAME="unprivileged"> <H3> "nobody" shell Problems </H3></A>
			<HL>
			<UL>
EOF
			}
		elsif ($_type eq "ur") {
			print CLIENT <<EOF;
			<HR>
			<A NAME="user file read"> <H3> User reading file problems </H3></A>
			<HL>
			<UL>
EOF
			}
		elsif ($_type eq "uw") {
			print CLIENT <<EOF;
			<HR>
			<A NAME="user file write"> <H3> User writing file problems </H3></A>
			<HL>
			<UL>
EOF
			}
		elsif ($_type eq "nr") {
			print CLIENT <<EOF;
			<HR>
			<A NAME="unpriv file read"> <H3> "nobody" reading file problems </H3></A>
			<HL>
			<UL>
EOF
			}
		elsif ($_type eq "nw") {
			print CLIENT <<EOF;
			<HR>
			<A NAME="unpriv file write"> <H3> "nobody" writing file problems </H3></A>
			<HL>
			<UL>
EOF
			}
		elsif ($_type eq "x") {
			print CLIENT <<EOF;
			<HR>
			<A NAME="NFS"> <H3> NFS Problems </H3></A>
			<HL>
			<UL>
EOF
			}
		$_last_tmp = "";
		$_last_txt = "";
		# split all the targets into separate lines
		for $_tmp (sort keys %{$severity_levels{$_type}}) {
			for (sort split(/\n/, $severity_levels{$_type}{$_tmp})) {
				&satan_split($_);
				($_tutorial = $service_output) =~ tr / /_/;
				# just weed out the dups
				next if ($_last_tmp eq $_tmp && $text eq $_last_txt);
				$_last_tmp = $_tmp;
				$_last_txt = $text;
				print CLIENT <<EOF;
			<li> 
			<a href="satan_info_host.pl,$_tmp,">$_tmp</a> 
			<a href="$HTML_ROOT/tutorials/vulnerability/$_tutorial.html">($text)</a>
EOF
				}
			}
		print CLIENT <<EOF;
			</UL>
EOF
		}
	}
else {
	print CLIENT <<EOF;
	<P> No vulnerability information found.
EOF
	}

        print CLIENT <<EOF;
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
