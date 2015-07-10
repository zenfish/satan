#
# Display a FORM to select the primary target and to give the user a chance to
# override some defaults.
#
($_host) = split(/,/, $html_script_args);

#
# First figure out what radio buttons etc. should be "on". Note: the
# variables below are global. Perhaps we should hide in our own package
# name space.
#
@check_subnets = ();	$check_subnets[$attack_proximate_subnets] = "checked";
@check_level = ();	$check_level[$attack_level] = "checked";

#
# In case the primary target has not yet been set.
#
$primary_target = $THIS_HOST unless $primary_target;
$_host = $primary_target unless $_host;

print CLIENT <<EOF
<HTML>
<HEAD>
<TITLE>SATAN target selection</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>

<H1><IMG SRC=$HTML_ROOT/images/satan.gif> SATAN target selection</H1>

<hr>

<FORM METHOD=POST ACTION="satan_run_action.pl">

<h3> Primary target selection </h3>

Primary target host or network, e.g. <tt>$THIS_HOST</tt>:
<INPUT SIZE="48" NAME="primary_target" Value="$_host">

<P>

<DL compact>
<DT><DD><input type=radio name="attack_proximate_subnets" value="0" $check_subnets[0]>
	Scan the target host only.
<DT><DD><input type=radio name="attack_proximate_subnets" value="1" $check_subnets[1]>
	Scan all hosts in the primary (i.e. the target's) subnet.
</DL>

<HR>

<h3> Scanning level selection </h3>

Should SATAN do a light scan, a normal scan, or should it hit the
(primary) target(s) at full blast?

<P>

<DL compact>
<DT><DD><input type=radio name="attack_level" value="0" $check_level[0]>
	Light
<DT><DD><input type=radio name="attack_level" value="1" $check_level[1]>
	Normal (may be detected even with minimal logging)
<DT><DD><input type=radio name="attack_level" value="2" $check_level[2]> 
	Heavy (error messages may appear on systems consoles)
</DL>

<HR>

<INPUT TYPE="submit" VALUE=" Start the scan ">

</FORM>
</BODY>
</HTML>
EOF
