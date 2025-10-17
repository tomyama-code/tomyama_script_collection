#!/usr/bin/perl -w

use strict;
use warnings 'all';
use File::Basename;

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

#$ENV{WITH_PERL_COVERAGE} = 1;

#if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
#    if( !defined( $ENV{WITH_PERL_COVERAGE_OWNER} ) ){
#        $ENV{WITH_PERL_COVERAGE_OWNER} = $$;
#
#        `which cover 2>/dev/null`;
#        my $bUnavailableCover = $?;
#        #printf( qq{\$bUnavailableCover=$bUnavailableCover\n} );
#        if( $bUnavailableCover ){
#            print STDERR ( qq{$0: warn: "cover" command not found: \$ENV{WITH_PERL_COVERAGE}: ignore\n} );
#            delete( $ENV{WITH_PERL_COVERAGE} );
#        }
#    }
#}

#my $develCoverStatus = -1;
#if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
#    if( $ENV{WITH_PERL_COVERAGE_OWNER} == $$ ){
#        $develCoverStatus=`cover -delete`;
#    }
#}

my $apppath = dirname( $0 );
my $HELLOCMD = "$apppath/../hello.sh";
my $cmd;

subtest qq{hello.sh} => sub{
    plan( tests=> 3 );

    $cmd = Test::Command->new( cmd => qq{$HELLOCMD} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{hello, world!\n}, qq{Verify the correct output.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );
};

done_testing( 1 );

#if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
#    if( $ENV{WITH_PERL_COVERAGE_OWNER} eq $$ ){
#        $develCoverStatus=`cover`;
#    }
#}
