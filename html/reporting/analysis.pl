print CLIENT <<EOF;
<HTML>
<HEAD>
<title>SATAN Reporting and Analysis</title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>

<H1><IMG SRC=$HTML_ROOT/images/satan.gif> SATAN Reporting and Analysis</H1>
<HR>
<h2> Table of contents</h2>
<HL>
<p>
<strong> Vulnerabilities </strong>
        <ul>
        <li> <a href=satan_results_danger.pl> By Approximate Danger Level </a>
        <li> <a href=satan_severity_types.pl> By Type of Vulnerability </a>
        <li> <a href=satan_severity_counts.pl> By Vulnerability Count </a>
        </ul>

<strong> Host Information </strong>
        <ul>
        <li> <a href=satan_info_class.pl> By Class of Service</a>
        <li> <a href=satan_info_OS.pl> By System Type</a>
	<li> <a href=satan_info_domain.pl> By Internet Domain</a>
        <li> <a href=satan_info_subnet.pl> By Subnet</a>
	<li> <a href=satan_info_name.pl> By Host Name</a>
        </ul>
<p>

<strong> Trust</strong>
        <ul>
        <li> <a href=satan_info_trusted.pl> Trusted Hosts</a>
        <li> <a href=satan_info_trusting.pl> Trusting Hosts</a>
	</ul>
<p>

<HL>
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a>
</BODY>
</HTML>
EOF
