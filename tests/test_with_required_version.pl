#!/usr/bin/env perl

use strict;                         # first released with perl 5
use warnings;                       # first released with perl v5.6.0

use lib './tools';    # @INC にディレクトリを追加
require GenAutotoolsAcAm_UserFile;

sub command_exists( $ )
{
    `which $_[ 0 ] >/dev/null 2>&1`;
    my $exit_status = $?;
    return ( $exit_status ? 0 : 1 );
}

sub perl_ver_num_to_str( $ )
{
    my( $ver_num ) = @_;
    $ver_num =~ s/_//go;
    $ver_num = $ver_num + 0;
    my $ver = int( $ver_num );
    $ver_num = sprintf( '%.6f', ( $ver_num - $ver ) * 1000 );
    my $major = int( $ver_num );
    $ver_num = sprintf( '%.3f', ( $ver_num - $major ) * 1000 );
    my $minor = int( $ver_num );
    return "$ver.$major.$minor";
}

sub perlbrew_exec( $$@ )
{
    my $ref_sign = shift( @_ );
    my $ref_label = shift( @_ );
    my @args = @_;

    my @shell_stdout = ();
    my $exit_status = shell_exec( \@shell_stdout, 'perlbrew', @args );
    for my $line( @shell_stdout ){
        $line =~ s/\r?\n$//o;
        $line =~ s/^\s*(.*)\s*$/$1/o;

        my $sign = '';
        my $label = '';
        if( $line =~ m/^([^\s]*)\s+(.*)$/o ){
            #print( qq{\$1="$1", \$2="$2"\n} );
            if( $2 eq '' ){
                $label = $1;
            }else{
                $sign = $1;
                $label = $2;
            }
            #print( qq{\$sign="$sign", \$label="$label"\n} );
        }
        push( @$ref_sign, $sign );
        push( @$ref_label, $label );
    }
    return $exit_status;
}

#sub get_cmd_str( @ )
#{
#    my @cmds = @_;
#    my @args = @cmds;
#    my $cmd = shift( @args );
#    my $args_len = scalar( @args );
#    for( my $idx=0; $idx<$args_len; $idx++ ){
#        $args[ $idx ] = qq{'$args[ $idx ]'};
#    }
#    my $cmd_str = "$cmd " . join( ' ', @args );
#    return $cmd_str;
#}

sub shell_exec( $@ )
{
    my $ref_stdout = shift( @_ );
    my @cmds = @_;

#    my $cmd_str = get_cmd_str( @cmds );
#    print( qq{\n  \$ $cmd_str\n} );

    @$ref_stdout = () if( defined( $ref_stdout ) );

    open( CMD_HANDLE, '-|', @cmds ) ||
        die( qq{Command execution failed: $!} );
    if( defined( $ref_stdout ) ){
        @$ref_stdout = <CMD_HANDLE>;
    }else{
        local $| = 1;
        while( <CMD_HANDLE> ){
            my $line = $_;
            $line =~ s/\r?\n$//o;
            print( qq{$line\n} );
        }
    }
    close( CMD_HANDLE );
    my $exit_status = $? >> 8;

    return $exit_status;
}

sub get_perl_env()
{
    my @list_flag = ();
    my @list_label = ();
    perlbrew_exec( \@list_flag, \@list_label, 'list' );
    my %perl_env = ();
    for my $label( @list_label ){
        #print( qq{\$label="$label"\n} );
        my $perl_ver = $label;
        $perl_ver =~ s/^perl-//o;
        #print( qq{\$perl_ver="$perl_ver"\n} );
        $perl_env{$perl_ver} = 1;
    }
    return %perl_env;
}

my @scripts = GenAutotoolsAcAm_UserFile::getMyScripts();
#printf( qq{( %s )\n}, join( ', ', @scripts ) );

