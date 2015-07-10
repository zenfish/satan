#
# Report subnets
#

# generate the tables for looking subnets/hosts in:
&make_subnet_info();
$_subnets = keys %all_subnets;

sub sort_ip {
    local($aip,$bip);
    for $ip (split(/\./,$a)) { $aip = $aip * 256 + $ip; }
    for $ip (split(/\./,$b)) { $bip = $bip * 256 + $ip; }
    return $aip <=> $bip;
}

print CLIENT <<EOF;
<HTML>
<HEAD>
<title> Host Tables - By Subnet  </title>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC=$HTML_ROOT/images/satan.gif> Host Tables - By Subnet </H1>
<hr>
<h3>$_subnets Subnets. Number of hosts per subnet (vulnerable/total). </h3>
<strong>Subnets with a red dot next to them have a vulnerable host contained within.</strong>
<ul>
EOF

# until the subnet is all looked at...
for $_net (sort sort_ip keys %all_subnets) {
    $dot = $subnet_severities{$_net} ? "red" : "black";
    print CLIENT <<EOF;
	    <dt><IMG SRC=$HTML_ROOT/dots/$dot\dot.gif ALT="$dot">
	    <a href="satan_results_subnet.pl,$_net,"> $_net </a> 
	    ($subnet_severities{$_net}/$subnet_count{$_net})
EOF
    }

print CLIENT <<EOF;
</ul>
<hr> <a href=$HTML_STARTPAGE> Back to the SATAN start page </a> |
<a href=analysis.pl> Back to SATAN Reporting and Analysis </a>
</BODY>
</HTML>
EOF
