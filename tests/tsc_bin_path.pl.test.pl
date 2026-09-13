#!/usr/bin/env perl

use strict;                         # first released with perl 5
use warnings;                       # first released with perl v5.6.0

use FindBin;                        # first released with perl 5.00307
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Runner;

#&tests::Runner::TestPreProc(
#    '-ignore_re,/prove,-ignore_re,^tests/',
#    $0, @ARGV
#);
tests::Runner::TestPreProc( $0, @ARGV );

my $ret = system( "prove -lv tests/$ENV{TEST_TARGET_CMD}.t" );
my $exit_status = $ret >> 8;

tests::Runner::TestPostProc( $ENV{TEST_TARGET_CMD} );

exit $exit_status
