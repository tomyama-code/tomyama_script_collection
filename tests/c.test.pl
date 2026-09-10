#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;            # first released with perl 5.00307
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Runner;

tests::Runner::TestPreProc( $0, @ARGV );

my $ret = system( "prove -lv tests/$ENV{TEST_TARGET_CMD}.t" );
my $exit_status = $ret >> 8;

tests::Runner::TestPostProc( $ENV{TEST_TARGET_CMD} );

#print( qq{\$exit_status=$exit_status\n} );
#$exit_status;
