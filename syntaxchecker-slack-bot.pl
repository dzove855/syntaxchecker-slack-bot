#!/usr/bin/env perl

# This bot is for fun, not code checked, Code using is shitty, the regex are note very well, but hey, it's working :p
# This bot is using $HOME/.$softname.token for the token definition
# This bot is using $HOME/.$softname.mandir for the man dir definition, do not forget final slash

use strict;
use warnings;

use Slack::RTM::Bot;
use String::Random;

use File::Basename;
use File::Slurp;

my ( $softname, $path, $suffix ) = fileparse( $0, qr{\.[^.]*$} );

my $token = read_file("$ENV{'HOME'}/.$softname.token");
chomp $token;

my $bot = Slack::RTM::Bot->new( token => $token);

sub syntax{
    my ($ref, $message) = @_;

    my $string_gen = String::Random->new;
    my $shell = {
        php     => 'php -l',
        sh      => 'shellcheck'
    };

    my $filename = '/tmp/shellbot.' . $ref . '.' . $string_gen->randregex('\d\d\d\d\d');
    open(my $fh, '>', $filename);
        print $fh "<?php \n" if $ref eq "php";
        print $fh "$message";
    close $fh;

    my $output = `$shell->{$ref} $filename`;

    unlink $filename;

    return $output;
};

sub man{
    my ($ref, $message) = @_;

    my $dir = read_file("$ENV{'HOME'}/.$softname.mandir");

    chomp $dir;
    
    my $output;

    my $filename = $message;
    $filename =~ s/^\s+|\s+$//g;
    $filename =~ s/.*\s+.*/_/g;

    if ($ref eq 'man') {

        $output = read_file($dir . $filename) if -f "$dir$filename";
        $output = "Type: #man: help" if ! -f "$dir$filename";

    } elsif ($ref eq 'manedit') {

        if ($message =~ m/.* -m .*/) {
            (my $filename) = ($message =~ m|(.+) -m.*|);
            $filename =~ s/^\s+|\s+$//g;
            $filename =~ s/.*\s+.*/_/g;

            $message =~ s/.* -m//;
            $message =~ s/^\s+|\s+$//g;

            open(my $fh, '>>', $dir . $filename);
                print $fh "$message";
                close $fh;

            $output = "Manpage succesfully saved.";
        } else {
            $output = "Type: #man: help";
        };

    } elsif ($ref eq 'mandel') {

        unlink $dir . $filename;

        $output = 'Manpage succesfully removed.';

    } elsif ($ref eq 'manlist') {

        opendir(DIR, $dir);
        my @dircontent = readdir(DIR);

        foreach my $file (@dircontent) {
            next if ($file =~ m/^.$/ or $file =~ m/^..$/);
            $output .= " $file";
        };
        closedir(DIR);

    };

    return $output;
};

$bot->on({
        text    => qr/.*/
    },
    sub {
        my ($response) = @_;

        my %matcher = (
            php         => \&syntax,
            sh          => \&syntax,
            manedit     => \&man,
            manlist     => \&man,
            man         => \&man,
            mandel      => \&man
        );

        # Check if $response matches
        # XXX: I should use a proper regex

        if (defined($response->{user}) and defined($response->{text}) and defined($response->{channel})) {

            my $answer;

            (my $ref) = ($response->{text} =~ m|#(.+):.*|);
            (my $message) = ($response->{text} =~ m|#.+:(.*)|);

            $answer = $matcher{$ref}($ref, $message) if defined $ref and defined $message and defined $matcher{$ref} ;

            $bot->say(
                channel => $response->{channel},
                text    => '@' . $response->{user} . ' ```' . $answer . '```'
            ) if length $answer;
        };

    }
);
 
$bot->start_RTM(sub {
    while(1) { sleep 10; }
});
