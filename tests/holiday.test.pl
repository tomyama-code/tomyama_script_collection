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

$ENV{ 'TEST_TARGET_CMD' } = 'holiday';

#$ENV{WITH_PERL_COVERAGE} = 1;
$ENV{WITH_PERL_COVERAGE} = 1 if( scalar( @ARGV ) > 0 );

my $apppath = dirname( $0 );
chdir( "$apppath/../" );
my $cur_dir = getcwd();
$apppath = $cur_dir . '/tests';
my $TARGCMD = "./tests/cmd_wrapper";

my $test_beg = `./c 'now'`;

my $develCoverStatus = -1;
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
            $develCoverStatus=`cover -delete`;
        }
    }
}

my $cmd;

subtest qq{Normal} => sub{

    $cmd = Test::Command->new( cmd => qq{$TARGCMD | cat -} );
    $cmd->exit_is_num( 0, qq{./holiday | cat -} );
    $cmd->stdout_like( qr/^## \$Id: cl\.holiday,v / );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{PAGER=cat $TARGCMD} );
    $cmd->exit_is_num( 0, qq{PAGER=cat ./holiday} );
    $cmd->stdout_like( qr/^## \$Id: cl\.holiday,v / );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{PAGER=non-existent-command $TARGCMD} );
    $cmd->exit_isnt_num( 0, qq{PAGER=non-existent-command ./holiday} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/\nnon\-existent\-command \.\/tests\/\.\.\/cl\.holiday: failed: status=\-1: / );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD unknown_argument | cat -} );
    $cmd->exit_is_num( 0, qq{./holiday unknown_argument | cat -} );
    $cmd->stdout_like( qr/^## \$Id: cl\.holiday,v / );
    $cmd->stderr_is_eq( qq{holiday: warn: unknown_argument: unknown argument\n} );
    undef( $cmd );

};

subtest qq{-v, --version} => sub{

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -v} );
    $cmd->exit_is_num( 0, qq{./holiday -v} );
    $cmd->stdout_like( qr/^Version: \d/ );
    $cmd->stdout_like( qr/\n   Perl: v\d/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --version} );
    $cmd->exit_is_num( 0, qq{./holiday --version} );
    $cmd->stdout_like( qr/^Version: \d/ );
    $cmd->stdout_like( qr/\n   Perl: v\d/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{-h, --help} => sub{

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -h} );
    $cmd->exit_is_num( 0, qq{./holiday -h} );
    $cmd->stdout_like( qr/^Usage: holiday / );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --help} );
    $cmd->exit_is_num( 0, qq{./holiday --help} );
    $cmd->stdout_like( qr/^Usage: holiday / );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};


done_testing();

if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    if( $ENV{WITH_PERL_COVERAGE_OWNER} eq $$ ){
        $develCoverStatus=`cover`;
    }
}

my $test_end = `./c 'now'`;
my $test_duration = $test_end - $test_beg;
print( qq{$ENV{ 'TEST_TARGET_CMD' }: test: Begin: } . `./c 'epoch2local( $test_beg )'` );
print( qq{$ENV{ 'TEST_TARGET_CMD' }: test:   End: } . `./c 'epoch2local( $test_end )'` );
print( qq{$ENV{ 'TEST_TARGET_CMD' }: test: Elaps: } . `./c 'sec2dhms( $test_duration )'` );
exit( 0 );
