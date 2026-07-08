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

subtest 'BASIC-TEST' => sub{
    my $t;

    $t = tests::Command->new( qq{./tsc_bin_path.pl} );
    #$t->dump();
    $t->exit_is( 0, '引数無しで呼び出す' );
    $t->stdout_like( qr/tomyama_script_collection/ );
    $t->stderr_is( '' );

    $t = tests::Command->new( qq{./tsc_bin_path.pl 'tools'} );
    #$t->dump();
    $t->exit_is( 0, 'サブディレクトリを指定' );
    $t->stdout_like( qr/\/tools$/ );
    $t->stderr_is( '' );

    $t = tests::Command->new( qq{./tsc_bin_path.pl '123'} );
    #$t->dump();
    $t->exit_isnt( 0, '存在しないパス' );
    $t->stdout_is( '' );
    $t->stderr_like( qr/^error: directory not found: / );
};

subtest '-h, --help' => sub{
    my $t;

    $t = tests::Command->new( qq{./tsc_bin_path.pl -h} );
    #$t->dump();
    $t->exit_is( 0, 'ショート形式のオプションでヘルプ表示' );
    $t->stdout_like( qr/^NAME\n    tsc_bin_path.pl / );
    $t->stderr_is( '' );

    $t = tests::Command->new( qq{./tsc_bin_path.pl --help} );
    #$t->dump();
    $t->exit_is( 0, 'ロング形式のオプションでヘルプ表示' );
    $t->stdout_like( qr/^NAME\n    tsc_bin_path.pl / );
    $t->stderr_is( '' );
};

&tests::Command::TestPostProc( $ENV{TEST_TARGET_CMD} );
