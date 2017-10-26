#!/usr/bin/env perl

# This bot is for fun, not code checked, Code using is shitty, the regex are note very well, but hey, it's working :p

use strict;
use warnings;

use Slack::RTM::Bot;
use String::Random;

use File::Basename;
use File::Slurp;

my ( $softname, $path, $suffix ) = fileparse( $0, qr{\.[^.]*$} );

my $string_gen = String::Random->new;

my $token = read_file("$ENV{'HOME'}/.$softname");
chomp $token;

my $bot = Slack::RTM::Bot->new( token => $token);

$bot->on({
        text    => qr/.*/
    },
    sub {
        my ($response) = @_;
        
        # Check if $response matches
        # XXX: I should use a proper regex
	if ($response->{text} =~ m/.*#sh:/ or $response->{text} =~ m/.*#php:/ ){
           
            # Get Binary
            (my $shell) = ($response->{text} =~ m|.*#(.+):.*|);

            # reparse text to remove binary declaration and last ``` if it is a snippet
            # XXX: Should use propper regex
            my $parsedresponse = $response->{text};
            $parsedresponse =~ s/.*#$shell:// ;   
            $parsedresponse =~ s/```$//;

            # Hardcore coding
            my $filename = '/tmp/shellbot.' . $shell . '.' . $string_gen->randregex('\d\d\d\d\d');
            open(my $fh, '>', $filename);
                print $fh "<?php \n" if $shell eq "php";
                print $fh "$parsedresponse";
            close $fh;

            my $output;

            if ($shell eq "sh") {

	        $output = `shellcheck $filename`;

            } elsif ($shell eq "php") {
 
                $output = `php -l $filename`;

            }

            unlink($filename);

            $bot->say(
                channel => $response->{channel},
        	text    => '@' . $response->{user} . ' ```' . $output . '```'
    	    );

	};

    }
);
 
$bot->start_RTM(sub {
    while(1) { sleep 10; }
});
