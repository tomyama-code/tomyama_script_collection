#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Runner;

&tests::Runner::TestPreProc( $0, @ARGV );
$ENV{TEST_TARGET_CMD} = 'c';

system( "prove -lv tests/$ENV{TEST_TARGET_CMD}.t" );

&tests::Runner::TestPostProc( $ENV{TEST_TARGET_CMD} );
