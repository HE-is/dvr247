#!/usr/bin/perl -w
# dvr247.pl - Caleb
# Used to constantly record a "screencast" in a buffer, which you can hit a
# desired key to save the last n seconds 
# YES, this is uber messy, with many mistakes and ineficiencies
# I am continuing to try to develop it to a stable point.
# There are many ways I have thought about re-writing this script that would be
# MUCH more efficient and organized, but I r lazeh. =P
# Hopefully, this might influence you on moving to linux for League ^_~
# I doubt it as this may not even work on your linux system... I have a weird 
# setup with fish...

use strict;
use warnings;
use IO::Pty::Easy;
use IO::Handle;
use IO::Pty;
use POSIX qw(strftime);

##########################
# Configuration          #
##########################

# To find the key codes, use 'xinput test <your keyboard id>'
# 'xinput list' to find your keyboard; this script should find it automatically

my $savecutkey = 82; # -numlock minus- (on my keyboard)
my $exitkey = 63; # -numlock asterisk- (on my keyboard)
my $length = 0;
my $sn = "";
my $vidstart = 0;
my $duration = 0;
my $data = "";
my $saveduration = 30; # Desired video clip/cut duration
my $screencap = "tmp_screencap247.mp4"; # Video buffer name
my $savename = "scrn-cap_"; # Video clip/cut name; date will be appended to this
my $date = strftime "%a_%b_%e_%H:%M:%S_%Y", localtime; # Date config
$date =~ tr/ //ds;

##########################
# End Configuration      #
##########################

# X11 display.
$ENV{DISPLAY} ||= ":0.0";

if (system("which xinput > /dev/null") != 0) {
	print "You require the `xinput` command\n";
	exit(1);
}

my @inputs = `xinput list`;

my $id;
foreach my $line (@inputs) {
	$line =~ s/^[\s\t]+//g;
	$line =~ s/[\s\t]+$//g;
	$line =~ s/[\x0D\x0A]+//g;
	next unless length $line;
	if ($line =~ /Translated/i) { # Change "Translated" to match your keyboard
		($id) = ($line =~ /id=(\d+)/)[0]; # from 'xinput list'
	}#(keyboard id changes from time-to-time. So this will find it with regex!)
}
if (!defined $id) {
	print "Failed to find keyboard ID from `xinput list`!\n";
	exit(1);
}


# Begin watching. Make a pseudo TTY for this so xinput believes we're a shell.
my $tty = IO::Pty::Easy->new;
print "Watching `xinput test $id` for save or quit key\n";
$tty->spawn("xinput test $id");

sub cap()
{
	$| = 1; # Set unbuffered output.
	open( my $scrncap, "| ffmpeg -y -f x11grab -s 1920x1080 -r 25 -i \$DISPLAY -f pulse -i alsa_output.pci-0000_00_1b.0.analog-stereo.monitor -c:v libx264 -b:v 400k -bufsize 2000k -s 1280x720 $screencap > /dev/null 2>&1 &" ) or die "cannot start mp3 player: $!";
	print "\nBuffer recording...\n";
	if($vidstart eq 0){
		$vidstart = time();
	}
	OUTERLOOP: while ($tty->is_active) {
		$data = $tty->read();
		my @lines = split(/\n/, $data);
		foreach my $line (@lines) {
			# Key event?
			chomp $line;
			if ($line =~ /$exitkey/){
				$tty->close;
				system("pkill ffmpeg");
				sleep(1);
				exit(0);
			}
			if ($line =~ /$savecutkey/){
				$length = time() - $vidstart;
				if ($length > $saveduration){
					close $scrncap;
					print "...buffer stopped.\n\n";
					last OUTERLOOP;
				}
			}
		}	
	}
}

sub save(){
	print "\nSaving $saveduration second cut...\n";
	system("pkill ffmpeg");
	sleep(1);
	# Get buffer video duration
	$duration = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $screencap`;
	if ($duration =~ /(\d+)\./){
		$duration = $1; 
	}
	$duration = $duration - $saveduration;
	$date = strftime "%a_%b_%e_%H:%M:%S_%Y", localtime;
	$date =~ tr/ //ds;
	$sn = $savename . $date . ".mp4";
	system("ffmpeg -i $screencap -ss $duration -t $saveduration -vcodec copy -acodec copy $sn > /dev/null 2>&1");
	system("rm", "$screencap");
	$vidstart = 0;
	print "...saved $sn.\n\n";
	return;
}

while()
{
	cap();
	save();
}

