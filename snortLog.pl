#!/usr/local/bin/perl -w
###################################################################
# author: Chad Brandt (chad@linux-bsd-central.com)
#
# This program can be used to view formatted snort alert messages
# which are easy to read
#
###################################################################

###################################################################
# Change the following variable to point to your snort alert log
###################################################################
$alertLog = "/var/log/snort/alert";

open (IN, "$alertLog") || die "unable to open alert file: $alertLog $!";
@alertFile = <IN>;
close (IN);

$argLength = @ARGV;

if ($argLength == 0){
    $searchDate = qx|date +%m/%d|;
    chomp($searchDate);

    print "\nNo Argument Passed, Using Date: $searchDate\n\n";
} else {
    $searchDate = $ARGV[0];
}


foreach(@alertFile){

    chomp($_);

    if ($_ !~ /^$searchDate/){next;}
    if ($_ =~ /ICMP/){next;}

    # extract date and time format: 04/02-18:56:25.123340
    $_ =~ /((\d+)\/(\d+))-((\d\d):(\d\d):(\d\d))/;
    $date = $1;
    $tm = $4;

    #extract protocol format: {TCP}
    $_ =~/{(\w+)}/;
    $proto = $1;

    #extract src and tgt addresses format: 65.29.19.186:40668 -> 205.174.16.50:80
    $_ =~ /((\d+).(\d+).(\d+).(\d+):(\d+)) -> ((\d+).(\d+).(\d+).(\d+):(\d+))/;
    $src = $1;
    $tgt = $7;

    #extract sid and description format: [1:882:4] description [**]
    $_ =~ /\[(\d+):(\d+):(\d)\]\s(.*) \[\*\*\]/;
    $sid = $2;
    $desc = $4;

    #print out the formatted values
    printf ("%-5s %-8s  %-4s %-20s -> %-20s %-40s %-6s\n",$date, $tm, $proto, $src, $tgt, $desc, $sid);

}
