#
# miscellaneous perl functions that don't belong anywhere else
#

#
# Symbolic offsets for SATAN record fields.
#

$TARGET_FIELD = 0;
$SERVICE_FIELD = 1;
$STATUS_FIELD = 2;
$SEVERITY_FIELD = 3;
$TRUSTEE_FIELD = 4;
$TRUSTED_FIELD = 5;
$SERVICE_OUTPUT_FIELD = 6;
$TEXT_FIELD = 7;
$SATAN_FIELDS = 8;

# strip leading directory and optional suffix information.
sub basename {
    local($path, $suffix) = @_;

    $path =~ s:.*/::;
    if ($suffix) {
	$path =~ s/$suffix$//;
    }
    return $path;
}

# print to string 

sub satan_string{

    return "$target|$service|$status|$severity|$trustee|$trusted|$service_output|$text";
}

# print the output for the brain/optimizer
sub satan_print {

    print "$target|$service|$status|$severity|$trustee|$trusted|$service_output|$text\n";

}

# format the output for the brain/optimizer
sub satan_text {

    return "$target|$service|$status|$severity|$trustee|$trusted|$service_output|$text";

}

# breakup record into its constituent fields
sub satan_split {
    local ($line) = @_;

    return ((($target,$service,$status,$severity,$trustee,$trusted,$service_output,$text) = split(/\|/, $line)) != $SATAN_FIELDS);
}

# count the number of elements in an associative array.
sub sizeof {
    local(*which) = @_;
    local(@keywords);
 
    @keywords = keys %which;
    return($#keywords + 1);
}

#
# ensure that all paths in paths.pl file actually exist and are executable
sub check_paths {
local($caps, $command, $path, $null);

die "Can't open paths.pl\n" unless open(PATHS, "paths.pl");

while (<PATHS>) {
	($caps, $command) = split(/=/, $_);
	($null, $path, $null) = split(/\"/, $command);
	die "$path is *not* executable - necessary for SATAN to run\n"
		unless -x $path;
	}

close(PATHS);
}

1;
