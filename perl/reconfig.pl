#!/usr/local/bin/perl

#  Usage: reconfig [file]
#
#   This replaces the program paths (e.g. /bin/awk) in SATAN with an
# alternate path that is found in the file "file.paths".  It also finds
# perl5 (or at least tries!) and changes the path in all the stand-alone
# perl programs.
#

# all the HTML browsers we know about, IN ORDER OF PREFERENCE!
@all_www= ("netscape", "Mosaic", "xmosaic", "lynx");

#
#  Potential directories to find commands; first, find the user's path...
$PATH = $ENV{"PATH"};

# additional dirs; *COLON* separated!
$other_dirs="/usr/ccs/bin:/bin:/usr/bin:/usr/ucb:/usr/bsd:/usr/ucb/bin:/usr/sbin:/usr/etc:/usr/local/bin:/usr/bin/X11:/usr/X11/bin";

#
# split into a more reasonable format:
@all_dirs = split(/:/, $PATH . ":" . $other_dirs);

#
#  Target shell scripts in question:
@shell_scripts=("paths.pl", "rex.satan", "rsh.satan", "tftp.satan");
@perl5_src = <get_targets faux_fping *satan* html.pl>;

#
#  Target shell commands in question
@all_commands=("cc", "cat", "chmod", "cmp", "comm", "cp", "date", "diff",
	"egrep", "expr", "find", "grep", "ls", "mail", "mkdir", "mv", "rm",
	"sed", "sh", "sort", "tftp", "touch", "uniq", "uudecode", "ypcat",
	"strings", "finger", "ftp", "rpcinfo", "rusers", "showmount",
	"ypwhich", "nslookup", "xhost", "su", "awk", "sed", "test");

print "checking to make sure all the target(s) are here...\n";

for (@shell_scripts) {
	die "ERROR -- $_ not found!\n" unless -f $_;
	}

# find perl5!
print "Ok, trying to find perl5 now... hang on a bit...\n";
for $dir (@all_dirs) {
	# first, find where it might be; oftentimes you'll see perl,
	# perl4, perl5, etc. in the same dir
	while (<$dir/perl5* $dir/perl*>) {
		if (-x $_) {
			$perl_version=`($_ -v 2> /dev/null) |
				awk '/This is perl, version 5/ { print $NF }'`;
			if ($perl_version) {
				$PERL=$_;
				$pflag="1";
				last;
				}
			}
			last if $pflag;
		}
	last if $pflag;
	}

die "\nCan't find perl5!  Bailing out...\n" unless $PERL;
print "\nPerl5 is in $PERL\n";

for (@perl5_src) { $perl5_src .= "$_ "; }
print "\nchanging the perl source in: $perl5_src\n";
system "$PERL -pi -e \"s@/usr/local/bin/perl.*@$PERL@;\" $perl5_src";

# make sure things are executable...
system("chmod u+x $perl5_src");
 
# find the most preferred www viewer first.
for $www (@all_www) {
	for $dir (@all_dirs) {
		if (!$MOSAIC) {
			if (-x "$dir/$www") {
				$MOSAIC="$dir/$www";
				next;
				}
			}
		}
	}
if ($MOSAIC) {
	print "\nHTML/WWW Browser is $MOSAIC\n";
	$upper{"MOSAIC"} = $MOSAIC;
	}
else { print "Cannot find a web browser!  SATAN cannot be run except in CLI"; }

print "\nSo far so good...\nLooking for all the commands now...\n";

for $command (@all_commands) {
	$found="false";
	for $dir (@all_dirs) {
		# if find the command in one of the directories, print string
		if (-f "$dir/$command") {
			# this converts to upper case
			($upper = $command) =~ y/[a-z]/[A-Z]/;
			$found="true";
			$upper{$upper} = "$dir/$command";
			# print "found ($upper) $dir/$command\n";
			last;
			}
		}
	print "can't find $command\n" unless $found eq "true";
	}

print "\nOk, now doing substitutions on the shell scripts...\n";
for $shell (@shell_scripts) {
 	print "Changing paths in $shell...\n";
	die "Can't open $shell\n" unless open(SCRIPT, $shell);
	rename($shell, $shell . '.old');
	die "Can't open $shell\n" unless open(OUT, ">$shell");

	#
	#  Open up the script, search for lines beginning with
	# stuff like "TEST", "AWK", etc.  If the file ends in "pl",
	# assume it's a perl script and change it accordingly
	while (<SCRIPT>) {
		$found = 0;
		for $command (keys %upper) {
			if(/^\$?$command=/) {
				# shell script
				if ($shell !~ /.pl$/) {
					print OUT "$command=$upper{$command}\n";
					}
				# perl script
				else {
					print OUT "\$" . "$command=\"$upper{$command}\";\n";
					}
				$found = 1;
				}
			}
		print OUT $_ if !$found;
		}
	close(SCRIPT);
	close(OUT);
	# finally, make sure everything is back to executable status
	system ("chmod u+x $shell");
	}

# done...
