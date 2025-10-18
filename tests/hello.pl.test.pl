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

$ENV{ 'TEST_TARGET_CMD' } = 'hello.pl';

#$ENV{WITH_PERL_COVERAGE} = 1;

my $apppath = dirname( $0 );
chdir( "$apppath/../" );
my $cur_dir = getcwd();
$apppath = $cur_dir . '/tests';
my $HELLOCMD = "$apppath/cmd_wrapper";

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

subtest qq{hello.pl} => sub{
    $cmd = Test::Command->new( cmd => qq{$HELLOCMD} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{hello, world!\n}, qq{Verify the correct output.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$HELLOCMD error} );
    $cmd->exit_isnt_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{hello, world!\n}, qq{Verify the correct output.} );
    $cmd->stderr_like( qr/error/, "error message" );
    undef( $cmd );
};

done_testing();

if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    if( $ENV{WITH_PERL_COVERAGE_OWNER} eq $$ ){
        $develCoverStatus=`cover`;
    }
}
