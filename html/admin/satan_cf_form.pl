#
# Display a FORM to select default config options to give the user
# control over the knobs and dials

#
# First figure out what radio buttons etc. should be "on". Note: the
# variables below are global. Perhaps we should hide in our own package
# name space.
#
@cf_attack_level = ();	$cf_attack_level[$attack_level] = "checked";
@cf_timeout = ();	$cf_timeout[$timeout] = "checked";
@cf_sub_zero = ();	$cf_sub_zero[$sub_zero_proximity] = "checked";
@cf_attack_proximate = ();
	$cf_attack_proximate[$attack_proximate_subnets] = "checked";
@cf_dont_nslookup = ();	$cf_dont_nslookup[$dont_use_nslookup] = "checked";
@cf_dont_ping = ();	$cf_dont_ping[$dont_use_ping] = "checked";
@cf_untrusted = ();	$cf_untrusted[$untrusted_host] = "checked";

print CLIENT <<EOF
<HTML>
<HEAD>
<TITLE>SATAN Configuration Management</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>

<IMG SRC=$HTML_ROOT/images/satan.gif>
<H1>SATAN Configuration Management</H1>
<HR>

<FORM METHOD=POST ACTION=satan_cf_action.pl>

<H2>Scanning levels and timeouts</H2>

<STRONG>What directory should I store the data in?</STRONG>
<DL compact>
<DT><DD><INPUT SIZE=25 NAME=satan_data VALUE=$satan_data>
Satan data directory
</DL>
<P>

<STRONG>What probe level should I use?</STRONG>
<DL compact>
<DT><DD><INPUT TYPE="radio" NAME=attack_level VALUE=0 $cf_attack_level[0]>
Light
<DT><DD><INPUT TYPE="radio" NAME=attack_level VALUE=1 $cf_attack_level[1]>
Normal
<DT><DD><INPUT TYPE="radio" NAME=attack_level VALUE=2 $cf_attack_level[2]>
Heavy
</DL>

<P>
<STRONG>What timeout values should I use?</STRONG>
<DL compact>
<DT><DD><INPUT SIZE=3 NAME=long_timeout VALUE=$long_timeout> Slow
<DT><DD><INPUT SIZE=3 NAME=med_timeout VALUE=$med_timeout> Medium
<DT><DD><INPUT SIZE=3 NAME=short_timeout VALUE=$short_timeout> Fast
</DL>

<P>
<STRONG>What signal should I send to kill a tool process when it times out?</STRONG>
<DL compact>
<DT><DD><INPUT SIZE=3 NAME=timeout_kill VALUE=$timeout_kill>Kill signal
</DL>

<P>
<STRONG>How far out from the original target should I probe?</STRONG>
(Under no circumstances should this be higher than "2" unless you're
POSITIVE you know what you're doing!)
<DL compact>
<DT><DD><INPUT SIZE=3 NAME=max_proximity_level VALUE=$max_proximity_level>
Maximal proximity
</DL>

<P>
<STRONG>As I move out to less proximate hosts, how much should I drop
the probe level?</STRONG>
<DL compact>
<DT><DD><INPUT SIZE=3 NAME=proximity_descent VALUE=$proximity_descent>
Proximity descent
</DL>

<P>
<STRONG>When I go below 0 probe level, should I:</STRONG>
<DL compact>
<DT><DD><INPUT TYPE="radio" NAME=sub_zero_proximity VALUE=0 $cf_sub_zero[0]>Stop
<DT><DD><INPUT TYPE="radio" NAME=sub_zero_proximity VALUE=1 $cf_sub_zero[1]>Go on
</DL>

<P>
<STRONG>Should I do subnet expansion; that is, should I probe just the
target or its entire subnet?</STRONG>
<DL compact>
<DT><DD><INPUT TYPE="radio" NAME=attack_proximate_subnets VALUE=0
	$cf_attack_proximate[0]>Just the target
<DT><DD><INPUT TYPE="radio" NAME=attack_proximate_subnets VALUE=1
	$cf_attack_proximate[1]>The entire subnet
</DL>

<P>
<STRONG>Does $THIS_HOST appear in <i>rhosts, hosts.equiv</i> or
<i>NFS exports</i> files of hosts being probed?
</STRONG>

<DL compact>
<DT><DD><INPUT TYPE="radio" NAME=untrusted_host VALUE=0 $cf_untrusted[0]>
You are running SATAN from a possibly trusted host
<DT><DD><INPUT TYPE="radio" NAME=untrusted_host VALUE=1 $cf_untrusted[1]>
You are running SATAN from an untrusted host
</DL>

<HR>

<h2>Patterns specifying hosts to limit the probe to</h2>

If you only want to probe hosts within a specific domain, you could use,
for example:
<PRE>
	podunk.edu
</PRE>
<p>
If you only want to probe sites on a particular subnet, you could use,
for example:
<PRE>
	192.9.9
</PRE>
<p>
<INPUT SIZE=48 NAME=only_attack_these VALUE="$only_attack_these">
<p>
You can specify multiple shell-like patterns, separated by whitespace
or commas, and you may mix networks and domains. A host will be
scanned when it matches <i>any</i> pattern: either a network number prefix
or an internet domain suffix.

<hr>

<h2>Patterns specifying hosts to NOT probe</h2>

If you don't want to probe any military or governmental sites, you could use:
<PRE>
	mil, gov
</PRE>
<p>
<INPUT SIZE=48 NAME=dont_attack_these VALUE="$dont_attack_these">
<p>
You can specify multiple shell-like patterns, separated by whitespace
or commas, and you may mix networks and domains. A host will be
skipped when it matches <i>any</i> pattern: either a network number prefix
or an internet domain suffix.

<hr>

<H2>Workarounds for broken DNS, ICMP etc.</H2>

<DL compact>
<DT><DD><INPUT TYPE="radio" NAME="dont_use_nslookup" VALUE="0" $cf_dont_nslookup[0]>
Use <i>nslookup</i> to look up fully-qualified (<i>host.domain</i>) host names
<DT><DD><INPUT TYPE="radio" NAME="dont_use_nslookup" VALUE="1" $cf_dont_nslookup[1]>
Don't use <i>nslookup</i>: DNS is unavailable.
</DL>

<DL compact>
<DT><DD><INPUT TYPE="radio" NAME="dont_use_ping" VALUE="0" $cf_dont_ping[0]>
Ping hosts to see if they are alive (skip non-responding hosts).
<DT><DD><INPUT TYPE="radio" NAME="dont_use_ping" VALUE="1" $cf_dont_ping[1]>
Don't ping hosts: ICMP does not work.
</DL>

<HR>
<INPUT TYPE="submit" VALUE="Change the configuration file">
</FORM>
</BODY>
</HTML>
EOF
