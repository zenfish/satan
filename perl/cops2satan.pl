#!/usr/local/bin/perl5
#
#  An experimental script that will Convert a COPS warning report
# into SATAN rules.  Take stdin or a filename.  Uses the function
# "satan_print" to emit SATAN rules.
#

require "perl/hostname.pl";
require "perl/misc.pl";

# we're the target... nothing remote here
$target = &hostname();

#
# default value for satan_print(); everything we report is "available"
$status = "a";

# most things only affect users on the machine
$trusted = "ANY@$target";

# most things will be blank here, at least on my first shot at this...
$service_ouput = "";

# ok, process everything now:
while (<>) {

	# chow down on blank lines
	if ($_ =~ /^\s*$/) { next; }

	# top three lines look like:
	#
	# ATTENTION
	# Security Report for...
	# from host ...
	if ($_ =~ /from host/) { $start_processing = 1; next; }
	if (!$start_processing) { next; }

	# get the service, if possible -- 
	# assumes all checks print out something like:
	# "**** foo.chk ****"
	# when the verbose flag is true
	if ($_ =~ /^\*\*\*\*/) {
		($service) = ($_ =~ /\*\*\*\* (\S+) /);
		next;
		}
	
	#  IMPORTANT - exception list!
	#
	#  Be very careful of regular expressions and other meta stuff...
	# ()'s, *'s, ?'s, /'s, etc. are all trouble.  Backquote if in doubt.
	#
	#  Sample list:
	#
	#  Hassled by mail warning?
	# next if (m@Warning!  /usr/spool/mail is _World_ writable!@);
	#
	#  Running an NIS-free machine but in an NIS environment?
	#  next if (/YG/);
	#  next if (/YP/);

	# if it doesn't start with "Warning!", then nuke the second
	# line; it's a multipart print
	next unless ($_ =~ /^Warning!/);
	
	#
	# START THE CHECKING
	#
	# level 0 checks -- the most serious
	#
	if ($_ =~ /A "+" entry in/) {
		$severity = "us";
		$trusted = "ANY@ANY";
		$trustee = "ANY@$target";
		$text = "+ in /etc/hosts.equiv file";
		}
		
	# Assume bugs are all bad -- some bugs are remote; need to
	# change this to recognize them...
	elsif (m@ould have a hole/bug@) {
		$severity = "rs";
		$trusted = "ANY@$target";
		$trustee = "root@$target";
		$text = "serious bug";
		}

	# kuang telling us we're in deep yoghurt, or something like that...
	elsif ($_ =~ /DO ANYTHING/) {
		$severity = "rs";
		$trusted = "ANY@$target";
		$trustee = "root@$target";
		$text = "kuang found a path to compromise root";
		}

	# writable password file really sucks:
	elsif ($_ =~ /\/etc\/passwd.*_World_/) {
		$severity = "rs";
		$trusted = "ANY@$target";
		$trustee = "root@$target";
		$text = "world-writable password file";
		}

	# this is easy root most of the time...
	elsif ($_ =~ /Directory.*is _World_ writable and in roots path!/) {
		$severity = "rs";
		$trusted = "ANY@$target";
		$trustee = "root@$target";
		$text = "world-writable file in root's path";
		}

	# level 1 checks:
	#
	elsif ($_ =~ /uudecode is suid!/) {
		$severity = "uw";	# cops should tell us *what* user, eh?
		$trusted = "ANY@$target";
		$trustee = "user@$target";
		$text = "uudecode is suid";
		}
	elsif ($_ =~ /rexd is enabled in/) {
		$severity = "us";
		$trusted = "ANY@ANY";
		$trustee = "user@$target";
		$text = "rexd is enabled";
		}
	elsif ($_ =~ /User.*mode/ && $_ !~ /is not a directory/) {
		$severity = "us";
		$trusted = "ANY@$target";
		$trustee = "user@$target";
		$text = "User home directory or startup file is writable";
		}
	elsif ($_ =~ /tftp is enabled on/) {
		$severity="nr";
		$trustee="nobody@$target";
		$trusted="ANY@ANY";
		$text="tftp is enabled";
		$text = "tftp is enabled on";
		&satan_print();
		# (OUTPUT TWICE)
		$severity="nw";
		$trustee="nobody@$target";
		$trusted="ANY@ANY";
		$text = "tftp is enabled on";
		}
	elsif ($_ =~ /uudecode is enabled in/) {
		$severity = "nw";
		$trustee="nobody@$target";
		$trusted="ANY@ANY";
		$text = "uudecode is enabled in/";
		}
	# unclear what ramifications are...
	# /Password file, line.*is blank/
	# /Password file, line.*nonnumeric user id:/
	elsif ($_ =~ /(in cron_file) is World writable!/) {
		$severity = "root";
		$trusted = "ANY@$target";
		$trustee = "root@$target";
		$status = "q"; # who knows if it really matters?
		$text = "File in cron_file is world writable";
		}
	elsif ($_ =~ /File.*(inside root executed file) is _World_ writable!/) {
		$severity = "root";
		$trusted = "ANY@$target";
		$trustee = "root@$target";
		$status = "q"; # who knows if it really matters?
		$text = "File inside root executed file is _World_ writable!";
		}
	elsif ($_ =~ /File.*(in .*) is _World_ writable!/) {
		$severity = "user";
		$trusted = "ANY@$target";
		$trustee = "root@$target";
		$status = "q"; # who knows if it really matters?
		$text = "File inside important command is _World_ writable!";
		}
	# this assumes anon-ftp is actually on!
	elsif ($_ =~ /ftp's home directory should not be/) {
		$severity = "nw";
		$trusted = "ANY@ANY";
		$trustee = "nobody@$target";
		$text = "ftp's home directory is /";
		&satan_print();
		# (OUTPUT TWICE)
		$severity = "nr";
		$trusted = "ANY@ANY";
		$trustee = "nobody@$target";
		$text = "ftp's home directory is /";
		}
	# this gives away password file; what do we do?
	# elsif (/and.*ass.*are the same/)
	# $text = "system password file and ~ftp/etc/passwd are the same";

	# unclear of ramifications; could be very bad or ok
	# elsif (/should be mode 555/)

	# rhosts entry in ftp...
	# elsif (/should be be empty/)
	
	#  PRINT *SOMETHING* if can't find anything... give it no
	# severity so it won't get counted...
	else  {
		$severity = "";
		$trusted = "";
		$trustee = "";
		$status = "a";
		($text) = /Warning!\s+(.+)$/;
		# $text = "Unknown warning!";
		}


	&satan_print();
	}

