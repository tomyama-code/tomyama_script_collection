#!/usr/bin/perl -w

use strict;
use warnings 'all';
use File::Basename;


$ENV{TEST_TARGET_MODULE} = 'FTCalc';

#$ENV{WITH_PERL_COVERAGE} = 1;
$ENV{WITH_PERL_COVERAGE} = 1 if( scalar( @ARGV ) > 0 );

my $test_beg = `./c 'now'`;

if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    if( !defined( $ENV{WITH_PERL_COVERAGE_OWNER} ) ){
        $ENV{WITH_PERL_COVERAGE_OWNER} = $$;

        `which cover 2>/dev/null`;
        my $bUnavailableCover = $?;
        #printf( qq{\$bUnavailableCover=$bUnavailableCover\n} );
        if( $bUnavailableCover ){
            print STDERR ( qq{$0: warn: "cover" command not found: \$ENV{WITH_PERL_COVERAGE}: ignore\n} );
            delete( $ENV{WITH_PERL_COVERAGE} );
            delete( $ENV{WITH_PERL_COVERAGE_OWNER} );
        }else{
            print( `cover -delete` );
        }
    }
    $ENV{PERL5OPT} = '-MDevel::Cover=-ignore,/prove,-ignore,^c$,-ignore,\.t$';
}

system("prove -lv tests/$ENV{TEST_TARGET_MODULE}.pm.t");

if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    delete( $ENV{PERL5OPT} );

    if( $ENV{WITH_PERL_COVERAGE_OWNER} eq $$ ){
        print( `cover` );
    }
}

my $test_end = `./c 'now'`;
my $test_duration = $test_end - $test_beg;
print( qq{$ENV{TEST_TARGET_MODULE}: test: Begin: } . `./c 'epoch2local( $test_beg )'` );
print( qq{$ENV{TEST_TARGET_MODULE}: test:   End: } . `./c 'epoch2local( $test_end )'` );
print( qq{$ENV{TEST_TARGET_MODULE}: test: Elaps: } . `./c 'sec2dhms( $test_duration )'` );
exit( 0 );
