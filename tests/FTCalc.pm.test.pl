#!/usr/bin/perl -w

use strict;
use warnings;

## Test::More was first released with perl v5.6.2
use Test::More;     # subtest()

#use lib '.';
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Command;

&tests::Command::TestPreProc( $0, @ARGV );
if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    $ENV{PERL5OPT} = '-MDevel::Cover=-ignore,/prove,-ignore,^c$,-ignore,\.t$';
    #print( qq{\$ENV{PERL5OPT}="$ENV{PERL5OPT}"\n} );
}

system("prove -lv tests/$ENV{TEST_TARGET_MDL}.pm.t");

if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    delete( $ENV{PERL5OPT} );
}
&tests::Command::TestPostProc( $ENV{TEST_TARGET_MDL} );

exit( 0 );
