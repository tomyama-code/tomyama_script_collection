#!/usr/bin/perl -w

use strict;
use warnings;

## Test::More was first released with perl v5.6.2
use Test::More;     # subtest()

#use lib '.';
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Command;

use Cwd 'getcwd';   # getcwd()

&tests::Command::TestPreProc( $0, @ARGV );

my $proj_root = getcwd();
my $apppath = $proj_root . '/tests';

subtest qq{"Usage" test} => sub{
    my $t;

    $t = tests::Command->new( "./mark" );
    $t->exit_isnt( 0, "Returning an error" );
    $t->stdout_is( qq{}, qq{stdout is silent} );
    $t->stderr_like( qr/mark: error: Please specify the Regular Expressions./, qq{Usage explanation} );
    $t->stderr_like( qr/\nUsage: mark /, qq{Usage explanation} );
    undef( $t );

    $t = tests::Command->new( "./mark --help" );
    $t->exit_is( 0, "Do not treat it as an error." );
    $t->stdout_like( qr/^Usage: mark /, qq{Usage explanation} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( "./mark --help 123" );
    $t->exit_is( 0, "Do not treat it as an error." );
    $t->stdout_like( qr/^Usage: mark /, qq{Usage explanation} );
    $t->stdout_unlike( qr/123/, qq{Arguments are ignored when displaying "help".} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );
};

subtest qq{<FILE>} => sub{
    my $t;

    $t = tests::Command->new( "./mark mark $proj_root/m?rk" );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/^#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
    $t->stdout_like( qr/=cut$/, qq{Display to the end} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./mark '^#!/usr' $proj_root/m?rk" );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/^#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
    $t->stdout_like( qr/=cut$/, qq{Display to the end} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{echo "123" | ./mark -d mark -} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_is( "123\n", qq{Only "123"} );
    $t->stderr_like( qr/\n\@main::fi_in = 1\n/, qq{The number of input files is correct} );
    undef( $t );

    $t = tests::Command->new( qq{echo "123" | ./mark -d mark} );
    $t->exit_is( 0, qq{Omit the hyphen(-).} );
    $t->stdout_is( "123\n", qq{Only "123"} );
    $t->stderr_like( qr/\n\@main::fi_in = 1\n/, qq{The number of input files is correct} );
    $t->stderr_like( qr/\n\$main::fi_in\[ 0 \] = "-"\n/, qq{Hyphens(-) must be completed.} );
    undef( $t );

    $t = tests::Command->new( qq{echo "123" | ./mark -d mark - -} );
    $t->exit_isnt( 0, "Returning an error" );
    $t->stdout_is( qq{}, qq{stdout is silent} );
    $t->stderr_like( qr/mark: error: "STDIN\(-\)" cannot be specified more than once.\n/, qq{The number of input files is correct} );
    undef( $t );

    $t = tests::Command->new( qq{echo "123" | ./mark -d mark - ./mark -} );
    $t->exit_isnt( 0, "Returning an error" );
    $t->stdout_is( qq{}, qq{stdout is silent} );
    $t->stderr_like( qr/mark: error: "STDIN\(-\)" cannot be specified more than once.\n/, qq{The number of input files is correct} );
    undef( $t );

    $t = tests::Command->new( qq{./mark c $proj_root/m?rk $proj_root/m?rk} );
    $t->exit_is( 0, "Allows duplicates of existing files." );
    $t->stdout_like( qr/#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
    $t->stdout_like( qr/=cut$/, qq{Display to the end} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{echo "123" | ./mark c $proj_root/m?rk -} );
    $t->exit_is( 0, "Allows duplicates of existing files." );
    $t->stdout_like( qr/#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
    $t->stdout_like( qr/:123$/, qq{Display to the end} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark c NON-EXISTENT-FILE} );
    $t->exit_isnt( 0, "Non-existent files" );
    $t->stdout_is( qq{}, qq{stdout is silent} );
    $t->stderr_like( qr/mark: error: "NON-EXISTENT-FILE": file not found.\n/, qq{Correct error message.} );
    undef( $t );

    $t = tests::Command->new( qq{./mark c A_FICTITIOUS_UNREADABLE_FILE_FOR_TESTING_PURPOSES} );
    $t->exit_isnt( 0, "Files without read permission" );
    $t->stdout_is( qq{}, qq{stdout is silent} );
    $t->stderr_like( qr/mark: error: "A_FICTITIOUS_UNREADABLE_FILE_FOR_TESTING_PURPOSES": permission denied.\n/, qq{Correct error message.} );
    undef( $t );

    $t = tests::Command->new( qq{./mark c A_FICTITIOUS_FILE_FOR_TESTING_PURPOSES} );
    $t->exit_isnt( 0, "abnormal end" );
    $t->stdout_is( qq{}, qq{stdout is silent} );
    $t->stderr_like( qr/mark: error: "A_FICTITIOUS_FILE_FOR_TESTING_PURPOSES": could not open file: /, qq{Correct error message.} );
    undef( $t );
};

subtest qq{'-d', '--debug' option switch} => sub{
    my $t;

    $t = tests::Command->new( qq{./mark -d '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/^0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLM$/, qq{Display to the correct point} );
    $t->stderr_like( qr/\n\$main::debug = 1\n/, qq{Prints debugging information.} );
    undef( $t );

    $t = tests::Command->new( qq{./mark --debug '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/^0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLM$/, qq{Display to the correct point} );
    $t->stderr_like( qr/\n\$main::debug = 1\n/, qq{Prints debugging information.} );
    undef( $t );

};

subtest qq{'-f' option switch} => sub{
    my $t;

    $t = tests::Command->new( qq{./mark -f '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\njklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghi\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\ntuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrs$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 3 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nlmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopq$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 0,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 2,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 2,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 0,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 11,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 11,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f3 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nlmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopq$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f0,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f2,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f2,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f0,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f11,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f11,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f0,1, '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_isnt( 0, "Incorrect parameter specification." );
    $t->stdout_is( qq{}, qq{stdout is silent} );
    $t->stderr_like( qr/\nmark: error: You have specified "-0,1," for <PATTERN>.\n/, qq{The right warning.} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f0 'rstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, qq{Do not display redundant "skip" messages.} );
    $t->stdout_like( qr/\*\nlmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopq$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f} );
    $t->exit_isnt( 0, "An error occurs" );
    $t->stdout_is( qq{}, qq{stdout is silent} );
    $t->stderr_like( qr/^mark: error: Please specify the Regular Expressions.\n/, qq{Prompt for corrective action.} );
    undef( $t );

};

subtest qq{'-h', '--no-filename' option switch} => sub{
    my $t;

    $t = tests::Command->new( qq{./mark -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f0h '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -hf0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f0 --no-filename '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark --no-filename -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );
};

subtest qq{'-H', '--with-filename' option switch} => sub{
    my $t;

    $t = tests::Command->new( qq{./mark -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f0H '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f0H '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -Hf0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f0 --with-filename '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark --with-filename -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f1H '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $t->stdout_like( qr/:nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklm\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/:pqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmno$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

};

subtest qq{'-v', '--version' option switch} => sub{
    my $t;

    $t = tests::Command->new( qq{./mark --version} );
    $t->exit_is( 0, qq{./mark --version} );
    $t->stdout_like( qr/^Version: \d/ );
    $t->stderr_is( qq{}, qq{STDERR is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -v} );
    $t->exit_is( 0, qq{./mark -v} );
    $t->stdout_like( qr/^Version: \d/ );
    $t->stderr_is( qq{}, qq{STDERR is silent} );
    undef( $t );

};

subtest qq{'-i', '--ignore-case' option switch} => sub{
    my $t;

    $t = tests::Command->new( qq{./mark -f0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_is( qq{}, qq{No lines match.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f0i '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Match with optional effects.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -if0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Match with optional effects.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f0 --ignore-case '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Match with optional effects.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark --ignore-case -f0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Match with optional effects.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark --ignore-case --force-color -f0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

};

subtest qq{'-n', '--line-number' option switch} => sub{
    my $t;

    $t = tests::Command->new( qq{./mark -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_unlike( qr/25/, qq{Line numbers are not displayed.} );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 0 -n '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{The line number is displayed.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -n -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{The line number is displayed.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 0 --line-number '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{The line number is displayed.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark --line-number -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{The line number is displayed.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f1n '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/24:nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklm\n/, qq{Display from the correct point} );
    $t->stdout_like( qr/26:pqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmno$/, qq{Display to the correct point} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

};

subtest qq{'-c', '--force-color' option switch} => sub{
    my $t;

    $t = tests::Command->new( qq{./mark -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_unlike( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n/, qq{Not highlighted.} );
    $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Not highlighted.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 0 -c '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -c -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 0 --force-color '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark --force-color -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./mark -f 0 --test-force-tty '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

};

&tests::Command::TestPostProc( $ENV{TEST_TARGET_CMD} );
