#
# Find if these commands would all run with root privileges.
#

sub suser {
	local(@path) = @_;
	local($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks);

	while ($> != 0 && $#path >= $[) {
		if ((($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat(@path[0])) == 0) {
			return(0);
		} elsif ($uid != 0 || ($mode & 04000) == 0) {
			return(0);
		}
		shift @path;
	}
	return(1);
}

#
# Stand-alone mode
#
if ($running_under_satan == 0) {

	warn 'suser.pl running in stand-alone mode';

	die "usage $0 file\n" unless $#ARGV == 0;

	print &suser($ARGV[0]) ? "Root privileged\n" : "Unprivileged\n";
}

1;
