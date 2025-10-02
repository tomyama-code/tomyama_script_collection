#!/usr/bin/perl -w

use strict;
use warnings 'all';
use File::Basename ;

my @args = @ARGV;

my $apppath = dirname( $0 );
my $targcmd = "$apppath/../mark";

my $exit_status = -1;
if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    # Devel::Cover をサイレントにする
    $ENV{DEVEL_COVER_OPTIONS} = "-silent,1";

    # Devel::Cover を有効にした上で fill を実行
    $exit_status = system( $^X, "-MDevel::Cover", "$targcmd", @args );
}else{
    $exit_status = system( "$targcmd", @args );
}
# ./fill の exit code をそのまま返す
exit( $exit_status >> 8 );
