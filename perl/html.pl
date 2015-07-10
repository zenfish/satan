#!/usr/local/bin/perl5
#
# version 1, Thu Mar 23 21:53:31 1995, last mod by wietse
#

#
# Run an off-the-shelf HTML client against a dedicated HTML server.  The
# server executes PERL files that are specified in HTML requests.
#
# Authentication is magic-cookie style via the file system.  This should
# be good enough: the client-server conversation never goes over the
# network so the magic cookie cannot be stolen by a network sniffer.
# 
# Values in POST attribute-value lists are assigned to the corresponding
# global PERL variables.  See &process_html_request() for details.
#

sub html {
	local($helper, $wd, $host);

	#
	# Start the HTML server and generate the initial cookie for
	# client-server authentication.
	#
	$running_from_html = 1;
	chmod 0700, <~/.mosaic*>;	# Yuck!
	chmod 0700, <~/.netsca*>;	# Yuck!
	chmod 0700, <~/.MCOM*>;		# Yuck!
	&start_html_server();
	&make_password_seed();

	#
	# These strings are used in, among others, PERL-to-HTML scripts.
	#
	$wd = `pwd`;
	chop $wd;
	$html_root = "$wd/html";
	$start_page = "satan.html";
	$THIS_HOST = &getfqdn(&hostname());
	die "Can't find my own hostname: set \$dont_use_nslookup in $SATAN_CF\n"
	    unless $THIS_HOST;
	$HTML_ROOT = "file://localhost$html_root";
	$HTML_SERVER = "http://$THIS_HOST:$html_port/$html_password/$html_root";
	$HTML_STARTPAGE = "$HTML_ROOT/$start_page";

	#
	# Some obscurity. The real security comes from magic cookies.
	#
	$html_client_addresses = find_all_addresses($THIS_HOST) ||
		die "Unable to find all my network addresses\n";

	for (<$html_root/*.pl>) {
	    s/\.pl$//;
	    unlink "$_.html";
	    open(HTML, ">$_.html")
		    || die "cannot write $_.html: $!\n";
	    select HTML;
	    do "$_.pl";
	    close HTML;
	    select STDOUT;
	    die $@ if $@;
	}

	#
	# Fork off the HTML client, and fork off a server process that
	# handles requests from that client. The parent process waits
	# until the client exits and terminates the server.
	#
	print "Starting $MOSAIC...\n" if $debug;

	if (($client = fork()) == 0) {
		foreach (keys %ENV) {
			delete $ENV{$_} if (/proxy/i && !/no_proxy/i);
		}
		exec($MOSAIC, "$HTML_STARTPAGE") 
			|| die "cannot exec $MOSAIC: $!";
	} 
	if (($server = fork()) == 0) {
		if (($helper = fork()) == 0) {
			alarm 3600;
			&patience();
		}
		&init_satan_data();
		&read_satan_data() unless defined($opt_i);
		kill 'TERM',$helper;
		$SIG{'PIPE'} = 'IGNORE';
		for (;;) {
			accept(CLIENT, SOCK) || die "accept: $!";
			select((select(CLIENT), $| = 1)[0]);
			&process_html_request();
			close(CLIENT);
		}
	}

	#
	# Wait until the client terminates, then terminate the server.
	#
	close(SOCK);
	waitpid($client, 0);
	kill('TERM', $server);
	exit;
}

#
# Compute a hard to predict number for client-server authentication. Exploit
# UNIX parallelism to improve unpredictability. We use MD5 only to compress
# the result.
#
sub make_password_seed {
	local($command);

	die "Cannot find $MD5. Did you run a \"reconfig\" and \"make\"?\n"
		unless -x "$MD5";
	$command = "ps axl&ps -el&netstat -na&netstat -s&ls -lLRt /dev*&w";
	open(SEED, "($command) 2>/dev/null | $MD5 |")
		|| die "cannot run password command: $!";
	($html_password = <SEED>) || die "password computation failed: $!";
	close(SEED);
	chop($html_password);
}

#
# Set up a listener on an arbitrary port. There is no good reason to
# listen on a well-known port number.
#
sub start_html_server {
	local($sockaddr, $proto, $junk);

	$sockaddr = 'S n a4 x8';
	($junk, $junk, $proto) = getprotobyname('tcp');
	socket(SOCK, &AF_INET, &SOCK_STREAM, $proto) || die "socket: $!";
	listen(SOCK, 1) || die "listen: $!";
	($junk, $html_port) = unpack($sockaddr, getsockname(SOCK));
}

#
# Process one client request.  We expect the client to send stuff that
# begins with:
#
#	command /password/perl_script junk
#
# Where perl_script is the name of a perl file that is executed via
# do "perl_script";
#
# In case of a POST command the values in the client's attribute-value
# list are assigned to the corresponding global PERL variables.
#
sub process_html_request {
	local($request, $command, $script, $magic, $url, $peer);
	local(%args);

	#
	# Parse the command and URL. Update the default file prefix.
	#
	$request = <CLIENT>;
	print $request if $debug;
	($command, $url) = split(/\s+/, $request);
	if ($command eq "" || $command eq "QUIT") {
		return;
	}

	($junk, $magic, $script) = split(/\//, $url, 3);
	($script, $html_script_args) = split(',', $script, 2);
	($HTML_CWD = "file:$script") =~ s/\/[^\/]*$//;

	#
	# Make sure they gave us the right magic number.
	#
	if ($magic ne $html_password) {
		&bad_html_magic($request);
		return;
	}

	#
	# Assume the password has leaked out when the following happens.
	#
	$peer = &get_peer_addr(CLIENT);
	die "SATAN password from unauthorized client: $peer\n"
		unless is_member_of($peer, $html_client_addresses);
	die "Illegal URL: $url received from: $peer\n" 
		if index($script, "..") >= $[
		|| index($script, "$html_root/") != $[
		|| $script !~ /\.pl$/;

	#
	# Warn them when the browser leaks parent URLs to web servers.
	#
	while (<CLIENT>) {
		if (!$cookie_leak_warning && /$html_password/) {
			&cookie_leak_warning();
			return;
		}
		last if (/^\s+$/);
	}

	if ($command eq "GET") {
		perl_html_script($script);
	} elsif ($command eq "POST") {

		#
		# Process the attribute-value list.
		#
		if ($_ = <CLIENT>) {
			s/\s+$//;
			s/^/\n/;
			s/&/\n/g;
			$html_post_attributes = '';
			$* = 1;
			for (split(/(%[0-9][0-9A-Z])/, $_)) {
				$html_post_attributes .= (/%([0-9][0-9A-Z])/) ? 
					pack('c',hex($1)) : $_;
			}
			%args = ('_junk_', split(/\n([^=]+)=/, $html_post_attributes));
			delete $args{'_junk_'};
			for (keys %args) {
				print "\$$_ = $args{$_}\n" if $debug;
				${$_} = $args{$_};
			}
			perl_html_script($script);
		} else {
			&bad_html_form($script);
		}
	} else {
		&bad_html_command($request);
	}
}


#
# Map IP to string.
#
sub inet_ntoa {
	local($ip) = @_;
	local($a, $b, $c, $d);

	($a, $b, $c, $d) = unpack('C4', $ip);
	return "$a.$b.$c.$d";
}

#
# Look up peer address and translate to string form.
#
sub get_peer_addr {
	local($peer) = @_;
	local($junk, $inet);

	($junk, $junk, $inet) = unpack('S n a4', getpeername($peer));
	return &inet_ntoa($inet);
}

#
# Wrong magic number.
#
sub bad_html_magic {
	local($request) = @_;
	local($peer);

	$peer = &get_peer_addr(CLIENT);
	print STDERR "bad request from $peer: $request\n";

        print CLIENT <<EOF
<HTML>
<HEAD>
<TITLE>Bad client authentication code</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1>Bad client authentication code</H1>
The command: <TT>$request</TT> was not properly authenticated.
</BODY>
</HTML>
EOF
}

#
# Unexpected HTML command.
#
sub bad_html_command {
	local($request) = @_;

	print CLIENT <<EOF
<HTML>
<HEAD>
<TITLE>Unknown command</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1>Unknown command</H1>
The command <TT>$request<TT> was not recognized.
</BODY>
</HTML>
EOF
}

#
# Execute PERL script with extreme prejudice.
#
sub perl_html_script {
	local($script) = @_;

	if (! -e $script) {
		print CLIENT <<EOF
<HTML>
<HEAD>
<TITLE>File not found</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1>File not found</H1>
The file <TT>$script</TT> does not exist or is not accessible.
</BODY>
</HTML>
EOF
;		return;
	}
	do $script;
	if ($@ && ($@ ne "\n")) {
		print CLIENT <<EOF
<HTML>
<HEAD>
<TITLE>Command failed</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1>Command failed</H1>
$@
</BODY>
</HTML>
EOF
	}
}

#
# Missing attribute list
#
sub bad_html_form {
	local($script) = @_;

	print CLIENT <<EOF
<HTML>
<HEAD>
<TITLE>No attribute list</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1>No attribute list</H1>

No attribute list was found.
</BODY>
</HTML>
EOF
}

#
# Scaffolding for stand-alone testing.
#
if ($running_under_satan == 1) {

	require 'perl/socket.pl';
	require 'config/paths.pl';
	require 'perl/hostname.pl';
	require 'perl/getfqdn.pl';
	require 'config/satan.cf';

} else {
	$running_under_satan = 1;

	require 'perl/socket.pl';
	require 'config/paths.pl';
	require 'perl/hostname.pl';
	require 'perl/getfqdn.pl';
	require 'config/satan.cf';

	&html();
}

#
# Give them something to read while the server is initializing.
#
sub patience {
	for (;;) {
		accept(CLIENT, SOCK) || die "accept: $!";
		<CLIENT>;
		print CLIENT <<EOF
<HTML>
<HEAD>
<TITLE>Initialization in progress</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1>Initialization in progress</H1>
SATAN is initializing, please try again later.
</BODY>
</HTML>
EOF
;
		close(CLIENT);
	}
}

# Look up all IP addresses listed for this host name, so that we can
# filter out requests from non-local clients. Doing so offers no real
# security, because network address information can be subverted.
# 
# All client-server communication security comes from the magic cookies
# that are generated at program startup time. Client address filtering
# adds an additional barrier in case the cookie somehow leaks out.

sub find_all_addresses {
	local($host) = @_;
	local($junk, $result);

	($junk, $junk, $junk, $junk, @all_addresses) = gethostbyname($host);
	for (@all_addresses) { $result .= &inet_ntoa($_) . " "; }
	return $result;
}

sub is_member_of {
	local($elem, $list) = @_;

	for (split(/\s+/, $list)) { return 1 if ($elem eq $_); }
	return 0;
}

sub cookie_leak_warning {
	print CLIENT <<EOF;
<HTML>
<HEAD>
<TITLE>Warning - SATAN Password Disclosure</TITLE>
<LINK REV="made" HREF="mailto:satan\@fish.com">
</HEAD>
<BODY>
<H1><IMG SRC="$HTML_ROOT/images/satan.gif" ALT="[SATAN Image]">
Warning - SATAN Password Disclosure</H1>

<HR>

<H3> 

Your Hypertext viewer may reveal confidential information when you
contact remote WWW servers from within SATAN.

<p>

For this reason, SATAN advises you to not contact other WWW servers
from within SATAN.

<p>

For more information, see <a
href="$HTML_ROOT/tutorials/vulnerability/SATAN_password_disclosure.html">the
SATAN vulnerability tutorial</a>.

<p>

This message will appear only once per SATAN session. 

<p>

In order to proceed, send a <i>reload</i> command (Ctrl-R with Lynx),
or go back to the previous screen and select the same link or button
again.

</H3>

</BODY>
</HTML>
EOF
	$cookie_leak_warning = 1;
}

1;
