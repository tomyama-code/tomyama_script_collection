#!/usr/bin/perl -w

use strict;
use warnings 'all';
use File::Basename ;

use constant MODULE_NOT_FOUND_STATUS => 0;

BEGIN {
  ## https://perldoc.jp/docs/modules/Test-Simple-0.96/lib/Test/More.pod
  eval{use Test::More};     # subtest(), done_testing()
  if( $@ ){
    print STDERR ( qq{Test::More: not found\n} );
    exit( MODULE_NOT_FOUND_STATUS );
  }
}

BEGIN {
  ## https://metacpan.org/pod/Test::Command
  eval{use Test::Command};
  if( $@ ){
    print STDERR ( qq{Test::Command: not found\n} );
    exit( MODULE_NOT_FOUND_STATUS );
  }
}

#$ENV{WITH_PERL_COVERAGE} = 1;

if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    `which cover 2>/dev/null`;
    my $bUnavailableCover = $?;
    #printf( qq{\$bUnavailableCover=$bUnavailableCover\n} );
    if( $bUnavailableCover ){
        print STDERR ( qq{$0: "cover" command not found: \$ENV{WITH_PERL_COVERAGE}: ignore\n} );
        delete( $ENV{WITH_PERL_COVERAGE} );
    }
}

my $develCoverStatus = -1;
if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    $develCoverStatus=`cover -delete`;
}

my $apppath = dirname( $0 );
my $MARKCMD = "$apppath/mark_wrapper.pl";
my $cmd;

subtest qq{argument} => sub{
    $cmd = Test::Command->new( cmd => "$MARKCMD mark $apppath/../mark" );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/^#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
    $cmd->stdout_like( qr/=cut$/, qq{Display to the end} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$MARKCMD '^#!/usr' $apppath/../mark" );
    $cmd->exit_is_num( 0, "normal termination" );
    $cmd->stdout_like( qr/^#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
    $cmd->stdout_like( qr/=cut$/, qq{Display to the end} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );
};

subtest qq{"Usage" test} => sub{
    $cmd = Test::Command->new( cmd => "$MARKCMD" );
    $cmd->exit_isnt_num( 0, "Returning an error" );
    $cmd->stdout_is_eq( qq{}, qq{stdout is silent} );
    $cmd->stderr_like( qr/mark: Please specify the Regular Expressions./, qq{Usage explanation} );
    $cmd->stderr_like( qr/\nUsage: mark /, qq{Usage explanation} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$MARKCMD --help" );
    $cmd->exit_is_num( 0, "Do not treat it as an error." );
    $cmd->stdout_like( qr/^Usage: mark /, qq{Usage explanation} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$MARKCMD --help 123" );
    $cmd->exit_is_num( 0, "Do not treat it as an error." );
    $cmd->stdout_like( qr/^Usage: mark /, qq{Usage explanation} );
    $cmd->stdout_unlike( qr/123/, qq{Arguments are ignored when displaying "help".} );
    $cmd->stderr_is_eq( qq{}, qq{stderr is silent} );
    undef( $cmd );
};

#subtest qq{debug mode} => sub{
#    $cmd = Test::Command->new( cmd => "$MARKCMD -d -1 123" );
#    $cmd->exit_is_num( 0, "exit status is 0" );
#    $cmd->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
#    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
#    undef( $cmd );
#
#    $cmd = Test::Command->new( cmd => "$MARKCMD --debug -1 123" );
#    $cmd->exit_is_num( 0, "exit status is 0" );
#    $cmd->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
#    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
#    undef( $cmd );
#
#    $cmd = Test::Command->new( cmd => "$MARKCMD -dh -1 123" );
#    $cmd->exit_is_num( 0, "exit status is 0" );
#    $cmd->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
#    $cmd->stdout_like( qr/usage: fill /, "usage output" );
#    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
#    undef( $cmd );
#
#    ## テストは通せるがキャプチャできないのでSTDOUTの評価ができない。その為やる意味が無い。
#    $cmd = Test::Command->new( cmd => "$MARKCMD --test-force-tty -2 a- 1:1 -b " );
#    $cmd->exit_is_num( 0, "exit status is 0" );
#    $cmd->stdout_is_eq( qq{a-\033[1m1\033[0m-b\na-\033[1m2\033[0m-b\n}, qq{ANSI escape sequence} );
#    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
#    undef( $cmd );
#};
#
#subtest qq{"-f" option switch} => sub{
#    $cmd = Test::Command->new( cmd => "$MARKCMD -3 10:2" );
#    $cmd->exit_is_num( 0, "Always terminates normally." );
#    $cmd->stdout_is_eq( "10\n12\n14\n", qq{"-N" option switch} );
#    $cmd->stderr_is_eq( "", "stderr is silent" );
#    undef( $cmd );
#
#    $cmd = Test::Command->new( cmd => "$MARKCMD -9 1:1" );
#    $cmd->exit_is_num( 0, "Always terminates normally." );
#    $cmd->stdout_is_eq( "1\n2\n3\n4\n5\n6\n7\n8\n9\n", "Single digit counter" );
#    $cmd->stderr_is_eq( "", "stderr is silent" );
#    undef( $cmd );
#
#    $cmd = Test::Command->new( cmd => "$MARKCMD -10 1:1" );
#    $cmd->exit_is_num( 0, "Always terminates normally." );
#    $cmd->stdout_is_eq( "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n", "double-digit counter" );
#    $cmd->stderr_is_eq( "", "stderr is silent" );
#    undef( $cmd );
#
#    $cmd = Test::Command->new( cmd => "$MARKCMD -10d3 1:1" );
#    $cmd->exit_is_num( 0, "Always terminates normally." );
#    $cmd->stdout_like( qr/1\n2\n3\n$/, "Use the last specified value." );
#    $cmd->stderr_is_eq( "", "stderr is silent" );
#    undef( $cmd );
#
#    $cmd = Test::Command->new( cmd => "$MARKCMD -0 -" );
#    $cmd->exit_is_num( 0, "Always terminates normally." );
#    $cmd->stdout_is_eq( "", qq{"-0" is also allowed} );
#    $cmd->stderr_is_eq( "", "stderr is silent" );
#    undef( $cmd );
#
#    $cmd = Test::Command->new( cmd => "echo 123 | $MARKCMD -2 -" );
#    $cmd->exit_is_num( 0, "Always terminates normally." );
#    $cmd->stdout_is_eq( "123\n", "Outputs the number of lines in STDIN instead of the default 10 lines." );
#    $cmd->stderr_like( qr/^fill: STDIN=1, specified_cycle=2: /, "Show warning" );
#    undef( $cmd );
#
#    $cmd = Test::Command->new( cmd => "echo 123 | $MARKCMD -1 -" );
#    $cmd->exit_is_num( 0, "Always terminates normally." );
#    $cmd->stdout_is_eq( "123\n", "Outputs the number of lines in STDIN instead of the default 10 lines." );
#    $cmd->stderr_is_eq( "", "stderr is silent" );
#    undef( $cmd );
#
#    $cmd = Test::Command->new( cmd => "echo 123 | $MARKCMD -0 -" );
#    $cmd->exit_is_num( 0, "Always terminates normally." );
#    $cmd->stdout_is_eq( "", "stdout is silent" );
#    $cmd->stderr_is_eq( "", "stderr is silent" );
#    undef( $cmd );
#};

done_testing;

if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    $develCoverStatus=`cover`;
}
