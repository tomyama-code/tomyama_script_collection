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

$ENV{ 'TEST_TARGET_CMD' } = 'c';

#$ENV{WITH_PERL_COVERAGE} = 1;
$ENV{WITH_PERL_COVERAGE} = 1 if( scalar( @ARGV ) > 0 );

my $UV_bit_width = log( ~0 + 1 ) / log( 2 );    # perlの整数は固定幅ではないので桁溢れしない。
#print( qq{\$UV_bit_width="$UV_bit_width"\n} );

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

`gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.deploy && mv .c.rc.deploy .c.rc`;

subtest qq{Normal} => sub{
    $cmd = Test::Command->new( cmd => qq{echo | $TARGCMD} );
    $cmd->exit_is_num( 0, qq{echo | ./c} );
    $cmd->stdout_is_eq( qq{\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 123456-59+123.456*2=} );
    $cmd->exit_is_num( 0, qq{./c 123456-59+123.456*2=} );
    $cmd->stdout_is_eq( qq{123643.912\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '123456-(59+123.456)*2='} );
    $cmd->exit_is_num( 0, qq{./c '123456-(59+123.456)*2='} );
    $cmd->stdout_is_eq( qq{123091.088\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 123+45*6-7=} );
    $cmd->exit_is_num( 0, qq{./c 123+45*6-7=} );
    $cmd->stdout_is_eq( qq{386\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD １２３，４５６－５９ ＋ １２３．４５６＊２＝} );
    $cmd->exit_is_num( 0, qq{./c １２３，４５６－５９ ＋ １２３．４５６＊２＝} );
    $cmd->stdout_is_eq( qq{123643.912\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD １２３，４５６－５９ ＋ １２３．４５６（３－１）＝} );
    $cmd->exit_is_num( 0, qq{./c １２３，４５６－５９ ＋ １２３．４５６（３－１）＝} );
    $cmd->stdout_is_eq( qq{123643.912\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD １２３，４５６－５９ ＋ １２３．４５６（３－２＊１＋１）＝} );
    $cmd->exit_is_num( 0, qq{./c １２３，４５６－５９ ＋ １２３．４５６（３－２＊１＋１）＝} );
    $cmd->stdout_is_eq( qq{123643.912\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD １２３，４５６－５９ ＋ １２３．４５６（（３－２）＊１＋１）＝} );
    $cmd->exit_is_num( 0, qq{./c １２３，４５６－５９ ＋ １２３．４５６（（３－２）＊１＋１）＝} );
    $cmd->stdout_is_eq( qq{123643.912\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD １２３，４５６＋－５９ ＋ １２３．４５６（（３－２）＊１＋１）＝} );
    $cmd->exit_is_num( 0, qq{./c １２３，４５６＋－５９ ＋ １２３．４５６（（３－２）＊１＋１）＝} );
    $cmd->stdout_is_eq( qq{123643.912\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'round( geo_distance_km( 北緯５１．５０３２４度、西経０．１１３４度,　南緯６９．００４３９°，東経３９．５８２２° ), 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'round( geo_distance_km( 北緯５１．５０３２４度、西経０．１１３４度,　南緯６９．００４３９°，東経３９．５８２２° ), 0 )'} );
    $cmd->stdout_is_eq( qq{13787\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD "round( geo_distance_km( 51°30'11.6639999999933\\"N, 0°6'48.24\\"W,　69°0'15.8040000000028\\"S，39°34'55.920000000001\\"E ), 0 )"} );
    $cmd->exit_is_num( 0, qq{./c "round( geo_distance_km( 51°30'11.6639999999933\\"N, 0°6'48.24\\"W,　69°0'15.8040000000028\\"S，39°34'55.920000000001\\"E ), 0 )"} );
    $cmd->stdout_is_eq( qq{13787\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '2--10='} );
    $cmd->exit_is_num( 0, qq{./c '2--10='} );
    $cmd->stdout_is_eq( qq{12\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '2/-10='} );
    $cmd->exit_is_num( 0, qq{./c '2/-10='} );
    $cmd->stdout_is_eq( qq{-0.2\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '3+10%3='} );
    $cmd->exit_is_num( 0, qq{./c '3+10%3='} );
    $cmd->stdout_is_eq( qq{4\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '3+0xf*2='} );
    $cmd->exit_is_num( 0, qq{./c '3+0xf*2='} );
    $cmd->stdout_is_eq( qq{33 \[ = 0x21 \]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x0055**2-0XC-2='} );
    $cmd->exit_is_num( 0, qq{./c '0x0055**2-0XC-2='} );
    $cmd->stdout_is_eq( qq{7211 \[ = 0x1C2B \]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x9+0xc&0xe='} );
    $cmd->exit_is_num( 0, qq{./c '0x9+0xc&0xe='} );
    $cmd->stdout_is_eq( qq{4 \[ = 0x4 \]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x9&0xc+0xe='} );
    $cmd->exit_is_num( 0, qq{./c '0x9&0xc+0xe='} );
    $cmd->stdout_is_eq( qq{8 \[ = 0x8 \]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x9+0xc|0xe='} );
    $cmd->exit_is_num( 0, qq{./c '0x9+0xc|0xe='} );
    $cmd->stdout_is_eq( qq{31 \[ = 0x1F \]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x9|0xc+0xe='} );
    $cmd->exit_is_num( 0, qq{./c '0x9|0xc+0xe='} );
    $cmd->stdout_is_eq( qq{27 \[ = 0x1B \]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x1 ^ 0x2 ='} );
    $cmd->exit_is_num( 0, qq{./c '0x1 ^ 0x2 ='} );
    $cmd->stdout_is_eq( qq{3 [ = 0x3 ]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x3 ^ 0x2 ='} );
    $cmd->exit_is_num( 0, qq{./c '0x3 ^ 0x2 ='} );
    $cmd->stdout_is_eq( qq{1 [ = 0x1 ]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x3 ^ 0x3 ='} );
    $cmd->exit_is_num( 0, qq{./c '0x3 ^ 0x3 ='} );
    $cmd->stdout_is_eq( qq{0 [ = 0x0 ]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '5 ^ 3 ='} );
    $cmd->exit_is_num( 0, qq{./c '5 ^ 3 ='} );
    $cmd->stdout_is_eq( qq{6 [ = 0x6 ]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x6 << 1'} );
    $cmd->exit_is_num( 0, qq{./c '0x6 << 1'} );
    $cmd->stdout_is_eq( qq{12 [ = 0xC ]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x6 >> 1'} );
    $cmd->exit_is_num( 0, qq{./c '0x6 >> 1'} );
    $cmd->stdout_is_eq( qq{3 [ = 0x3 ]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    my $num_of_shifts = $UV_bit_width - 1;
    my $expect_L = qq{9223372036854775808 [ = -9223372036854775808 ] [ = 0x8000000000000000 ]};
    my $arg_R = 9223372036854775808;
    if( $UV_bit_width == 32 ){
        $expect_L = qq{2147483648 [ = -2147483648 ] [ = 0x80000000 ]};
        $arg_R = 2147483648;
    }

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1 << $num_of_shifts'} );
    $cmd->exit_is_num( 0, qq{./c '1 << $num_of_shifts'} );
    $cmd->stdout_is_eq( qq{$expect_L\n}, qq{UVの最大シフト数: $num_of_shifts} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '$arg_R >> $num_of_shifts'} );
    $cmd->exit_is_num( 0, qq{./c '$arg_R >> $num_of_shifts'} );
    $cmd->stdout_is_eq( qq{1 [ = 0x1 ]\n}, qq{UVの最大シフト数: $num_of_shifts} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '~1+1='} );
    $cmd->exit_is_num( 0, qq{./c '~1+1='} );
    my $expect = qq{18446744073709551615 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{4294967295 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
    }
    $cmd->stdout_is_eq( $expect );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1+~1='} );
    $cmd->exit_is_num( 0, qq{./c '1+~1='} );
    $expect = qq{18446744073709551615 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{4294967295 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
    }
    $cmd->stdout_is_eq( $expect );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '~1*2='} );
    $cmd->exit_is_num( 0, qq{./c '~1*2='} );
    $expect = qq{36893488147419103232 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{8589934588 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
    }
    $cmd->stdout_is_eq( $expect );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '2*~1='} );
    $cmd->exit_is_num( 0, qq{./c '2*~1='} );
    $expect = qq{36893488147419103232 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{8589934588 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
    }
    $cmd->stdout_is_eq( $expect );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '2' '~1='} );
    $cmd->exit_is_num( 0, qq{./c '2' '~1='} );
    $expect = qq{36893488147419103232 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{8589934588 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
    }
    $cmd->stdout_is_eq( $expect );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0xfc & 0x10  ~0x1 | 0x8 =' -v} );
    $cmd->exit_is_num( 0, qq{./c '0xfc & 0x10  ~0x1 | 0x8 =' -v} );
    $cmd->stdout_like( qr/\n    RPN: '252 16 1 ~ \* & 8 \|'\n/ );
    $cmd->stdout_like( qr/\n Result: 252 \[ = 0xFC \]\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 123,456-59 + '123.456((3-2)*1+1+(1-3/3))='} );
    $cmd->exit_is_num( 0, qq{./c 123,456-59 + '123.456((3-2)*1+1+(1-3/3))='} );
    $cmd->stdout_is_eq( qq{123643.912\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD （１９２０＊＊２＋１０８０＊＊２）＝} );
    $cmd->exit_is_num( 0, qq{./c （１９２０＊＊２＋１０８０＊＊２）＝} );
    $cmd->stdout_is_eq( qq{4852800\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '√(1920**2+1080**2)='} );
    $cmd->exit_is_num( 0, qq{./c '√(1920**2+1080**2)='} );
    $cmd->stdout_is_eq( qq{2202.9071700823\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '２π１０＝'} );
    $cmd->exit_is_num( 0, qq{./c '２π１０＝'} );
    $cmd->stdout_like( qr/^62\.831853071795[89]\n$/ );  ## 62.83185307179586476925286766559
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ＳＱＲＴ(1920**2+1080**2)='} );
    $cmd->exit_is_num( 0, qq{./c 'ＳＱＲＴ(1920**2+1080**2)='} );
    $cmd->stdout_is_eq( qq{2202.9071700823\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(power(1920,2)+power(1080,2))='} );
    $cmd->exit_is_num( 0, qq{./c 'sqrt(power(1920,2)+power(1080,2))='} );
    $cmd->stdout_is_eq( qq{2202.9071700823\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt( power( 1920, 2 ) + power( 1080, 2 ) ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'sqrt( power( 1920, 2 ) + power( 1080, 2 ) ) ='} );
    $cmd->stdout_is_eq( qq{2202.9071700823\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt( 1920 ** 2, 1080 ** 2 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'sqrt( 1920 ** 2, 1080 ** 2 ) ='} );
    $cmd->stdout_is_eq( qq{( 1920, 1080 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'hypot( 1920, 1080 )='} );
    $cmd->exit_is_num( 0, qq{./c 'hypot( 1920, 1080 )='} );
    $cmd->stdout_is_eq( qq{2202.9071700823\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'angle_deg( 1920, 1080 )='} );
    $cmd->exit_is_num( 0, qq{./c 'angle_deg( 1920, 1080 )='} );
    $cmd->stdout_is_eq( qq{29.3577535427913\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'angle_deg( 1920, 1080, 0 )='} );
    $cmd->exit_is_num( 0, qq{./c 'angle_deg( 1920, 1080, 0 )='} );
    $cmd->stdout_is_eq( qq{29.3577535427913\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'angle_deg( 1920, 1080, 1 )='} );
    $cmd->exit_is_num( 0, qq{./c 'angle_deg( 1920, 1080, 1 )='} );
    $cmd->stdout_is_eq( qq{60.6422464572087\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dist_between_points( -50, -50, 50, 50 )='} );
    $cmd->exit_is_num( 0, qq{./c 'dist_between_points( -50, -50, 50, 50 )='} );
    $cmd->stdout_is_eq( qq{141.42135623731\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dist_between_points( -50, -50, -50, 50, 50 )='} );
    $cmd->exit_isnt_num( 0, qq{./c 'dist_between_points( -50, -50, -50, 50, 50 )='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: dist_between_points: \$argc=5: Invalid number of arguments\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dist_between_points( -50, -50, -50, 50, 50, 50 )='} );
    $cmd->exit_is_num( 0, qq{./c 'dist_between_points( -50, -50, -50, 50, 50, 50 )='} );
    $cmd->stdout_is_eq( qq{173.205080756888\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'midpt_between_points( -50, -50, 50, 50 )='} );
    $cmd->exit_is_num( 0, qq{./c 'midpt_between_points( -50, -50, 50, 50 )='} );
    $cmd->stdout_is_eq( qq{( 0, 0 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'midpt_between_points( -50, -50, -50, 50, 50 )='} );
    $cmd->exit_isnt_num( 0, qq{./c 'midpt_between_points( -50, -50, -50, 50, 50 )='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: midpt_between_points: \$argc=5: Invalid number of arguments\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'midpt_between_points( -50, -50, -50, 50, 50, 50 )='} );
    $cmd->exit_is_num( 0, qq{./c 'midpt_between_points( -50, -50, -50, 50, 50, 50 )='} );
    $cmd->stdout_is_eq( qq{( 0, 0, 0 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'angle_between_points( -50, -50, 50, 75 )='} );
    $cmd->exit_is_num( 0, qq{./c 'angle_between_points( -50, -50, 50, 75 )='} );
    $cmd->stdout_is_eq( qq{51.3401917459099\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'angle_between_points( -50, -50, 50, 75, 0 )='} );
    $cmd->exit_is_num( 0, qq{./c 'angle_between_points( -50, -50, 50, 75, 0 )='} );
    $cmd->stdout_is_eq( qq{51.3401917459099\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'angle_between_points( -50, -50, 50, 75, 1 )='} );
    $cmd->exit_is_num( 0, qq{./c 'angle_between_points( -50, -50, 50, 75, 1 )='} );
    $cmd->stdout_is_eq( qq{38.6598082540901\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'angle_between_points( -50, -50, -50, 50, 75, 50 )='} );
    $cmd->exit_is_num( 0, qq{./c 'angle_between_points( -50, -50, -50, 50, 75, 50 )='} );
    $cmd->stdout_is_eq( qq{( 51.3401917459099, 31.9928170001817 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'angle_between_points( -50, -50, -50, 50, 75, 50, 0 )='} );
    $cmd->exit_is_num( 0, qq{./c 'angle_between_points( -50, -50, -50, 50, 75, 50, 0 )='} );
    $cmd->stdout_is_eq( qq{( 51.3401917459099, 31.9928170001817 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'angle_between_points( -50, -50, -50, 50, 75, 50, 1 )='} );
    $cmd->exit_is_num( 0, qq{./c 'angle_between_points( -50, -50, -50, 50, 75, 50, 1 )='} );
    $cmd->stdout_is_eq( qq{( 38.6598082540901, 31.9928170001817 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(power(2, 100)+power(2, 100))='} );
    $cmd->exit_is_num( 0, qq{./c 'sqrt(power(2, 100)+power(2, 100))='} );
    $cmd->stdout_is_eq( qq{1592262918131443.25\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'power(2+1,2*2)='} );
    $cmd->exit_is_num( 0, qq{./c 'power(2+1,2*2)='} );
    $cmd->stdout_is_eq( qq{81\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'power(6/2,power(2,1)*2)='} );
    $cmd->exit_is_num( 0, qq{./c 'power(6/2,power(2,1)*2)='} );
    $cmd->stdout_is_eq( qq{81\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'power(-1+2**2,power(2,1)*2)='} );
    $cmd->exit_is_num( 0, qq{./c 'power(-1+2**2,power(2,1)*2)='} );
    $cmd->stdout_is_eq( qq{81\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'power(1+sqrt(4),power(2,1)*2)='} );
    $cmd->exit_is_num( 0, qq{./c 'power(1+sqrt(4),power(2,1)*2)='} );
    $cmd->stdout_is_eq( qq{81\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0.22*10**(-6)='} );
    $cmd->exit_is_num( 0, qq{./c '0.22*10**(-6)='} );
    $cmd->stdout_is_eq( qq{0.00000022\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ｄｅｇ２ｒａｄ（１８０）＝'} );
    $cmd->exit_is_num( 0, qq{./c 'ｄｅｇ２ｒａｄ（１８０）＝'} );
    $cmd->stdout_is_eq( qq{3.14159265358979\n} );       ## 3.1415926535897932384626433832795
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ｒａｄ２ｄｅｇ（ｐｉ／２）＝'} );
    $cmd->exit_is_num( 0, qq{./c 'ｒａｄ２ｄｅｇ（ｐｉ／２）＝'} );
    $cmd->stdout_is_eq( qq{90\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1/cos(deg2rad(45))='} );
    $cmd->exit_is_num( 0, qq{./c '1/cos(deg2rad(45))='} );
    $cmd->stdout_is_eq( qq{1.41421356237309\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '１' 'cos(deg2rad(45))'} );
    $cmd->exit_is_num( 0, qq{./c '１' 'cos(deg2rad(45))'} );
    $cmd->stdout_is_eq( qq{0.707106781186548\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1080/sin(deg2rad(45))='} );
    $cmd->exit_is_num( 0, qq{./c '1080/sin(deg2rad(45))='} );
    $cmd->stdout_is_eq( qq{1527.35064736294\n} );       ## 1527.3506473629426527058238221465
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rad2deg(asin(1080/1527.3506473629426527058238221465))='} );
    $cmd->exit_is_num( 0, qq{./c 'rad2deg(asin(1080/1527.3506473629426527058238221465))='} );
    $cmd->stdout_is_eq( qq{45\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1920/cos(deg2rad(45))='} );
    $cmd->exit_is_num( 0, qq{./c '1920/cos(deg2rad(45))='} );
    $cmd->stdout_is_eq( qq{2715.29003975634\n} );       ## 2715.2900397563424936992423504826
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rad2deg(acos(1920/2715.2900397563424936992423504826))='} );
    $cmd->exit_is_num( 0, qq{./c 'rad2deg(acos(1920/2715.2900397563424936992423504826))='} );
    $cmd->stdout_is_eq( qq{45\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rad2deg(atan(1080/1920))='} );
    $cmd->exit_is_num( 0, qq{./c 'rad2deg(atan(1080/1920))='} );
    $cmd->stdout_is_eq( qq{29.3577535427913\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rad2deg( 2.26892802759263, 2.0943951023932 )'} );
    $cmd->exit_is_num( 0, qq{./c 'rad2deg( 2.26892802759263, 2.0943951023932 )'} );
    $cmd->stdout_is_eq( qq{( 130, 120 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1920*tan(deg2rad(29.3577535427913))='} );
    $cmd->exit_is_num( 0, qq{./c '1920*tan(deg2rad(29.3577535427913))='} );
    $cmd->stdout_is_eq( qq{1080\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    ## 大阪駅座標：北緯34度42分6.8秒 東経135度29分41.9秒
    ##             度分秒 34° 42′ 6.8″ N, 135° 29′ 41.9″ E
    ##             十進数 34.701889, 135.494972
    ## 北緯は+，東経も+。もし南緯なら-，西経なら-。
    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2deg( 34, 42, 6.8 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2deg( 34, 42, 6.8 )'} );
    $cmd->stdout_is_eq( qq{34.7018888888889\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2deg( 135, 29, 41.9 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2deg( 135, 29, 41.9 )'} );
    $cmd->stdout_is_eq( qq{135.494972222222\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    ## 東京駅座標：北緯35度40分52秒 東経139度46分0秒
    ##             度分秒 35° 40′ 52″ N, 139° 46′ 0″ E
    ##             十進数 35.681111, 139.766667
    ## 北緯は+，東経も+。もし南緯なら-，西経なら-。
    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2deg( 35, 40, 52 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2deg( 35, 40, 52 )'} );
    $cmd->stdout_is_eq( qq{35.6811111111111\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2deg( 139, 46, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2deg( 139, 46, 0 )'} );
    $cmd->stdout_is_eq( qq{139.766666666667\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    ## Galapagos Islands: degrees: -0.3831, -90.42333
    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2deg( -0, -22, -59.16 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2deg( -0, -22, -59.16 )'} );
    $cmd->stdout_is_eq( qq{-0.3831\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2deg( -90, -25, -23.9880000000255 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2deg( -90, -25, -23.9880000000255 )'} );
    $cmd->stdout_is_eq( qq{-90.42333\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2deg( 35, 40, 52, 139, 46, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2deg( 35, 40, 52, 139, 46, 0 )'} );
    $cmd->stdout_is_eq( qq{( 35.6811111111111, 139.766666666667 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    ## 大阪駅
    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( 34, 42, 6.8 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2rad( 34, 42, 6.8 )'} );
    $cmd->stdout_is_eq( qq{0.605662217772348\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( 135, 29, 41.9 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2rad( 135, 29, 41.9 )'} );
    $cmd->stdout_is_eq( qq{2.36483338517604\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    ## 東京駅
    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( 35, 40, 52 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2rad( 35, 40, 52 )'} );
    $cmd->stdout_is_eq( qq{0.622752869658821\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( 139, 46, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2rad( 139, 46, 0 )'} );
    $cmd->stdout_is_eq( qq{2.43938851787074\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    ## 大阪駅 → 東京駅
    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( 35, 40, 52 ) - dms2rad( 34, 42, 6.8 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2rad( 35, 40, 52 ) - dms2rad( 34, 42, 6.8 )'} );
    $cmd->stdout_is_eq( qq{0.0170906518864732\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( 139, 46, 0 ) - dms2rad( 135, 29, 41.9 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2rad( 139, 46, 0 ) - dms2rad( 135, 29, 41.9 )'} );
    $cmd->stdout_is_eq( qq{0.074555132694706\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    ## Galapagos Islands: degrees: -0.3831, -90.42333
    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( -0, -22, -59.16 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2rad( -0, -22, -59.16 )'} );
    $cmd->stdout_is_eq( qq{-0.00668635636439028\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( -90, -25, -23.9880000000255 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2rad( -90, -25, -23.9880000000255 )'} );
    $cmd->stdout_is_eq( qq{-1.57818482911736\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( -90, -25.399800000000425, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2rad( -90, -25.399800000000425, 0 )'} );
    $cmd->stdout_is_eq( qq{-1.57818482911736\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( -90.42333, 0, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2rad( -90.42333, 0, 0 )'} );
    $cmd->stdout_is_eq( qq{-1.57818482911736\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( -90, -25, -23.9880000000255, -90, -25, -23.9880000000255 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2rad( -90, -25, -23.9880000000255, -90, -25, -23.9880000000255 )'} );
    $cmd->stdout_is_eq( qq{( -1.57818482911736, -1.57818482911736 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( -90, -25, -23.9880000000255, -90, -25 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'dms2rad( -90, -25, -23.9880000000255, -90, -25 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: dms2rad: \$arg_counter="5": Not a multiple of 3\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2rad( -90, -25 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'dms2rad( -90, -25 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: "dms2rad": Operand missing\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1 + ( 2 + ( 3 + dms2rad( -90, -25 ) ) )'} );
    $cmd->exit_isnt_num( 0, qq{./c '1 + ( 2 + ( 3 + dms2rad( -90, -25 ) ) )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: dms2rad: \$arg_counter="2": Not a multiple of 3\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'deg2dms( -18.76694 )'} );
    $cmd->exit_is_num( 0, qq{./c 'deg2dms( -18.76694 )'} );
    $cmd->stdout_is_eq( qq{( -18, -46, -0.984000000006233 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'deg2dms( 46.8691 )'} );
    $cmd->exit_is_num( 0, qq{./c 'deg2dms( 46.8691 )'} );
    $cmd->stdout_is_eq( qq{( 46, 52, 8.76000000001113 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'deg2dms( dms2deg( -18, -46.01640000000010388333333333333333, -0 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'deg2dms( dms2deg( -18, -46.01640000000010388333333333333333, -0 ) )'} );
    $cmd->stdout_is_eq( qq{( -18, -46, -0.984000000006233 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'deg2dms( dms2deg( 46, 52.1460000000001855, 0 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'deg2dms( dms2deg( 46, 52.1460000000001855, 0 ) )'} );
    $cmd->stdout_is_eq( qq{( 46, 52, 8.76000000001113 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'deg2dms( -0.3831 )'} );
    $cmd->exit_is_num( 0, qq{./c 'deg2dms( -0.3831 )'} );
    $cmd->stdout_is_eq( qq{( -0, -22, -59.16 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2deg( deg2dms( -0.3831 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2deg( deg2dms( -0.3831 ) )'} );
    $cmd->stdout_is_eq( qq{-0.3831\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'deg2dms( 0.3831 )'} );
    $cmd->exit_is_num( 0, qq{./c 'deg2dms( 0.3831 )'} );
    $cmd->stdout_is_eq( qq{( 0, 22, 59.16 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2deg( deg2dms( 0.3831 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2deg( deg2dms( 0.3831 ) )'} );
    $cmd->stdout_is_eq( qq{0.3831\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'deg2dms( 40.6983333333333, 143.595 )'} );
    $cmd->exit_is_num( 0, qq{./c 'deg2dms( 40.6983333333333, 143.595 )'} );
    $cmd->stdout_is_eq( qq{( 40, 41, 53.9999999998878, 143, 35, 41.9999999999959 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2dms( -0.3831, 0, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2dms( -0.3831, 0, 0 )'} );
    $cmd->stdout_is_eq( qq{( -0, -22, -59.16 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dms2dms( 0.3831, 0, 0, -69.00439, 0, 0, 39.5822, 0, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dms2dms( 0.3831, 0, 0, -69.00439, 0, 0, 39.5822, 0, 0 )'} );
    $cmd->stdout_is_eq( qq{( 0, 22, 59.16, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_radius( deg2rad( 0 ) ) / 1000 ='} );
    $cmd->exit_is_num( 0, qq{./c 'geo_radius( deg2rad( 0 ) ) / 1000 ='} );
    $cmd->stdout_is_eq( qq{6378.137\n}, qq{地球の赤道半径（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_radius( deg2rad( 35.68129 ) ) / 1000 ='} );
    $cmd->exit_is_num( 0, qq{./c 'geo_radius( deg2rad( 35.68129 ) ) / 1000 ='} );
    $cmd->stdout_is_eq( qq{6370.9019434243\n}, qq{地球が楕円である事を考慮して地球の中心から東京駅（地表）までの距離（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'radius_of_lat( deg2rad( 35.68129 ) ) / 1000 ='} );
    $cmd->exit_is_num( 0, qq{./c 'radius_of_lat( deg2rad( 35.68129 ) ) / 1000 ='} );
    $cmd->stdout_is_eq( qq{5186.70483557997\n}, qq{地球が楕円である事を考慮して東京駅を通る緯線の半径（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance_m( deg2rad( 35.68129 ), deg2rad( 139.76706 ), deg2rad( 34.70248 ), deg2rad( 135.49595 ) ) / 1000'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance_m( deg2rad( 35.68129 ), deg2rad( 139.76706 ), deg2rad( 34.70248 ), deg2rad( 135.49595 ) ) / 1000'} );
    $cmd->stdout_like( qr/^403\.862905334285\n/, qq{東京駅から大阪駅までの距離（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance_m( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) ) / 1000'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance_m( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) ) / 1000'} );
    $cmd->stdout_is_eq( qq{14075.6175288926\n}, qq{東京駅から昭和基地までの距離（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance_km( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance_km( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->stdout_is_eq( qq{14075.6175288926\n}, qq{東京駅から昭和基地までの距離（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance_km( deg2rad( -69.00439, 39.5822, -77.3169444444444, 39.7033333333333 ), 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance_km( deg2rad( -69.00439, 39.5822, -77.3169444444444, 39.7033333333333 ), 1 )'} );
    $cmd->stdout_is_eq( qq{924.322901757007\n}, qq{昭和基地からドームふじ基地までの距離（km）, ハバーサイン (Haversine) 公式} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance_km( deg2rad( -69.00439, 39.5822, -77.3169444444444, 39.7033333333333 ), 2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance_km( deg2rad( -69.00439, 39.5822, -77.3169444444444, 39.7033333333333 ), 2 )'} );
    $cmd->stdout_is_eq( qq{927.683443441365\n}, qq{昭和基地からドームふじ基地までの距離（km）, ヒュベニ (Hubeny) の公式} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_azimuth( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_azimuth( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->stdout_is_eq( qq{206.051582912837\n}, qq{東京駅から昭和基地までの方角（度）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_dist_m_and_azimuth( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_dist_m_and_azimuth( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->stdout_is_eq( qq{( 14075617.5288926, 206.051582912837 )\n}, qq{東京駅から昭和基地までの距離（m）と方角（度）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_dist_km_and_azimuth( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_dist_km_and_azimuth( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->stdout_is_eq( qq{( 14075.6175288926, 206.051582912837 )\n}, qq{東京駅から昭和基地までの距離（km）と方角（度）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'epoch2local( 1763999942 )'} );
    $cmd->exit_is_num( 0, qq{./c 'epoch2local( 1763999942 )'} );
    $cmd->stdout_is_eq( qq{( 2025, 11, 25, 0, 59, 2 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'epoch2gmt( 1763999942 )'} );
    $cmd->exit_is_num( 0, qq{./c 'epoch2gmt( 1763999942 )'} );
    $cmd->stdout_is_eq( qq{( 2025, 11, 24, 15, 59, 2 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'is_leap( 1996 )'} );
    $cmd->exit_is_num( 0, qq{./c 'is_leap( 1996 )'} );
    $cmd->stdout_is_eq( qq{1\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'is_leap( 1999 )'} );
    $cmd->exit_is_num( 0, qq{./c 'is_leap( 1999 )'} );
    $cmd->stdout_is_eq( qq{0\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'is_leap( 2000 )'} );
    $cmd->exit_is_num( 0, qq{./c 'is_leap( 2000 )'} );
    $cmd->stdout_is_eq( qq{1\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'is_leap( 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000, 2100 )'} );
    $cmd->exit_is_num( 0, qq{./c 'is_leap( 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000, 2100 )'} );
    $cmd->stdout_is_eq( qq{( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'age_of_moon( 2025, 12, 13 )'} );
    $cmd->exit_is_num( 0, qq{./c 'age_of_moon( 2025, 12, 13 )'} );
    $cmd->stdout_is_eq( qq{23\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'age_of_moon( 2025, 12, 19 )'} );
    $cmd->exit_is_num( 0, qq{./c 'age_of_moon( 2025, 12, 19 )'} );
    $cmd->stdout_is_eq( qq{29\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'age_of_moon( 2025, 12, 20 )'} );
    $cmd->exit_is_num( 0, qq{./c 'age_of_moon( 2025, 12, 20 )'} );
    $cmd->stdout_is_eq( qq{0\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'local2epoch( 2000, 12, 31, 23, 59, 59 )'} );
    $cmd->exit_is_num( 0, qq{./c 'local2epoch( 2000, 12, 31, 23, 59, 59 )'} );
    $cmd->stdout_is_eq( qq{978274799\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gmt2epoch( 2000, 12, 31, 23, 59, 59 )'} );
    $cmd->exit_is_num( 0, qq{./c 'gmt2epoch( 2000, 12, 31, 23, 59, 59 )'} );
    $cmd->stdout_is_eq( qq{978307199\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sec2dhms( local2epoch( 2030, 1, 1 ) - now )'} );
    $cmd->exit_is_num( 0, qq{./c 'sec2dhms( local2epoch( 2030, 1, 1 ) - now )'} );
    $cmd->stdout_like( qr/^\( \d+, \d+, \d+, \d+ \)\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sec2dhms( gmt2epoch( 2020, 1, 1 ) - now )'} );
    $cmd->exit_is_num( 0, qq{./c 'sec2dhms( local2epoch( 2020, 1, 1 ) - now )'} );
    $cmd->stdout_like( qr/^\( \-\d+, \-?\d+, \-?\d+, \-?\d+ \)\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sec2dhms( 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'sec2dhms( 0 )'} );
    $cmd->stdout_is_eq( qq{( 0, 0, 0, 0 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'epoch2local( local2epoch( 2020, 1, 1, 15, 0, 0 ) + dhms2sec( 10 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'epoch2local( local2epoch( 2020, 1, 1, 15, 0, 0 ) + dhms2sec( 10 ) )'} );
    $cmd->stdout_is_eq( qq{( 2020, 1, 11, 15, 0, 0 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'epoch2local( local2epoch( 2020, 1, 1, 15, 0, 0 ) + dhms2sec( -2, 3, -4, 5 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'epoch2local( local2epoch( 2020, 1, 1, 15, 0, 0 ) + dhms2sec( -2, 3, -4, 5 ) )'} );
    $cmd->stdout_is_eq( qq{( 2019, 12, 30, 17, 56, 5 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ri2meter( 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'ri2meter( 1 )'} );
    $cmd->stdout_is_eq( qq{3927.2727272727\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'meter2ri( 4000 )'} );
    $cmd->exit_is_num( 0, qq{./c 'meter2ri( 4000 )'} );
    $cmd->stdout_is_eq( qq{1.01851851851853\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'mile2meter( 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'mile2meter( 1 )'} );
    $cmd->stdout_is_eq( qq{1609.344\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'meter2mile( 2000 )'} );
    $cmd->exit_is_num( 0, qq{./c 'meter2mile( 2000 )'} );
    $cmd->stdout_is_eq( qq{1.24274238447467\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'nautical_mile2meter( 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'nautical_mile2meter( 1 )'} );
    $cmd->stdout_is_eq( qq{1852\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'meter2nautical_mile( 2000 )'} );
    $cmd->exit_is_num( 0, qq{./c 'meter2nautical_mile( 2000 )'} );
    $cmd->stdout_is_eq( qq{1.07991360691145\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pound2gram( 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'pound2gram( 1 )'} );
    $cmd->stdout_is_eq( qq{453.59237\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gram2pound( 500 )'} );
    $cmd->exit_is_num( 0, qq{./c 'gram2pound( 500 )'} );
    $cmd->stdout_is_eq( qq{1.10231131092439\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ounce2gram( 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'ounce2gram( 1 )'} );
    $cmd->stdout_is_eq( qq{28.349523125\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gram2ounce( 30 )'} );
    $cmd->exit_is_num( 0, qq{./c 'gram2ounce( 30 )'} );
    $cmd->stdout_is_eq( qq{1.05821885848741\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'laptimer( 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'laptimer( 0 )'} );
    $cmd->stdout_is_eq( qq{0\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '' | $TARGCMD 'laptimer( 1 )'} );
    $cmd->exit_is_num( 0, qq{echo '' | ./c 'laptimer( 1 )'} );
    $cmd->stdout_like( qr/^Elaps         Date\-Time\n/ );
    $cmd->stdout_like( qr/\n0\./ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{printf "\n\n" | $TARGCMD 'laptimer( 2 )'} );
    $cmd->exit_is_num( 0, qq{printf "\n\n" | ./c 'laptimer( 2 )'} );
    $cmd->stdout_like( qr/^Lap  Split\-Time    Lap\-Time      Date\-Time\n/ );
    $cmd->stdout_like( qr/\r2\/2  00:00:00\./ );
    $cmd->stdout_like( qr/\n0\./ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{printf "\nq\n" | $TARGCMD 'laptimer( 10 )'} );
    $cmd->exit_is_num( 0, qq{printf "\nq\n" | ./c 'laptimer( 10 )'} );
    $cmd->stdout_like( qr/^Lap    Split\-Time    Lap\-Time      Date\-Time\n/ );
    $cmd->stdout_like( qr/\r 2\/10  00:00:00\./ );
    $cmd->stdout_like( qr/\n0\./ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '' | $TARGCMD 'timer( local2epoch( 2025, 1, 1  ) )'} );
    $cmd->exit_is_num( 0, qq{echo '' | ./c 'timer( local2epoch( 2025, 1, 1  ) )'} );
    $cmd->stdout_like( qr/^2025\-01\-01 00:00:00\.000  TARGET\n/ );
    $cmd->stdout_like( qr/\n\d+\.\d+\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '' | $TARGCMD 'timer( 3 )'} );
    $cmd->exit_is_num( 0, qq{echo '' | ./c 'timer( 3 )'} );
    $cmd->stdout_like( qr/^20\d{2}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}  TARGET\n/ );
    $cmd->stdout_like( qr/\n\-\d+\.\d+\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'timer( 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'timer( 1 )'} );
    $cmd->stdout_like( qr/^20\d{2}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}  TARGET\n/ );
    $cmd->stdout_like( qr/\n\d+\.\d+\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '' | $TARGCMD 'stopwatch()'} );
    $cmd->exit_is_num( 0, qq{echo '' | ./c 'stopwatch()'} );
    $cmd->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $cmd->stdout_like( qr/\n0\./ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '' | $TARGCMD 'bpm( 10, stopwatch() )'} );
    $cmd->exit_is_num( 0, qq{echo '' | ./c 'bpm( 10, stopwatch() )'} );
    $cmd->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $cmd->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '' | $TARGCMD 'bpm15()'} );
    $cmd->exit_is_num( 0, qq{echo '' | ./c 'bpm15()'} );
    $cmd->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $cmd->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '' | $TARGCMD 'bpm30()'} );
    $cmd->exit_is_num( 0, qq{echo '' | ./c 'bpm30()'} );
    $cmd->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $cmd->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '' | $TARGCMD 'tachymeter( stopwatch() )'} );
    $cmd->exit_is_num( 0, qq{echo '' | ./c 'tachymeter( stopwatch() )'} );
    $cmd->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $cmd->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '' | $TARGCMD 'telemeter( stopwatch() )'} );
    $cmd->exit_is_num( 0, qq{echo '' | ./c 'telemeter( stopwatch() )'} );
    $cmd->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $cmd->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'telemeter_m( 8 )'} );
    $cmd->exit_is_num( 0, qq{./c 'telemeter_m( 8 )'} );
    $cmd->stdout_is_eq( qq{2720\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'telemeter_km( 8 )'} );
    $cmd->exit_is_num( 0, qq{./c 'telemeter_km( 8 )'} );
    $cmd->stdout_is_eq( qq{2.72\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'exp( -2.3 )'} );
    $cmd->exit_is_num( 0, qq{./c 'exp( -2.3 )'} );
    $cmd->stdout_is_eq( qq{0.100258843722804\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'exp( -2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'exp( -2 )'} );
    $cmd->stdout_is_eq( qq{0.135335283236613\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'exp( -1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'exp( -1 )'} );
    $cmd->stdout_is_eq( qq{0.367879441171442\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'exp( 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'exp( 0 )'} );
    $cmd->stdout_is_eq( qq{1\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'exp( 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'exp( 1 )'} );
    $cmd->stdout_is_eq( qq{2.71828182845905\n}, qq{Napier's number} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'exp( 2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'exp( 2 )'} );
    $cmd->stdout_is_eq( qq{7.38905609893065\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'exp( 2.3 )'} );
    $cmd->exit_is_num( 0, qq{./c 'exp( 2.3 )'} );
    $cmd->stdout_is_eq( qq{9.97418245481472\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'exp( -1, 0, 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'exp( -1, 0, 1 )'} );
    $cmd->stdout_is_eq( qq{( 0.367879441171442, 1, 2.71828182845905 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log(3)='} );
    $cmd->exit_is_num( 0, qq{./c 'log(3)='} );
    $cmd->stdout_is_eq( qq{1.09861228866811\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log( -123.456 ) ='} );
    $cmd->exit_isnt_num( 0, qq{./c 'log( -123.456 ) ='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: log\( -123.456 \): Must be a positive number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log(0)/log(2)='} );
    $cmd->exit_isnt_num( 0, qq{./c 'log(0)/log(2)='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: log\( 0 \): Must be a positive number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log(~0+1)/log(2)='} );
    $cmd->exit_is_num( 0, qq{./c 'log(~0+1)/log(2)='} );
    $expect = qq{64 [ = 0x40 ]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{32 [ = 0x20 ]\n};
    }
    $cmd->stdout_is_eq( $expect, qq{${UV_bit_width}bit: perlの整数は固定幅ではないが基本は64bitが多いはず。} );
    $cmd->stderr_is_eq( qq{}, qq{"~0+1": perlの整数は固定幅ではないので桁溢れしない。} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log( 10, 100, 1000 )'} );
    $cmd->exit_is_num( 0, qq{./c 'log( 10, 100, 1000 )'} );
    $cmd->stdout_is_eq( qq{( 2.30258509299405, 4.60517018598809, 6.90775527898214 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'exp2( 10 )'} );
    $cmd->exit_is_num( 0, qq{./c 'exp2( 10 )'} );
    $cmd->stdout_is_eq( qq{1024\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'exp2( 8, 16, 32 )'} );
    $cmd->exit_is_num( 0, qq{./c 'exp2( 8, 16, 32 )'} );
    $cmd->stdout_is_eq( qq{( 256, 65536, 4294967296 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log2( -123.456 ) ='} );
    $cmd->exit_isnt_num( 0, qq{./c 'log2( -123.456 ) ='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: log2\( -123.456 \): Must be a positive number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log2(0)='} );
    $cmd->exit_isnt_num( 0, qq{./c 'log2(0)='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: log2\( 0 \): Must be a positive number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log2( 4294967296 )'} );
    $cmd->exit_is_num( 0, qq{./c 'log2( 4294967296 )'} );
    $cmd->stdout_is_eq( qq{32\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log2( 256, 65536, 4294967296 )'} );
    $cmd->exit_is_num( 0, qq{./c 'log2( 256, 65536, 4294967296 )'} );
    $cmd->stdout_is_eq( qq{( 8, 16, 32 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'exp10( 5 )'} );
    $cmd->exit_is_num( 0, qq{./c 'exp10( 5 )'} );
    $cmd->stdout_is_eq( qq{100000\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'exp10( 1, 2, 3 )'} );
    $cmd->exit_is_num( 0, qq{./c 'exp10( 1, 2, 3 )'} );
    $cmd->stdout_is_eq( qq{( 10, 100, 1000 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log10( -123.456 ) ='} );
    $cmd->exit_isnt_num( 0, qq{./c 'log10( -123.456 ) ='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: log10\( -123.456 \): Must be a positive number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log10(0)='} );
    $cmd->exit_isnt_num( 0, qq{./c 'log10(0)='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: log10\( 0 \): Must be a positive number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log10( 4294967296 )'} );
    $cmd->exit_is_num( 0, qq{./c 'log10( 4294967296 )'} );
    $cmd->stdout_is_eq( qq{9.6329598612474\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log10( 10, 100, 1000 )'} );
    $cmd->exit_is_num( 0, qq{./c 'log10( 10, 100, 1000 )'} );
    $cmd->stdout_is_eq( qq{( 1, 2, 3 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pow_inv( ~0+1, 2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'pow_inv( ~0+1, 2 )'} );
    $expect = qq{64 [ = 0x40 ]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{32 [ = 0x20 ]\n};
    }
    $cmd->stdout_is_eq( $expect, qq{${UV_bit_width}bit: perlの整数は固定幅ではないが基本は64bitが多いはず。} );
    $cmd->stderr_is_eq( qq{}, qq{"~0+1": perlの整数は固定幅ではないので桁溢れしない。} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linstep( ~0, -1, 2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linstep( ~0, -1, 2 )'} );
    $expect = qq{( 18446744073709551615, 18446744073709551614 ) [ = ( -1, -2 ) ] [ = ( 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFE ) ]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{( 4294967295, 4294967294 ) [ = ( -1, -2 ) ] [ = ( 0xFFFFFFFF, 0xFFFFFFFE ) ]\n};
    }
    $cmd->stdout_is_eq( $expect );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pow_inv( 4294967296, 2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'pow_inv( 4294967296, 2 )'} );
    $cmd->stdout_is_eq( qq{32\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pow_inv( 4294967297, 2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'pow_inv( 4294967297, 2 )'} );
    $cmd->stdout_is_eq( qq{32.0000000003359\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '2PI10='} );
    $cmd->exit_is_num( 0, qq{./c '2PI10='} );
    $cmd->stdout_like( qr/^62\.831853071795[89]\n$/ );  ## 62.83185307179586476925286766559
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '2･PI･10='} );
    $cmd->exit_is_num( 0, qq{./c '2PI10='} );
    $cmd->stdout_like( qr/^62\.831853071795[89]\n$/ );  ## 62.83185307179586476925286766559
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '２・ＰＩ・１０＝'} );
    $cmd->exit_is_num( 0, qq{./c '2PI10='} );
    $cmd->stdout_like( qr/^62\.831853071795[89]\n$/ );  ## 62.83185307179586476925286766559
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '2PI10'} );
    $cmd->exit_is_num( 0, qq{./c '2PI10'} );
    $cmd->stdout_like( qr/^62\.831853071795[89]\n$/ );  ## 62.83185307179586476925286766559
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD ' ' '2PI10='} );
    $cmd->exit_is_num( 0, qq{./c ' ' '2PI10='} );
    $cmd->stdout_like( qr/^62\.831853071795[89]\n$/ );  ## 62.83185307179586476925286766559
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '2PI10=' ' '} );
    $cmd->exit_is_num( 0, qq{./c '2PI10=' ' '} );
    $cmd->stdout_like( qr/^62\.831853071795[89]\n$/ );  ## 62.83185307179586476925286766559
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '2PI10=' ' ' -d} );
    $cmd->exit_is_num( 0, qq{./c '2PI10=' ' ' -d} );
    $cmd->stdout_like( qr/\n Result: 62\.831853071795[89]\n$/ );  ## 62.83185307179586476925286766559
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD ')(='} );
    $cmd->exit_isnt_num( 0, qq{./c ')(='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: parser: error: "BEGIN", "\)": Wrong combination\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '123' '2(='} );
    $cmd->exit_isnt_num( 0, qq{./c '123' '2(='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: parser: error: The position of the "\)" is incorrect\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '123' '2(2='} );
    $cmd->exit_isnt_num( 0, qq{./c '123' '2(2='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: parser: error: The position of the "\)" is incorrect\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '15/5='} );
    $cmd->exit_is_num( 0, qq{./c '15/5='} );
    $cmd->stdout_is_eq( qq{3\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '5/0='} );
    $cmd->exit_isnt_num( 0, qq{./c '5/0='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: "5 \/ 0": Illegal division by zero\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '5%-1.0='} );
    $cmd->exit_is_num( 0, qq{./c '5%-1.0='} );
    $cmd->stdout_is_eq( qq{0\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '5%-0.9='} );
    $cmd->exit_isnt_num( 0, qq{./c '5%-0.9='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: "5 % \-0.9": Illegal modulus operand\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '5%0='} );
    $cmd->exit_is_num( 0, qq{./c '5%0='} );
    $cmd->stdout_is_eq( qq{5\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '5%0.9='} );
    $cmd->exit_isnt_num( 0, qq{./c '5%0.9='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: "5 % 0.9": Illegal modulus operand\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '5%1.0='} );
    $cmd->exit_is_num( 0, qq{./c '5%1.0='} );
    $cmd->stdout_is_eq( qq{0\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '12(3' '2)2='} );
    $cmd->exit_is_num( 0, qq{./c '12(3' '2)2='} );
    $cmd->stdout_is_eq( qq{144\n}, qq{-10} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '12(3 2)2='} );
    $cmd->exit_is_num( 0, qq{./c '12(3 2)2='} );
    $cmd->stdout_is_eq( qq{144\n}, qq{-10} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '2 3 4 ='} );
    $cmd->exit_is_num( 0, qq{./c '2 3 4 ='} );
    $cmd->stdout_is_eq( qq{24\n}, qq{-10} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '-10='} );
    $cmd->exit_is_num( 0, qq{./c '-10='} );
    $cmd->stdout_is_eq( qq{-10\n}, qq{-10} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '='} );
    $cmd->exit_is_num( 0, qq{./c '='} );
    $cmd->stdout_is_eq( qq{0\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'testfunc(10)='} );
    $cmd->exit_isnt_num( 0, qq{./c 'testfunc(10)='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
#    $cmd->stderr_like( qr/^c: error: "testfunc": The function is not defined\.\n/ );
    $cmd->stderr_is_eq( qq{c: parser: error: "testfunc": There is a problem with the calculation formula.\n} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'unknownfunc(10)='} );
    $cmd->exit_isnt_num( 0, qq{./c 'unknownfunc(10)='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: lexer: error: "unknownfunc\(\)": unknown function\.\n/ );
    $cmd->stderr_like( qr/\nc: lexer: info: Supported functions: / );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rad2deg(atan2(100, 200='} );
    $cmd->exit_is_num( 0, qq{./c 'rad2deg(atan2(100, 200='} );
    $cmd->stdout_is_eq( qq{26.565051177078\n} );
    $cmd->stderr_like( qr/^c: parser: warn: "atan2\(": "\)" may be incorrect\.\n/ );
    $cmd->stderr_like( qr/\nc: parser: warn: "rad2deg\(": "\)" may be incorrect\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rad2deg(atan2(100, 200)='} );
    $cmd->exit_is_num( 0, qq{./c 'rad2deg(atan2(100, 200)='} );
    $cmd->stdout_is_eq( qq{26.565051177078\n} );
    $cmd->stderr_unlike( qr/^c: parser: warn: "atan2\(": "\)" may be incorrect\.\n/ );
    $cmd->stderr_like( qr/^c: parser: warn: "rad2deg\(": "\)" may be incorrect\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rad2deg(atan2(100, 200))='} );
    $cmd->exit_is_num( 0, qq{./c 'rad2deg(atan2(100, 200))='} );
    $cmd->stdout_is_eq( qq{26.565051177078\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'abs(-29.3577535427913)='} );
    $cmd->exit_is_num( 0, qq{./c 'abs(-29.3577535427913)='} );
    $cmd->stdout_is_eq( qq{29.3577535427913\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '( abs( -1.2, 1.2 ) )'} );
    $cmd->exit_is_num( 0, qq{./c '( abs( -1.2, 1.2 ) )'} );
    $cmd->stdout_is_eq( qq{( 1.2, 1.2 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'int(10/3*100+0.5)/100='} );
    $cmd->exit_is_num( 0, qq{./c 'int(10/3*100+0.5)/100='} );
    $cmd->stdout_is_eq( qq{3.33\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '( int( -1.2, 1.2 ) )'} );
    $cmd->exit_is_num( 0, qq{./c '( int( -1.2, 1.2 ) )'} );
    $cmd->stdout_is_eq( qq{( -1, 1 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'floor( 192.168 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'floor( 192.168 ) ='} );
    $cmd->stdout_is_eq( qq{192\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'floor( -192.168 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'floor( -192.168 ) ='} );
    $cmd->stdout_is_eq( qq{-193\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '( floor( -1.2, 1.2 ) )'} );
    $cmd->exit_is_num( 0, qq{./c '( floor( -1.2, 1.2 ) )'} );
    $cmd->stdout_is_eq( qq{( -2, 1 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ceil( 192.168 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'ceil( 192.168 ) ='} );
    $cmd->stdout_is_eq( qq{193\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ceil( -192.168 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'ceil( -192.168 ) ='} );
    $cmd->stdout_is_eq( qq{-192\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '( ceil( -1.2, 1.2 ) )'} );
    $cmd->exit_is_num( 0, qq{./c '( ceil( -1.2, 1.2 ) )'} );
    $cmd->stdout_is_eq( qq{( -1, 2 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rounddown( 192.168 ) ='} );
    $cmd->exit_isnt_num( 0, qq{./c 'rounddown( 192.168 ) ='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: rounddown\(\): \$argc=1: Insufficient arguments\.\n/, qq{Insufficient arguments.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'round( 192.168 ) ='} );
    $cmd->exit_isnt_num( 0, qq{./c 'round( 192.168 ) ='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: round\(\): \$argc=1: Insufficient arguments\.\n/, qq{Insufficient arguments.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'roundup( 192.168 ) ='} );
    $cmd->exit_isnt_num( 0, qq{./c 'roundup( 192.168 ) ='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: roundup\(\): \$argc=1: Insufficient arguments\.\n/, qq{Insufficient arguments.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rounddown( 192.168, 2 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'rounddown( 192.168, 2 ) ='} );
    $cmd->stdout_is_eq( qq{192.16\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'round( 192.168, 2 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'round( 192.168, 2 ) ='} );
    $cmd->stdout_is_eq( qq{192.17\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'roundup( 192.168, 2 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'roundup( 192.168, 2 ) ='} );
    $cmd->stdout_is_eq( qq{192.17\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rounddown( -192.168, 2 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'rounddown( -192.168, 2 ) ='} );
    $cmd->stdout_is_eq( qq{-192.16\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'round( -192.168, 2 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'round( -192.168, 2 ) ='} );
    $cmd->stdout_is_eq( qq{-192.17\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'roundup( -192.168, 2 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'roundup( -192.168, 2 ) ='} );
    $cmd->stdout_is_eq( qq{-192.17\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rounddown( -192.168, 3 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'rounddown( -192.168, 3 ) ='} );
    $cmd->stdout_is_eq( qq{-192.168\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'round( -192.168, 3 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'round( -192.168, 3 ) ='} );
    $cmd->stdout_is_eq( qq{-192.168\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'roundup( -192.168, 3 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'roundup( -192.168, 3 ) ='} );
    $cmd->stdout_is_eq( qq{-192.168\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rounddown( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'rounddown( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 ) ='} );
    $cmd->stdout_is_eq( qq{( -1, -0.5, -0.4, 0, 0.4, 0.5, 1 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'round( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'round( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 ) ='} );
    $cmd->stdout_is_eq( qq{( -1, -0.5, -0.4, 0, 0.4, 0.5, 1 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'roundup( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'roundup( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 ) ='} );
    $cmd->stdout_is_eq( qq{( -1, -0.5, -0.4, 0, 0.4, 0.5, 1 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rounddown( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'rounddown( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 ) ='} );
    $cmd->stdout_is_eq( qq{( -1, 0, 0, 0, 0, 0, 1 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'round( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'round( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 ) ='} );
    $cmd->stdout_is_eq( qq{( -1, -1, 0, 0, 0, 1, 1 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'roundup( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'roundup( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 ) ='} );
    $cmd->stdout_is_eq( qq{( -1, -1, -1, 0, 1, 1, 1 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'percentage( 2, 3 )'} );
    $cmd->exit_is_num( 0, qq{./c 'percentage( 2, 3 )'} );
    $cmd->stdout_is_eq( qq{66.6666666666667\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'percentage( 2, 3, 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'percentage( 2, 3, 1 )'} );
    $cmd->stdout_is_eq( qq{66.7\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'percentage( 2, 3, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'percentage( 2, 3, 0 )'} );
    $cmd->stdout_is_eq( qq{67\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'percentage( 2, 3, -1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'percentage( 2, 3, -1 )'} );
    $cmd->stdout_is_eq( qq{70\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'percentage( 2 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'percentage( 2 )'} );
    $cmd->stdout_is_eq( qq{} );
    $cmd->stderr_like( qr/^c: evaluator: error: "percentage": Operand missing\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'percentage()'} );
    $cmd->exit_isnt_num( 0, qq{./c 'percentage()'} );
    $cmd->stdout_is_eq( qq{} );
    $cmd->stderr_like( qr/^c: evaluator: error: "percentage": Operand missing\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'percentage( 2, 0 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'percentage( 2, 0 )'} );
    $cmd->stdout_is_eq( qq{} );
    $cmd->stderr_like( qr/^c: evaluator: error: Illegal division by zero.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ratio_scaling( 3, 10, 20 )'} );
    $cmd->exit_is_num( 0, qq{./c 'ratio_scaling( 3, 10, 20 )'} );
    $cmd->stdout_is_eq( qq{66.6666666666667\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ratio_scaling( 3, 10, 20, 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'ratio_scaling( 3, 10, 20, 1 )'} );
    $cmd->stdout_is_eq( qq{66.7\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ratio_scaling( 0, 10, 20 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'ratio_scaling( 0, 10, 20 )'} );
    $cmd->stdout_is_eq( qq{} );
    $cmd->stderr_like( qr/^c: evaluator: error: Illegal division by zero.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'is_prime( -2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'is_prime( -2 )'} );
    $cmd->stdout_is_eq( qq{0\n}, qq{2未満の数は素数ではない} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'is_prime( 2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'is_prime( 2 )'} );
    $cmd->stdout_is_eq( qq{1\n}, qq{2は素数} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'is_prime( 4 )'} );
    $cmd->exit_is_num( 0, qq{./c 'is_prime( 4 )'} );
    $cmd->stdout_is_eq( qq{0\n}, qq{2以外の偶数は素数ではない} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'is_prime( 0xfffffffb )'} );
    $cmd->exit_is_num( 0, qq{./c 'is_prime( 0xfffffffb )'} );
    $cmd->stdout_is_eq( qq{1 [ = 0x1 ]\n}, qq{32bitクラスの整数（素数）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'is_prime( 0xfffffffd )'} );
    $cmd->exit_is_num( 0, qq{./c 'is_prime( 0xfffffffd )'} );
    $cmd->stdout_is_eq( qq{0 [ = 0x0 ]\n}, qq{32bitクラスの整数（非素数）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'is_prime( 1576770817, 1576770818 )'} );
    $cmd->exit_is_num( 0, qq{./c 'is_prime( 1576770817, 1576770818 )'} );
    $cmd->stdout_is_eq( qq{( 1, 0 )\n}, qq{まとめて評価する} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'prime_factorize( 1234567890 )'} );
    $cmd->exit_is_num( 0, qq{./c 'prime_factorize( 1234567890 )'} );
    $cmd->stdout_is_eq( qq{( 2, 3, 3, 5, 3607, 3803 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'prime_factorize( 2 ** 32 )'} );
    $cmd->exit_is_num( 0, qq{./c 'prime_factorize( 2 ** 32 )'} );
    $cmd->stdout_is_eq( qq{( 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'prime_factorize( ( 2 ** 32 ) - 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'prime_factorize( ( 2 ** 32 ) - 1 )'} );
    $cmd->stdout_is_eq( qq{( 3, 5, 17, 257, 65537 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'prime_factorize( 2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'prime_factorize( 2 )'} );
    $cmd->stdout_is_eq( qq{2\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'prime_factorize( -10 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'prime_factorize( -10 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: prime_factorize: \-10: Cannot be less than 2\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'prime_factorize( 2.345 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'prime_factorize( 2.345 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: prime_factorize: 2\.345: Decimals cannot be specified\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'get_prime( 32.1 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'get_prime( 32.1 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: get_prime: 32\.1: Decimals cannot be specified\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'get_prime( 64 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'get_prime( 64 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: get_prime: 64: Cannot specify a value greater than 32\.\n/ );
    undef( $cmd );

    ## 64bit: 3473826439 [ = 0xCF0E6287 ]
    ## 32bit: 2942933887 [ = -1352033409 ] [ = 0xAF699B7F ]
    my $gp32_expect = qr/^\d+ \[ = 0x[\dA-F]{1,8} \]\n$/;
    if( $UV_bit_width == 32 ){
        $gp32_expect = qr/^\d+(?: \[ = \-\d+ \])? \[ = 0x[\dA-F]{1,8} \]\n$/;
    }
    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'get_prime( 32 )|0'} );
    $cmd->exit_is_num( 0, qq{./c 'get_prime( 32 )|0'} );
    $cmd->stdout_like( $gp32_expect, qq{\$UV_bit_width="$UV_bit_width"} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'get_prime( 24 )|0'} );
    $cmd->exit_is_num( 0, qq{./c 'get_prime( 24 )|0'} );
    $cmd->stdout_like( qr/^\d+ \[ = 0x[\dA-F]{1,6} \]\n$/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'get_prime( 16 )|0'} );
    $cmd->exit_is_num( 0, qq{./c 'get_prime( 16 )|0'} );
    $cmd->stdout_like( qr/^\d+ \[ = 0x[\dA-F]{1,4} \]\n$/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'get_prime( 4 )|0'} );
    $cmd->exit_is_num( 0, qq{./c 'get_prime( 4 )|0'} );
    $cmd->stdout_like( qr/^\d+ \[ = 0x[\dA-F]{1} \]\n$/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'get_prime( 3 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'get_prime( 3 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: get_prime: 3: Cannot specify a value less than 4\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gcd( 0 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'gcd( 0 ) ='} );
    $cmd->stdout_is_eq( qq{0\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gcd( 138 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'gcd( 138 ) ='} );
    $cmd->stdout_is_eq( qq{138\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gcd( 2040, 1920, 1080 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'gcd( 2040, 1920, 1080 ) ='} );
    $cmd->stdout_is_eq( qq{120\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'lcm( 1920, 1080 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'lcm( 1920, 1080 ) ='} );
    $cmd->stdout_is_eq( qq{17280\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ncr( -1.0, 2.0 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'ncr( -1.0, 2.0 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: nCr\( \-1, 2 \): N\[=\-1\] must be a non-negative integer\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ncr( 1.1, 2.0 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'ncr( 1.1, 2.0 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: nCr\( 1\.1, 2 \): N\[=1\.1\] must be a non-negative integer\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ncr( 1.0, 0 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'ncr( 1.0, 0 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: nCr\( 1, 0 \): R\[=0\] must be a positive integer\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ncr( 1.0, 2.1 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'ncr( 1.0, 2.1 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: nCr\( 1, 2\.1 \): R\[=2\.1\] must be a positive integer\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ncr( 1.0, 2.0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'ncr( 1.0, 2.0 )'} );
    $cmd->stdout_is_eq( qq{0\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ncr( 7.0, 2.0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'ncr( 7.0, 2.0 )'} );
    $cmd->stdout_is_eq( qq{21\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'min( 5 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'min( 5 ) ='} );
    $cmd->stdout_is_eq( qq{5\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'max( 5 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'max( 5 ) ='} );
    $cmd->stdout_is_eq( qq{5\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'min( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'min( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $cmd->stdout_is_eq( qq{1\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'max( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'max( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $cmd->stdout_is_eq( qq{9\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'min( 5, 4, 3, min( 5, 4, 3, 1, 2, 9, 8, 7, 6 ), 2, 9, 8, 7, 6 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'min( 5, 4, 3, min( 5, 4, 3, 1, 2, 9, 8, 7, 6 ), 2, 9, 8, 7, 6 ) ='} );
    $cmd->stdout_is_eq( qq{1\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'max( 5, 4, 3, 1, 2, max( 5, 4, 3, 1, 2, 9, 8, 7, 6 ), 8, 7, 6 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'max( 5, 4, 3, 1, 2, max( 5, 4, 3, 1, 2, 9, 8, 7, 6 ), 8, 7, 6 ) ='} );
    $cmd->stdout_is_eq( qq{9\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'min() ='} );
    $cmd->exit_isnt_num( 0, qq{./c 'min() ='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: "min": Operand missing\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'shuffle( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'shuffle( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $cmd->stdout_like( qr/^\( \d, \d, \d, \d, \d, \d, \d, \d, \d \)\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'min( shuffle( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'min( shuffle( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ) ='} );
    $cmd->stdout_is_eq( qq{1\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'uniq( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'uniq( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $cmd->stdout_is_eq( qq{( 5, 4, 3, 1, 2, 9, 8, 7, 6 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'uniq( 5, 4, 3, 1, 2, 1, 3, 4, 5, 9, 8, 7, 6 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'uniq( 5, 4, 3, 1, 2, 1, 3, 4, 5, 9, 8, 7, 6 ) ='} );
    $cmd->stdout_is_eq( qq{( 5, 4, 3, 1, 2, 9, 8, 7, 6 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'max( uniq( 5, 4, 3, 1, 2, 1, 3, 4, 5, 9, 8, 7, 6 ) ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'max( uniq( 5, 4, 3, 1, 2, 1, 3, 4, 5, 9, 8, 7, 6 ) ) ='} );
    $cmd->stdout_is_eq( qq{9\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'first( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'first( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $cmd->stdout_is_eq( qq{5\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'slice( 2025, 12 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'slice( 2025, 12 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: slice: \$argc=2: Not enough arguments\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'slice( 2025, 12, 16, 1.2, 1.3 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'slice( 2025, 12, 16, 1.2, 1.3 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: slice: \$offset=1\.2: \$offset cannot be a decimal number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'slice( 2025, 12, 16, -1.2, 1.3 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'slice( 2025, 12, 16, -1.2, 1.3 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: slice: \$offset=\-1\.2: \$offset cannot be a decimal number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'slice( 2025, 12, 16, 1, 1.3 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'slice( 2025, 12, 16, 1, 1.3 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: slice: \$length=1\.3: \$length cannot be a decimal number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'slice( 2025, 12, 16, 3, 1 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'slice( 2025, 12, 16, 3, 1 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: slice: \$offset=3, \$argc=3: \$offset is large\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'slice( 2025, 12, 16, 0, 0 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'slice( 2025, 12, 16, 0, 0 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: slice: \$length=0: \$length must be greater than 0\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'slice( 2025, 12, 16, 0, 4 )'} );
    $cmd->exit_is_num( 0, qq{./c 'slice( 2025, 12, 16, 0, 4 )'} );
    $cmd->stdout_is_eq( qq{( 2025, 12, 16 )\n} );
    $cmd->stderr_like( qr/^c: tbl_prvdr: warn: \$length=4: Decrease the value of \$length\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'slice( 2025, 12, 16, -2, 3 )'} );
    $cmd->exit_is_num( 0, qq{./c 'slice( 2025, 12, 16, -2, 3 )'} );
    $cmd->stdout_is_eq( qq{( 12, 16 )\n} );
    $cmd->stderr_like( qr/^c: tbl_prvdr: warn: \$length=3: Decrease the value of \$length\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'slice( 2025, 12, 16, 0, 3 )'} );
    $cmd->exit_is_num( 0, qq{./c 'slice( 2025, 12, 16, 0, 3 )'} );
    $cmd->stdout_is_eq( qq{( 2025, 12, 16 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'slice( 2025, 12, 16, -1, 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'slice( 2025, 12, 16, -1, 1 )'} );
    $cmd->stdout_is_eq( qq{16\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sum( 1, 2, 3, 4, 5, 6, 7, 8, 9 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'sum( 1, 2, 3, 4, 5, 6, 7, 8, 9 ) ='} );
    $cmd->stdout_is_eq( qq{45\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sum( 0.1, 2.3, 4.5, 6.7, 8.9 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'sum( 0.1, 2.3, 4.5, 6.7, 8.9 ) ='} );
    $cmd->stdout_is_eq( qq{22.5\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'prod( linstep( 1, 1, 10 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'prod( linstep( 1, 1, 10 ) )'} );
    $cmd->stdout_is_eq( qq{3628800\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'prod( linstep( 0, 1, 10 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'prod( linstep( 0, 1, 10 ) )'} );
    $cmd->stdout_is_eq( qq{0\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'prod( linstep( -1, 2, 6 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'prod( linstep( -1, 2, 6 ) )'} );
    $cmd->stdout_is_eq( qq{-945\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'avg( 1, 2, 3, 4, 5, 6, 7, 8, 9 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'avg( 1, 2, 3, 4, 5, 6, 7, 8, 9 ) ='} );
    $cmd->stdout_is_eq( qq{5\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'avg( 0.1, 2.3, 4.5, 6.7, 8.9 ) ='} );
    $cmd->exit_is_num( 0, qq{./c 'avg( 0.1, 2.3, 4.5, 6.7, 8.9 ) ='} );
    $cmd->stdout_is_eq( qq{4.5\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'add_each( -10 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'add_each( -10 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: add_each\(\): \$argc=1: Insufficient number of arguments\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'add_each( 100, 200, -10 )'} );
    $cmd->exit_is_num( 0, qq{./c 'add_each( 100, 200, -10 )'} );
    $cmd->stdout_is_eq( qq{( 90, 190 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'mul_each( ( 1 / 25.4 ) * 300 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'mul_each( ( 1 / 25.4 ) * 300 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: mul_each\(\): \$argc=1: Insufficient number of arguments\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'mul_each( 210, 297, ( 1 / 25.4 ) * 300 )'} );
    $cmd->exit_is_num( 0, qq{./c 'mul_each( 210, 297, ( 1 / 25.4 ) * 300 )'} );
    $cmd->stdout_is_eq( qq{( 2480.31496062992, 3507.87401574803 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( 4, 10, 3 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linspace( 4, 10, 3 )'} );
    $cmd->stdout_is_eq( qq{( 4, 7, 10 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( -10, 10, 5 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linspace( -10, 10, 5 )'} );
    $cmd->stdout_is_eq( qq{( -10, -5, 0, 5, 10 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( 10, -10, 5 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linspace( 10, -10, 5 )'} );
    $cmd->stdout_is_eq( qq{( 10, 5, 0, -5, -10 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( -10, 10, 9 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linspace( -10, 10, 9 )'} );
    $cmd->stdout_is_eq( qq{( -10, -7.5, -5, -2.5, 0, 2.5, 5, 7.5, 10 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( -10, 10, 9, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linspace( -10, 10, 9, 0 )'} );
    $cmd->stdout_is_eq( qq{( -10, -8, -5, -3, 0, 3, 5, 8, 10 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( 0x64, 0xff, 5 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linspace( 0x64, 0xff, 5 )'} );
    $cmd->stdout_is_eq( qq{( 100, 138.75, 177.5, 216.25, 255 ) [ = ( 0x64, 138.75, 177.5, 216.25, 0xFF ) ]\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( -10, 10 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'linspace( -10, 10 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: "linspace": Operand missing\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( -10, 10, 3, 1, 0 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'linspace( -10, 10, 3, 1, 0 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: linspace: \$arg_counter="5": The number of operands is incorrect\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( -10, 10, 0 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'linspace( -10, 10, 0 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: linspace\(\): \$length\[=0\] is less than 2\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( -10, 10, 1.2 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'linspace( -10, 10, 1.2 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: linspace\(\): \$length\[=1\.2\] is less than 2\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( -10, 10, 2.1 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'linspace( -10, 10, 2.1 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: linspace\(\): \$length\[=2\.1\] is a decimal number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linstep( 4, 10, 3 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linstep( 4, 10, 3 )'} );
    $cmd->stdout_is_eq( qq{( 4, 14, 24 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linstep( 4, -10, 3 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linstep( 4, -10, 3 )'} );
    $cmd->stdout_is_eq( qq{( 4, -6, -16 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linstep( 4, -10, 0 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'linstep( 4, -10, 0 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: linstep\(\): \$length\[=0\] is less than 1\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linstep( 4, 10, -1.2 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'linstep( 4, 10, -1.2 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: linstep\(\): \$length\[=\-1\.2\] is less than 1\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linstep( 4, 10, 1.2 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'linstep( 4, 10, 1.2 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: linstep\(\): \$length\[=1\.2\] is a decimal number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linstep( 4, -10, 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linstep( 4, -10, 1 )'} );
    $cmd->stdout_is_eq( qq{4\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linstep( -1.1, -1 sqrt( 2 ), 3 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linstep( -1.1, -1 sqrt( 2 ), 3 )'} );
    $cmd->stdout_is_eq( qq{( -1.1, -2.5142135623731, -3.92842712474619 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'mul_growth( 0, 1, 10 )'} );
    $cmd->exit_is_num( 0, qq{./c 'mul_growth( 0, 1, 10 )'} );
    $cmd->stdout_is_eq( qq{( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'mul_growth( 1, 1, -1.2 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'mul_growth( 1, 1, -1.2 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: mul_growth\(\): \$length\[=\-1\.2\] is less than 1\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'mul_growth( 1, 1, 0 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'mul_growth( 1, 1, 0 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: mul_growth\(\): \$length\[=0\] is less than 1\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'mul_growth( -100, 0, 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'mul_growth( -100, 0, 1 )'} );
    $cmd->stdout_is_eq( qq{-100\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'mul_growth( 1, 1, 1.2 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'mul_growth( 1, 1, 1.2 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: mul_growth\(\): \$length\[=1\.2\] is a decimal number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'mul_growth( 100, 0.5, 2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'mul_growth( 100, 0.5, 2 )'} );
    $cmd->stdout_is_eq( qq{( 100, 50 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'mul_growth( 4, 2, 5 )'} );
    $cmd->exit_is_num( 0, qq{./c 'mul_growth( 4, 2, 5 )'} );
    $cmd->stdout_is_eq( qq{( 4, 8, 16, 32, 64 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gen_fibo_seq( 0, 1, 10 )'} );
    $cmd->exit_is_num( 0, qq{./c 'gen_fibo_seq( 0, 1, 10 )'} );
    $cmd->stdout_is_eq( qq{( 0, 1, 1, 2, 3, 5, 8, 13, 21, 34 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gen_fibo_seq( 2, 1, 10 )'} );
    $cmd->exit_is_num( 0, qq{./c 'gen_fibo_seq( 2, 1, 10 )'} );
    $cmd->stdout_is_eq( qq{( 2, 1, 3, 4, 7, 11, 18, 29, 47, 76 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gen_fibo_seq( -2, 5, 10 )'} );
    $cmd->exit_is_num( 0, qq{./c 'gen_fibo_seq( -2, 5, 10 )'} );
    $cmd->stdout_is_eq( qq{( -2, 5, 3, 8, 11, 19, 30, 49, 79, 128 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gen_fibo_seq( 2, 1, 0 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'gen_fibo_seq( 2, 1, 0 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: gen_fibo_seq\(\): \$length\[=0\] is less than 2\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gen_fibo_seq( 2, 1, -1.2 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'gen_fibo_seq( 2, 1, -1.2 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: gen_fibo_seq\(\): \$length\[=\-1\.2\] is less than 2\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gen_fibo_seq( 2, 1, 2.1 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'gen_fibo_seq( 2, 1, 2.1 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: gen_fibo_seq\(\): \$length\[=2\.1\] is a decimal number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gen_fibo_seq( -100, 100, 2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'gen_fibo_seq( -100, 100, 2 )'} );
    $cmd->stdout_is_eq( qq{( -100, 100 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gen_fibo_seq( -5.4, 3.2, 10 )'} );
    $cmd->exit_is_num( 0, qq{./c 'gen_fibo_seq( -5.4, 3.2, 10 )'} );
    $cmd->stdout_is_eq( qq{( -5.4, 3.2, -2.2, 1, -1.2, -0.2, -1.4, -1.6, -3, -4.6 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'paper_size( -1.2 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'paper_size( -1.2 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: paper_size\(\): \$size\[=\-1\.2\] is negative\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'paper_size( 1.2 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'paper_size( 1.2 )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: paper_size\(\): \$size\[=1\.2\] is a decimal number\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'paper_size( 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'paper_size( 0 )'} );
    $cmd->stdout_is_eq( qq{( 841, 1189 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'paper_size( 4 )'} );
    $cmd->exit_is_num( 0, qq{./c 'paper_size( 4 )'} );
    $cmd->stdout_is_eq( qq{( 210, 297 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'paper_size( 19, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'paper_size( 19, 0 )'} );
    $cmd->stdout_is_eq( qq{( 1, 1 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'paper_size( 20, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'paper_size( 20, 0 )'} );
    $cmd->stdout_is_eq( qq{( 0, 1 )\n} );
    $cmd->stderr_is_eq( qq{paper_size(): A20: The short side reaches 0 mm.\n} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'paper_size( 100, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'paper_size( 100, 0 )'} );
    $cmd->stdout_is_eq( qq{( 0, 0 )\n} );
    $cmd->stderr_is_eq( qq{paper_size(): A20: The short side reaches 0 mm.\npaper_size(): A21: The long side reaches 0 mm.\n} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'paper_size( 0, 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'paper_size( 0, 1 )'} );
    $cmd->stdout_is_eq( qq{( 1030, 1456 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'paper_size( 4, 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'paper_size( 4, 1 )'} );
    $cmd->stdout_is_eq( qq{( 257, 364 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'paper_size( 100, 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'paper_size( 100, 1 )'} );
    $cmd->stdout_is_eq( qq{( 0, 0 )\n} );
    $cmd->stderr_is_eq( qq{paper_size(): B21: The short side reaches 0 mm.\npaper_size(): B22: The long side reaches 0 mm.\n} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'min( rand( 10 ), rand( 10 ), rand( 10 ), rand( 10 ), rand( 10 ) )' -v} );
    $cmd->exit_is_num( 0, qq{./c 'min( rand( 10 ), rand( 10 ), rand( 10 ), rand( 10 ), rand( 10 ) )' -v} );
    $cmd->stdout_like( qr/\n    RPN: '# # 10 rand # 10 rand # 10 rand # 10 rand # 10 rand min'\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rand(-10)'} );
    $cmd->exit_is_num( 0, qq{./c 'rand(-10)'} );
    $cmd->stdout_like( qr/^\-\d\./ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rand(0)'} );
    $cmd->exit_is_num( 0, qq{./c 'rand(0)'} );
    $cmd->stdout_like( qr/^0\./ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rand(10)'} );
    $cmd->exit_is_num( 0, qq{./c 'rand(10)'} );
    $cmd->stdout_like( qr/^\d\./ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'int( rand( 2 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'int( rand( 2 ) )'} );
    $cmd->stdout_like( qr/^[01]$/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '***='} );
    $cmd->exit_isnt_num( 0, qq{./c '***='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: "\*\*": Operand missing\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1+2*3+='} );
    $cmd->exit_isnt_num( 0, qq{./c '1+2*3+='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: "\+": Operand missing\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '()='} );
    $cmd->exit_is_num( 0, qq{./c '()='} );
    $cmd->stdout_is_eq( qq{0\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1_2='} );
    $cmd->exit_isnt_num( 0, qq{./c '1_2='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: lexer: error: "_2=": Could not interpret\.\n/ );
    $cmd->stderr_like( qr/\nc: lexer: info: Supported operators: / );
    $cmd->stderr_like( qr/\nc: lexer: info: Supported functions: / );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(#)='} );
    $cmd->exit_isnt_num( 0, qq{./c 'sqrt(#)='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: lexer: error: "#\)=": Could not interpret\.\n/ );
    $cmd->stderr_like( qr/\nc: lexer: info: Supported operators: / );
    $cmd->stderr_like( qr/\nc: lexer: info: Supported functions: / );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '( 1 + 2 + 3, 4 ) ='} );
    $cmd->exit_is_num( 0, qq{./c '( 1 + 2 + 3, 4 ) ='} );
    $cmd->stdout_is_eq( qq{( 6, 4 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '123' '+2=' -v} );
    $cmd->exit_is_num( 0, qq{./c '123' '+2=' -v} );
    $cmd->stdout_like( qr/123 \+ 2 = 125\n/ );
    $cmd->stdout_like( qr/\n Result: 125\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '123' '2=' -v} );
    $cmd->exit_is_num( 0, qq{./c '123' '2=' -v} );
    $cmd->stdout_like( qr/^123 \* 2 = 246\n/ );
    $cmd->stdout_like( qr/\n Result: 246\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1+(2+(3+(4+(5+(6+((7+8*9)))))))='} );
    $cmd->exit_is_num( 0, qq{./c '1+(2+(3+(4+(5+(6+((7+8*9)))))))='} );
    $cmd->stdout_is_eq( qq{100\n}, qq{result: 100} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(4)=' =r} );
    $cmd->exit_isnt_num( 0, qq{./c 'sqrt(4)=' =r} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_is_eq( qq{c: engine: warn: "=r": Ignore. The calculation process has been completed.\n} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(power(2, 100)+power(2,100))='} );
    $cmd->exit_isnt_num( 0, qq{./c 'sqrt(power(2, 100)+power(2,100))='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: pow: \$arg_counter="1": The number of operands is incorrect\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(-1)'} );
    $cmd->exit_isnt_num( 0, qq{./c 'sqrt(-1)'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: Can't take sqrt of \-1\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1+(2+(3+(4+(5+(6+((7+8*9)))))))=' --test-test -d} );
    $cmd->exit_is_num( 0, qq{./c '1+(2+(3+(4+(5+(6+((7+8*9)))))))=' --test-test -d} );
    ## OutputFunc
    $cmd->stdout_like( qr/\nengine: \$help_of_unknown_operator="  \*\*\*\n/, 'OutputFunc' );
    ## TableProvider
    $cmd->stdout_like( qr/\ntbl_prvdr: test: \$opeIdx=""\n/, 'TableProvider' );
    $cmd->stdout_like( qr/\ntbl_prvdr: test: \$bSentinel="0"\n/, 'TableProvider' );
    ## FormulaStack
    $cmd->stdout_like( qr/Pop\(\): enmpy/, 'FormulaStack' );
    $cmd->stdout_like( qr/GetNewer\(\): enmpy/, 'FormulaStack' );
    ## FormulaEvaluator
    $cmd->stdout_like( qr/\nevaluator: scalar\( \@\{ \$self->\{RPN\} \} \) = 3\n/, 'FormulaEvaluator' );
    $cmd->stdout_like( qr/\nevaluator: scalar\( \@\{ \$self->\{TOKENS\} \} \) = 2\n/, 'FormulaEvaluator' );
    $cmd->stdout_like( qr/\nevaluator: GetUsage\(\) test: \$usage=""\n/, 'FormulaEvaluator' );
    $cmd->stdout_like( qr/\n Result: 100\n/, qq{result: 100} );
    $cmd->stderr_like( qr/^Use of uninitialized value \$opeIdx / );
    $cmd->stderr_like( qr/\nc: evaluator: warn: There may be an error in the calculation formula\.\n/, 'FormulaEvaluator' );
    $cmd->stderr_like( qr/\nc: evaluator: error: "\*": Unexpected errors\.\n/, 'FormulaEvaluator' );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1+(2+(3+(4+(5+(6+((7+8*9)))))))=' --test-test} );
    $cmd->exit_is_num( 0, qq{./c '1+(2+(3+(4+(5+(6+((7+8*9)))))))=' --test-test} );
    ## OutputFunc
    $cmd->stdout_unlike( qr/\nengine: \$help_unknown_operator="  \*\*\*\n/, 'OutputFunc' );
    ## TableProvider
    $cmd->stdout_unlike( qr/\ntbl_prvdr: test: \$opeIdx=""\n/, 'TableProvider' );
    $cmd->stdout_unlike( qr/\ntbl_prvdr: test: \$bSentinel="0"\n/, 'TableProvider' );
    ## FormulaStack
    $cmd->stdout_unlike( qr/Pop\(\): enmpy/, 'FormulaStack' );
    $cmd->stdout_unlike( qr/GetNewer\(\): enmpy/, 'FormulaStack' );
    ## FormulaEvaluator
    $cmd->stdout_unlike( qr/\nevaluator: scalar\( \@FormulaEvaluator::RPN \) = 3\n/, 'FormulaEvaluator' );
    $cmd->stdout_unlike( qr/\nevaluator: scalar\( \@FormulaEvaluator::Tokens \) = 2\n/, 'FormulaEvaluator' );
    $cmd->stdout_unlike( qr/\nevaluator: GetUsage\(\) test: \$usage=""\n/, 'FormulaEvaluator' );
    $cmd->stdout_is_eq( qq{100\n}, qq{result: 100} );
    $cmd->stderr_like( qr/^Use of uninitialized value \$opeIdx / );
    $cmd->stderr_like( qr/\nc: evaluator: warn: There may be an error in the calculation formula\.\n/, 'FormulaEvaluator' );
    $cmd->stderr_like( qr/\nc: evaluator: error: "\*": Unexpected errors\.\n/, 'FormulaEvaluator' );
    undef( $cmd );

};

subtest qq{aliases} => sub{

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pct( 2, 3, 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'pct( 2, 3, 1 )'} );
    $cmd->stdout_is_eq( qq{66.7\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'rs( 3, 10, 20 )'} );
    $cmd->exit_is_num( 0, qq{./c 'rs( 3, 10, 20 )'} );
    $cmd->stdout_is_eq( qq{66.6666666666667\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pf( 1234567890 )'} );
    $cmd->exit_is_num( 0, qq{./c 'pf( 1234567890 )'} );
    $cmd->stdout_is_eq( qq{( 2, 3, 3, 5, 3607, 3803 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'dist( 100, 100, 0, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'dist( 100, 100, 0, 0 )'} );
    $cmd->stdout_is_eq( qq{141.42135623731\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'midpt( 100, 100, 0, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'midpt( 100, 100, 0, 0 )'} );
    $cmd->stdout_is_eq( qq{( 50, 50 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'angle( 100, 100, 0, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'angle( 100, 100, 0, 0 )'} );
    $cmd->stdout_is_eq( qq{-135\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gd_m( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) ) / 1000'} );
    $cmd->exit_is_num( 0, qq{./c 'gd_m( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) ) / 1000'} );
    $cmd->stdout_is_eq( qq{14075.6175288926\n}, qq{東京駅から昭和基地までの距離（m）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gd_km( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'gd_km( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->stdout_is_eq( qq{14075.6175288926\n}, qq{東京駅から昭和基地までの距離（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gazm( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'gazm( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->stdout_is_eq( qq{206.051582912837\n}, qq{東京駅から昭和基地までの方角（度）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gd_m_azm( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'gd_m_azm( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->stdout_is_eq( qq{( 14075617.5288926, 206.051582912837 )\n}, qq{東京駅から昭和基地までの距離（m）と方角（度）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'gd_km_azm( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->exit_is_num( 0, qq{./c 'gd_km_azm( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $cmd->stdout_is_eq( qq{( 14075.6175288926, 206.051582912837 )\n}, qq{東京駅から昭和基地までの距離（km）と方角（度）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '里→メートル( 1 )'} );
    $cmd->exit_is_num( 0, qq{./c '里→メートル( 1 )'} );
    $cmd->stdout_is_eq( qq{3927.2727272727\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'メートル→里( 4000 )'} );
    $cmd->exit_is_num( 0, qq{./c 'メートル→里( 4000 )'} );
    $cmd->stdout_is_eq( qq{1.01851851851853\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'マイル→メートル( 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'マイル→メートル( 1 )'} );
    $cmd->stdout_is_eq( qq{1609.344\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'メートル→マイル( 2000 )'} );
    $cmd->exit_is_num( 0, qq{./c 'メートル→マイル( 2000 )'} );
    $cmd->stdout_is_eq( qq{1.24274238447467\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '海里→メートル( 1 )'} );
    $cmd->exit_is_num( 0, qq{./c '海里→メートル( 1 )'} );
    $cmd->stdout_is_eq( qq{1852\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'メートル→海里( 2000 )'} );
    $cmd->exit_is_num( 0, qq{./c 'メートル→海里( 2000 )'} );
    $cmd->stdout_is_eq( qq{1.07991360691145\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'ポンド→グラム( 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'ポンド→グラム( 1 )'} );
    $cmd->stdout_is_eq( qq{453.59237\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'グラム→ポンド( 500 )'} );
    $cmd->exit_is_num( 0, qq{./c 'グラム→ポンド( 500 )'} );
    $cmd->stdout_is_eq( qq{1.10231131092439\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'オンス→グラム( 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'オンス→グラム( 1 )'} );
    $cmd->stdout_is_eq( qq{28.349523125\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'グラム→オンス( 30 )'} );
    $cmd->exit_is_num( 0, qq{./c 'グラム→オンス( 30 )'} );
    $cmd->stdout_is_eq( qq{1.05821885848741\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{printf "\n\n" | $TARGCMD 'lt( 2 )'} );
    $cmd->exit_is_num( 0, qq{printf "\n\n" | ./c 'lt( 2 )'} );
    $cmd->stdout_like( qr/^Lap  Split\-Time    Lap\-Time      Date\-Time\n/ );
    $cmd->stdout_like( qr/\r2\/2  00:00:00\./ );
    $cmd->stdout_like( qr/\n0\./ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '' | $TARGCMD 'sw()'} );
    $cmd->exit_is_num( 0, qq{echo '' | ./c 'sw()'} );
    $cmd->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $cmd->stdout_like( qr/\n0\./ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{-d, --debug} => sub{

    $cmd = Test::Command->new( cmd => qq{echo | $TARGCMD -d} );
    $cmd->exit_is_num( 0, qq{echo | ./c -d} );
    $cmd->stdout_like( qr/^dbg: arg="\-d", \@val=0\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo | $TARGCMD --debug} );
    $cmd->exit_is_num( 0, qq{echo | ./c --debug} );
    $cmd->stdout_like( qr/^dbg: arg="\-\-debug", \@val=0\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo | $TARGCMD -dv} );
    $cmd->exit_is_num( 0, qq{echo | ./c -dv} );
    $cmd->stdout_like( qr/dbg: arg="\-d", \@val=1\ndbg: arg="\-v", \@val=0\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -d '-20-3*2(1+sqrt(4))='} );
    $cmd->exit_is_num( 0, qq{./c -d '-20-3*2(1+sqrt(4))='} );
    $cmd->stdout_like( qr/^dbg: arg="\-d", \@val=1\n/ );
    $cmd->stdout_like( qr/\nRemain RPN: \-20 3 2\n/ );
    $cmd->stdout_like( qr/\n Result: \-38\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{-v, --verbose} => sub{

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(2**100)=' -v} );
    $cmd->exit_is_num( 0, qq{./c 'sqrt(2**100)=' -v} );
    $cmd->stdout_like( qr/^2 \*\* 100 = 1\.26765060022823e\+30\n/ );
    $cmd->stdout_like( qr/\nsqrt\( 1\.26765060022823e\+30 \) = 1\.12589990684262e\+15\n/ );
    $cmd->stdout_like( qr/\n Result: 1125899906842624 \[ = 1\.12589990684262e\+15 \]\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(power(2, 100)+power(2, 100))=' --verbose} );
    $cmd->exit_is_num( 0, qq{./c 'sqrt(power(2, 100)+power(2, 100))=' --verbose} );
    $cmd->stdout_like( qr/\n Result: 1592262918131443\.25 \[ = 1\.59226291813144e\+15 \]\n/ );  ## 1592262918131443.1411559535896932
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0.22*10**(-6)=' --verbose} );
    $cmd->exit_is_num( 0, qq{./c '0.22*10**(-6)=' --verbose} );
    $cmd->stdout_like( qr/\n Result: 0.00000022 \[ = 2\.2e\-07 \]\n/ );            ## 0.00000022
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -v '-20-3*2(1+sqrt(4))='} );
    $cmd->exit_is_num( 0, qq{./c -v '-20-3*2(1+sqrt(4))='} );
    $cmd->stdout_like( qr/^3 \* 2 = 6\n/ );
    $cmd->stdout_like( qr/\nsqrt\( 4 \) = 2\n/ );
    $cmd->stdout_like( qr/\n1 \+ 2 = 3\n/ );
    $cmd->stdout_like( qr/\n6 \* 3 = 18\n/ );
    $cmd->stdout_like( qr/\n\-20 \- 18 = \-38\n/ );
    $cmd->stdout_like( qr/\n Result: \-38\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '10*-3*-5+-4/2=' --verbose} );
    $cmd->exit_is_num( 0, qq{./c '10*-3*-5+-4/2=' --verbose} );
    $cmd->stdout_like( qr/^10 \* \-3 = \-30\n/ );
    $cmd->stdout_like( qr/\n\-30 \* \-5 = 150\n/ );
    $cmd->stdout_like( qr/\n\-4 \/ 2 = \-2\n/ );
    $cmd->stdout_like( qr/\n150 \+ \-2 = 148\n/ );
    $cmd->stdout_like( qr/\n Result: 148\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --verbose '0x0d*0xff/(-0x5*-0x0d)='} );
    $cmd->exit_is_num( 0, qq{./c --verbose '0x0d*0xff/(-0x5*-0x0d)='} );
    $cmd->stdout_like( qr/^13 \* 255 = 3315\n/ );
    $cmd->stdout_like( qr/\n\-5 \* \-13 = 65\n/ );
    $cmd->stdout_like( qr/\n3315 \/ 65 = 51\n/ );
    $cmd->stdout_like( qr/\n Result: 51 \[ = 0x33 \]\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linstep( 0.00000022, -1, 2 )' -v} );
    $cmd->exit_is_num( 0, qq{./c 'linstep( 0.00000022, -1, 2 )' -v} );
    $cmd->stdout_like( qr/\n Result: \( 0\.00000022, \-0\.99999978 \) \[ = \( 2\.2e\-07, \-0\.99999978 \) \]\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{-r, --rpn} => sub{

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '10*-3' '*-5+-4/2=' -r} );
    $cmd->exit_is_num( 0, qq{./c '10*-3' '*-5+-4/2=' -r} );
    $cmd->stdout_is_eq( qq{10 -3 * -5 * -4 2 / +\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '10*-3' '*-5+-4/2=' --rpn} );
    $cmd->exit_is_num( 0, qq{./c '10*-3' '*-5+-4/2=' --rpn} );
    $cmd->stdout_is_eq( qq{10 -3 * -5 * -4 2 / +\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '10*-3' '*-5+-4/2=' --rpn --verbose} );
    $cmd->exit_is_num( 0, qq{./c '10*-3' '*-5+-4/2=' --rpn --verbose} );
    $cmd->stdout_like( qr/^Remain RPN: 10\n/ );
    $cmd->stdout_like( qr/\nRemain RPN: 150 \-4 2\n/ );
    $cmd->stdout_like( qr/\n10 \-3 \* \-5 \* \-4 2 \/ \+\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{--version} => sub{

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --version} );
    $cmd->exit_is_num( 0, qq{./c --version} );
    $cmd->stdout_like( qr/^Version: \d/ );
    $cmd->stdout_like( qr/\n   Perl: v\d/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{-h, --help} => sub{

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -h} );
    $cmd->exit_is_num( 0, qq{./c -h} );
    $cmd->stdout_like( qr/^Usage: c / );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --help} );
    $cmd->exit_is_num( 0, qq{./c --help} );
    $cmd->stdout_like( qr/^Usage: c / );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --test-test --help} );
    $cmd->exit_is_num( 0, qq{./c --test-test --help} );
    $cmd->stdout_like( qr/^Usage: c / );
    $cmd->stdout_like( qr/\n  =     Equals sign. In \*c\* script, it has the meaning of terminating the/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

#    $cmd = Test::Command->new( cmd => qq{export PATH="./tests:\$PATH" && $TARGCMD --test-test --help} );
#    $cmd->exit_is_num( 0, qq{export PATH="./tests:\$PATH" && ./c --test-test --help} );
    $cmd = Test::Command->new( cmd => qq{PATH="./tests:\$PATH" $TARGCMD --test-test --help} );
    $cmd->exit_is_num( 0, qq{PATH="./tests:\$PATH" ./c --test-test --help} );
    $cmd->stdout_like( qr/^Usage: c / );
    $cmd->stdout_like( qr/\n  =     Equals sign. In \*c\* script, it has the meaning of terminating the/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

#    $cmd = Test::Command->new( cmd => qq{export COLUMNS="70" && export LINES="30" && $TARGCMD --help} );
#    $cmd->exit_is_num( 0, qq{export COLUMNS="70" && export LINES="30" && ./c --help} );
    $cmd = Test::Command->new( cmd => qq{COLUMNS="70" LINES="30" $TARGCMD --help} );
    $cmd->exit_is_num( 0, qq{COLUMNS="70" LINES="30" ./c --help} );
    $cmd->stdout_like( qr/^Usage: c /, qq{Specified character width.} );
    $cmd->stdout_like( qr/\n  =     Equals sign. In \*c\* script, it has the meaning of terminating\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

#    $cmd = Test::Command->new( cmd => qq{unset COLUMNS && unset LINES && $TARGCMD --help} );
#    $cmd->exit_is_num( 0, qq{unset COLUMNS && unset LINES && ./c --help} );
    $cmd = Test::Command->new( cmd => qq{env -u COLUMNS -u LINES $TARGCMD --help} );
    $cmd->exit_is_num( 0, qq{env -u COLUMNS -u LINES ./c --help} );
    $cmd->stdout_like( qr/^Usage: c / );
    $cmd->stdout_like( qr/\n  =     Equals sign. In \*c\* script, it has the meaning of terminating the\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{user-rc ( Run Command )} => sub{

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $cmd->stdout_is_eq( qq{403\.862905334285\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    `rm -f .c.rc`;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: lexer: error: "tokyo_st_coord, osaka_st_coord \)=": Could not interpret\.\n/ );
    undef( $cmd );

    `gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.failed && mv .c.rc.failed .c.rc`;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/c: lexer: error: \.\/tests\/\.\.\/\.c\.rc: Failed to load user rc file: / );
    undef( $cmd );

    `gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.duplicate && mv .c.rc.duplicate .c.rc`;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )' -v} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )' -v} );
    $cmd->stdout_like( qr/\n Result: 403\.862905334285\n/ );
    $cmd->stderr_is_eq( qq{c: lexer: warn: "osaka_st_coord": "deg2rad( 34.70248, 135.49595 )" -> "deg2rad( 34.70248, 135.49595 )": Overwrites the existing definition.\n} );
    undef( $cmd );

    `gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.deploy && mv .c.rc.deploy .c.rc`;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )' -v} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )' -v} );
    $cmd->stdout_like( qr/\n Result: 403\.862905334285\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{-u, --user-defined} => sub{

    `rm -f .c.rc`;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -u} );
    $cmd->exit_is_num( 0, qq{./c -u} );
    $cmd->stdout_like( qr/^=== User Defined ===\n/ );
    $cmd->stdout_like( qr/\n====================\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    `gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.deploy && mv .c.rc.deploy .c.rc`;

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --user-defined} );
    $cmd->exit_is_num( 0, qq{./c --user-defined} );
    $cmd->stdout_like( qr/^=== User Defined ===\n/ );
    $cmd->stdout_like( qr/\n====================\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{STDIN} => sub{

    $cmd = Test::Command->new( cmd => qq{echo '１２３，４５６－５９ ＋ １２３．４５６＊２＝' | $TARGCMD} );
    $cmd->exit_is_num( 0, qq{echo '１２３，４５６－５９ ＋ １２３．４５６＊２＝' | ./c} );
    $cmd->stdout_is_eq( qq{123643.912\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '123 2(=' | $TARGCMD} );
    $cmd->exit_isnt_num( 0, qq{echo '123 2(=' | ./c} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: parser: error: The position of the "\)" is incorrect\.\n/ );
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
