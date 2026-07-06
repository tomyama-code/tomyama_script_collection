#!/usr/bin/perl -w

use strict;
use warnings 'all';
use File::Basename;
use Cwd 'getcwd';

use constant MODULE_NOT_FOUND_STATUS => 0;

BEGIN {
  ## https://perldoc.jp/docs/modules/Test-Simple-0.96/lib/Test/More.pod
  eval{use Test::More};     # subtest(), done_testing()
  if( $@ ){
    print STDERR ( qq{$0: warn: "Test::More": module not found\n} );
    exit( MODULE_NOT_FOUND_STATUS );
  }
}

BEGIN {
  ## https://metacpan.org/pod/Test::Command
  eval{use Test::Command};
  if( $@ ){
    print STDERR ( qq{$0: warn: "Test::Command": module not found\n} );
    exit( MODULE_NOT_FOUND_STATUS );
  }
}

$ENV{ 'TEST_TARGET_CMD' } = 'mark';

#$ENV{WITH_PERL_COVERAGE} = 1;
$ENV{WITH_PERL_COVERAGE} = 1 if( scalar( @ARGV ) > 0 );

my $apppath = dirname( $0 );
chdir( "$apppath/../" );
my $cur_dir = getcwd();
$apppath = $cur_dir . '/tests';
my $TARGCMD = "./tests/cmd_wrapper";

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
}

subtest qq{"Usage" test} => sub{

    ## Test::CommandはFDを解放しないので、枯渇を避けるため
    ## 局所的なスコープに留めること。
    my $cmd;

    $cmd = Test::Command->new( cmd => "$TARGCMD" );
    $cmd->exit_isnt_num( 0, "Returning an error" );
    $cmd->stdout_is_eq( qq{}, qq{stdout is silent} );
    $cmd->stderr_like( qr/mark: error: Please specify the Regular Expressions./, qq{Usage explanation} );
    $cmd->stderr_like( qr/\nUsage: mark /, qq{Usage explanation} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$TARGCMD --help" );
    $cmd->exit_is_num( 0, "Do not treat it as an error." );
    $cmd->stdout_like( qr/^Usage: mark /, qq{Usage explanation} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$TARGCMD --help 123" );
    $cmd->exit_is_num( 0, "Do not treat it as an error." );
    $cmd->stdout_like( qr/^Usage: mark /, qq{Usage explanation} );
    $cmd->stdout_unlike( qr/123/, qq{Arguments are ignored when displaying "help".} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );
};

subtest qq{<FILE>} => sub{

    ## Test::CommandはFDを解放しないので、枯渇を避けるため
    ## 局所的なスコープに留めること。
    my $cmd;

    $cmd = Test::Command->new( cmd => "$TARGCMD mark $apppath/../mark" );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/^#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
    $cmd->stdout_like( qr/=cut$/, qq{Display to the end} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$TARGCMD '^#!/usr' $apppath/../mark" );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/^#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
    $cmd->stdout_like( qr/=cut$/, qq{Display to the end} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo "123" | $TARGCMD -d mark -} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_is_eq( "123\n", qq{Only "123"} );
    $cmd->stderr_like( qr/\n\@main::fi_in = 1\n/, qq{The number of input files is correct} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo "123" | $TARGCMD -d mark} );
    $cmd->exit_is_num( 0, qq{Omit the hyphen(-).} );
    $cmd->stdout_is_eq( "123\n", qq{Only "123"} );
    $cmd->stderr_like( qr/\n\@main::fi_in = 1\n/, qq{The number of input files is correct} );
    $cmd->stderr_like( qr/\n\$main::fi_in\[ 0 \] = "-"\n/, qq{Hyphens(-) must be completed.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo "123" | $TARGCMD -d mark - -} );
    $cmd->exit_isnt_num( 0, "Returning an error" );
    $cmd->stdout_is_eq( qq{}, qq{stdout is silent} );
    $cmd->stderr_like( qr/mark: error: "STDIN\(-\)" cannot be specified more than once.\n/, qq{The number of input files is correct} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo "123" | $TARGCMD -d mark - $TARGCMD -} );
    $cmd->exit_isnt_num( 0, "Returning an error" );
    $cmd->stdout_is_eq( qq{}, qq{stdout is silent} );
    $cmd->stderr_like( qr/mark: error: "STDIN\(-\)" cannot be specified more than once.\n/, qq{The number of input files is correct} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD c $apppath/../mark $apppath/../mark} );
    $cmd->exit_is_num( 0, "Allows duplicates of existing files." );
    $cmd->stdout_like( qr/#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
    $cmd->stdout_like( qr/=cut$/, qq{Display to the end} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo "123" | $TARGCMD c $apppath/../mark -} );
    $cmd->exit_is_num( 0, "Allows duplicates of existing files." );
    $cmd->stdout_like( qr/#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
    $cmd->stdout_like( qr/:123$/, qq{Display to the end} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD c NON-EXISTENT-FILE} );
    $cmd->exit_isnt_num( 0, "Non-existent files" );
    $cmd->stdout_is_eq( qq{}, qq{stdout is silent} );
    $cmd->stderr_like( qr/mark: error: "NON-EXISTENT-FILE": file not found.\n/, qq{Correct error message.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD c A_FICTITIOUS_UNREADABLE_FILE_FOR_TESTING_PURPOSES} );
    $cmd->exit_isnt_num( 0, "Files without read permission" );
    $cmd->stdout_is_eq( qq{}, qq{stdout is silent} );
    $cmd->stderr_like( qr/mark: error: "A_FICTITIOUS_UNREADABLE_FILE_FOR_TESTING_PURPOSES": permission denied.\n/, qq{Correct error message.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD c A_FICTITIOUS_FILE_FOR_TESTING_PURPOSES} );
    $cmd->exit_isnt_num( 0, "abnormal end" );
    $cmd->stdout_is_eq( qq{}, qq{stdout is silent} );
    $cmd->stderr_like( qr/mark: error: "A_FICTITIOUS_FILE_FOR_TESTING_PURPOSES": could not open file: /, qq{Correct error message.} );
    undef( $cmd );
};