my $perlbrew = 'perlbrew';
my $is_perlbrew_exists = command_exists( $perlbrew );
#print( qq{\$is_perlbrew_exists = $is_perlbrew_exists\n} );
if( $is_perlbrew_exists == 0 ){
    print STDERR ( qq{$0: error: "$perlbrew": command not found\n} );
    exit( 1 );
}

my %perl_env = get_perl_env();

#GenAutotoolsAcAm_UserFile::setupValue();
#my @testRunners = GenAutotoolsAcAm_UserFile::getTestRunners();
#printf( qq{( %s )\n}, join( ', ', @testRunners ) );

#my $curr_perl_ver_num = $];
my $curr_perl_ver_str = perl_ver_num_to_str( $] );
print( qq{Current Perl version = "$curr_perl_ver_str"\n} );

my %require_version = ();
for my $scr( @scripts ){
    $require_version{ $scr } = $curr_perl_ver_str;
    open( SCR, '<', $scr ) ||
        die( qq{"$scr": could not open file: $!} );
    while( <SCR> ){
        my $line = $_;
        $line =~ s/\r?\n$//o;

        if( $line =~ m/^use (5\.\d[\d_]+\d);/o ){
            $require_version{ $scr } = perl_ver_num_to_str( $1 );
#            printf( "%-15s: %s\n", $scr, $require_version{ $scr } );
            last;
        }
    }
    close( SCR );
}

my %testables = ();
print( qq{\n} .
       qq{---------------  -------  ---\n} .
       qq{Script Name      Require  Env.\n} .
       qq{---------------  -------  ---\n} );
for my $scr( @scripts ){
    my $req_ver = $require_version{ $scr };
    my $testable = ( defined( $perl_env{ $req_ver } ) ? 1 : 0 );
    printf( "%-15s  %-7s   %s\n",
        $scr, $req_ver, ( $testable ? 'o' : 'x' ) );

    $testables{ $scr } = $testable;
}
print( qq{---------------  -------  ---\n} );

print( qq{\n} .
       qq{  - Testing with the minimum required version.\n} .
       qq{      ---------------  --------  -------  -----------\n} .
       qq{      Script Name      Version   Perl     Test Result\n} .
       qq{      ---------------  --------  -------  -----------\n} );
my $test_result = 0;
for my $scr( @scripts ){
    next if( $testables{ $scr } == 0 );

    # https://metacpan.org/release/GUGOD/App-perlbrew-0.71/view/bin/perlbrew
    # https://perldoc.jp/docs/modules/App-perlbrew-0.10/bin/perlbrew.pod
    # $ perlbrew exec --with perl-5.12.0 perl -e "print( qq{version: $^V\n} );"
    # $ perlbrew exec --with perl-5.14.0 perl ./timezone_id JST

    my $req_ver = $require_version{ $scr };
    my @cmd_args = (
        'perlbrew', 'exec', '--with', "perl-${req_ver}",
        'perl', "./tests/${scr}.test.pl" );
    my $log_file = "./tests/${scr}.test.pl.${req_ver}.log";

    my @test_stdout = ();
    my $test_status = shell_exec( \@test_stdout, @cmd_args );
    $test_result += $test_status;

    open( OUTLOG, '>', $log_file ) ||
        die( qq{$log_file: could not open file: $!} );
    print OUTLOG ( join( "", @test_stdout ) . "\n" );
    close( OUTLOG );

    my $perl_ver = '';
    my $targ_ver = '';
    for my $line( @test_stdout ){
        $line =~ s/\r?\n$//o;

        ## Perl Version: v5.44.0, Test Target: 1.05.033
        if( $line =~ m/^Perl Version: (v\d+\.\d+\.\d+), Test Target: (\d+\.\d+\.\d+)$/o ){
            $perl_ver = $1;
            $targ_ver = $2;
            last;
        }
    }

    printf( qq{      %-15s  %-8s  %-7s  %s %s\n},
        $scr, $targ_ver, $perl_ver, ( $test_status ? 'NG' : 'ok' ), $log_file );
}
print( qq{      ---------------  --------  -------  -----------\n} );

exit( $test_result );
