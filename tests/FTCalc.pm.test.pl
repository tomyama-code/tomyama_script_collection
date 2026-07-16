#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin;            # first released with perl 5.00307
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Runner;

&tests::Runner::TestPreProc( $0, @ARGV );

system("prove -lv tests/$ENV{TEST_TARGET_MDL}.t");

&tests::Runner::TestPostProc( $ENV{TEST_TARGET_MDL} );