subtest qq{'-d', '--debug' option switch} => sub{

    ## Test::CommandはFDを解放しないので、枯渇を避けるため
    ## 局所的なスコープに留めること。
    my $cmd;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -d '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/^0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLM$/, qq{Display to the correct point} );
    $cmd->stderr_like( qr/\n\$main::debug = 1\n/, qq{Prints debugging information.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --debug '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/^0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLM$/, qq{Display to the correct point} );
    $cmd->stderr_like( qr/\n\$main::debug = 1\n/, qq{Prints debugging information.} );
    undef( $cmd );

};

subtest qq{'-f' option switch} => sub{

    ## Test::CommandはFDを解放しないので、枯渇を避けるため
    ## 局所的なスコープに留めること。
    my $cmd;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\njklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghi\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\ntuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrs$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 3 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nlmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopq$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 0,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 2,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 2,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 0,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 11,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 11,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f3 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nlmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopq$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f2,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f2,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f11,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f11,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0,1, '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_isnt_num( 0, "Incorrect parameter specification." );
    $cmd->stdout_is_eq( qq{}, qq{stdout is silent} );
    $cmd->stderr_like( qr/\nmark: error: You have specified "-0,1," for <PATTERN>.\n/, qq{The right warning.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0 'rstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, qq{Do not display redundant "skip" messages.} );
    $cmd->stdout_like( qr/\*\nlmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopq$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f} );
    $cmd->exit_isnt_num( 0, "An error occurs" );
    $cmd->stdout_is_eq( qq{}, qq{stdout is silent} );
    $cmd->stderr_like( qr/^mark: error: Please specify the Regular Expressions.\n/, qq{Prompt for corrective action.} );
    undef( $cmd );

};

subtest qq{'-h', '--no-filename' option switch} => sub{

    ## Test::CommandはFDを解放しないので、枯渇を避けるため
    ## 局所的なスコープに留めること。
    my $cmd;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0h '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -hf0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0 --no-filename '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --no-filename -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );
};

subtest qq{'-H', '--with-filename' option switch} => sub{

    ## Test::CommandはFDを解放しないので、枯渇を避けるため
    ## 局所的なスコープに留めること。
    my $cmd;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0H '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0H '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -Hf0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0 --with-filename '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --with-filename -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f1H '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
    $cmd->stdout_like( qr/:nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklm\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/:pqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmno$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

};

subtest qq{'-v', '--version' option switch} => sub{

    ## Test::CommandはFDを解放しないので、枯渇を避けるため
    ## 局所的なスコープに留めること。
    my $cmd;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --version} );
    $cmd->exit_is_num( 0, qq{./mark --version} );
    $cmd->stdout_like( qr/^Version: \d/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -v} );
    $cmd->exit_is_num( 0, qq{./mark -v} );
    $cmd->stdout_like( qr/^Version: \d/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent} );
    undef( $cmd );

};

subtest qq{'-i', '--ignore-case' option switch} => sub{

    ## Test::CommandはFDを解放しないので、枯渇を避けるため
    ## 局所的なスコープに留めること。
    my $cmd;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_is_eq( qq{}, qq{No lines match.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0i '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Match with optional effects.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -if0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Match with optional effects.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f0 --ignore-case '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Match with optional effects.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --ignore-case -f0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Match with optional effects.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --ignore-case --force-color -f0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

};

subtest qq{'-n', '--line-number' option switch} => sub{

    ## Test::CommandはFDを解放しないので、枯渇を避けるため
    ## 局所的なスコープに留めること。
    my $cmd;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_unlike( qr/25/, qq{Line numbers are not displayed.} );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 0 -n '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{The line number is displayed.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -n -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{The line number is displayed.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 0 --line-number '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{The line number is displayed.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --line-number -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{The line number is displayed.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f1n '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/24:nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklm\n/, qq{Display from the correct point} );
    $cmd->stdout_like( qr/26:pqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmno$/, qq{Display to the correct point} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

};

subtest qq{'-c', '--force-color' option switch} => sub{

    ## Test::CommandはFDを解放しないので、枯渇を避けるため
    ## 局所的なスコープに留めること。
    my $cmd;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_unlike( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n/, qq{Not highlighted.} );
    $cmd->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Not highlighted.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 0 -c '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -c -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 0 --force-color '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --force-color -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -f 0 --test-force-tty '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

};

done_testing();

if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    if( $ENV{WITH_PERL_COVERAGE_OWNER} eq $$ ){
        print( `cover` );
    }
}

my $test_end = `./c 'now'`;
my $test_duration = $test_end - $test_beg;
print( qq{$ENV{ 'TEST_TARGET_CMD' }: test: Begin: } . `./c 'epoch2local( $test_beg )'` );
print( qq{$ENV{ 'TEST_TARGET_CMD' }: test:   End: } . `./c 'epoch2local( $test_end )'` );
print( qq{$ENV{ 'TEST_TARGET_CMD' }: test: Elaps: } . `./c 'sec2dhms( $test_duration )'` );
exit( 0 );
