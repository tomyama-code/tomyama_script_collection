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

my $UV_bit_width = log( ~0 + 1 ) / log( 2 );    # perlの整数は固定幅ではないので桁溢れしない。
#print( qq{\$UV_bit_width="$UV_bit_width"\n} );

`gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.deploy && mv .c.rc.deploy .c.rc`;

subtest qq{Normal} => sub{
    my $t;

    $t = tests::Command->new( qq{echo | ./c} );
    $t->exit_is( 0, qq{echo | ./c} );
    $t->stdout_is( qq{\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 123456-59+123.456*2=} );
    $t->exit_is( 0, qq{./c 123456-59+123.456*2=} );
    $t->stdout_is( qq{123643.912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '123456-(59+123.456)*2='} );
    $t->exit_is( 0, qq{./c '123456-(59+123.456)*2='} );
    $t->stdout_is( qq{123091.088\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 123+45*6-7=} );
    $t->exit_is( 0, qq{./c 123+45*6-7=} );
    $t->stdout_is( qq{386\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c １２３，４５６－５９ ＋ １２３．４５６＊２＝} );
    $t->exit_is( 0, qq{./c １２３，４５６－５９ ＋ １２３．４５６＊２＝} );
    $t->stdout_is( qq{123643.912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c １２３，４５６－５９ ＋ １２３．４５６（３－１）＝} );
    $t->exit_is( 0, qq{./c １２３，４５６－５９ ＋ １２３．４５６（３－１）＝} );
    $t->stdout_is( qq{123643.912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c １２３，４５６－５９ ＋ １２３．４５６（３－２＊１＋１）＝} );
    $t->exit_is( 0, qq{./c １２３，４５６－５９ ＋ １２３．４５６（３－２＊１＋１）＝} );
    $t->stdout_is( qq{123643.912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c １２３，４５６－５９ ＋ １２３．４５６（（３－２）＊１＋１）＝} );
    $t->exit_is( 0, qq{./c １２３，４５６－５９ ＋ １２３．４５６（（３－２）＊１＋１）＝} );
    $t->stdout_is( qq{123643.912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c １２３，４５６＋－５９ ＋ １２３．４５６（（３－２）＊１＋１）＝} );
    $t->exit_is( 0, qq{./c １２３，４５６＋－５９ ＋ １２３．４５６（（３－２）＊１＋１）＝} );
    $t->stdout_is( qq{123643.912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'round( geo_distance_km( 北緯５１．５０３２４度、西経０．１１３４度,　南緯６９．００４３９°，東経３９．５８２２° ), 0 )'} );
    $t->exit_is( 0, qq{./c 'round( geo_distance_km( 北緯５１．５０３２４度、西経０．１１３４度,　南緯６９．００４３９°，東経３９．５８２２° ), 0 )'} );
    $t->stdout_is( qq{13756\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c "round( geo_distance_km( 51°30'11.6639999999933\\"N, 0°6'48.24\\"W,　69°0'15.8040000000028\\"S，39°34'55.920000000001\\"E ), 0 )"} );
    $t->exit_is( 0, qq{./c "round( geo_distance_km( 51°30'11.6639999999933\\"N, 0°6'48.24\\"W,　69°0'15.8040000000028\\"S，39°34'55.920000000001\\"E ), 0 )"} );
    $t->stdout_is( qq{13756\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '2--10='} );
    $t->exit_is( 0, qq{./c '2--10='} );
    $t->stdout_is( qq{12\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '2/-10='} );
    $t->exit_is( 0, qq{./c '2/-10='} );
    $t->stdout_is( qq{-0.2\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '3+10%3='} );
    $t->exit_is( 0, qq{./c '3+10%3='} );
    $t->stdout_is( qq{4\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '3+0xf*2='} );
    $t->exit_is( 0, qq{./c '3+0xf*2='} );
    $t->stdout_is( qq{33 \[ = 0x21 \]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0x0055**2-0XC-2='} );
    $t->exit_is( 0, qq{./c '0x0055**2-0XC-2='} );
    $t->stdout_is( qq{7211 \[ = 0x1C2B \]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0x9+0xc&0xe='} );
    $t->exit_is( 0, qq{./c '0x9+0xc&0xe='} );
    $t->stdout_is( qq{4 \[ = 0x4 \]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0x9&0xc+0xe='} );
    $t->exit_is( 0, qq{./c '0x9&0xc+0xe='} );
    $t->stdout_is( qq{8 \[ = 0x8 \]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0x9+0xc|0xe='} );
    $t->exit_is( 0, qq{./c '0x9+0xc|0xe='} );
    $t->stdout_is( qq{31 \[ = 0x1F \]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0x9|0xc+0xe='} );
    $t->exit_is( 0, qq{./c '0x9|0xc+0xe='} );
    $t->stdout_is( qq{27 \[ = 0x1B \]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0x1 ^ 0x2 ='} );
    $t->exit_is( 0, qq{./c '0x1 ^ 0x2 ='} );
    $t->stdout_is( qq{3 [ = 0x3 ]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0x3 ^ 0x2 ='} );
    $t->exit_is( 0, qq{./c '0x3 ^ 0x2 ='} );
    $t->stdout_is( qq{1 [ = 0x1 ]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0x3 ^ 0x3 ='} );
    $t->exit_is( 0, qq{./c '0x3 ^ 0x3 ='} );
    $t->stdout_is( qq{0 [ = 0x0 ]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '5 ^ 3 ='} );
    $t->exit_is( 0, qq{./c '5 ^ 3 ='} );
    $t->stdout_is( qq{6 [ = 0x6 ]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0x6 << 1'} );
    $t->exit_is( 0, qq{./c '0x6 << 1'} );
    $t->stdout_is( qq{12 [ = 0xC ]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0x6 >> 1'} );
    $t->exit_is( 0, qq{./c '0x6 >> 1'} );
    $t->stdout_is( qq{3 [ = 0x3 ]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    my $num_of_shifts = $UV_bit_width - 1;
    my $expect_L = qq{9223372036854775808 [ = -9223372036854775808 ] [ = 0x8000000000000000 ]};
    my $arg_R = 9223372036854775808;
    if( $UV_bit_width == 32 ){
        $expect_L = qq{2147483648 [ = -2147483648 ] [ = 0x80000000 ]};
        $arg_R = 2147483648;
    }

    $t = tests::Command->new( qq{./c '1 << $num_of_shifts'} );
    $t->exit_is( 0, qq{./c '1 << $num_of_shifts'} );
    $t->stdout_is( qq{$expect_L\n}, qq{UVの最大シフト数: $num_of_shifts} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '$arg_R >> $num_of_shifts'} );
    $t->exit_is( 0, qq{./c '$arg_R >> $num_of_shifts'} );
    $t->stdout_is( qq{1 [ = 0x1 ]\n}, qq{UVの最大シフト数: $num_of_shifts} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '~1+1='} );
    $t->exit_is( 0, qq{./c '~1+1='} );
    my $expect = qq{18446744073709551615 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{4294967295 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
    }
    $t->stdout_is( $expect );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '1+~1='} );
    $t->exit_is( 0, qq{./c '1+~1='} );
    $expect = qq{18446744073709551615 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{4294967295 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
    }
    $t->stdout_is( $expect );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '~1*2='} );
    $t->exit_is( 0, qq{./c '~1*2='} );
    $expect = qq{36893488147419103232 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{8589934588 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
    }
    $t->stdout_is( $expect );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '2*~1='} );
    $t->exit_is( 0, qq{./c '2*~1='} );
    $expect = qq{36893488147419103232 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{8589934588 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
    }
    $t->stdout_is( $expect );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '2' '~1='} );
    $t->exit_is( 0, qq{./c '2' '~1='} );
    $expect = qq{36893488147419103232 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{8589934588 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
    }
    $t->stdout_is( $expect );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0xfc & 0x10  ~0x1 | 0x8 =' -v} );
    $t->exit_is( 0, qq{./c '0xfc & 0x10  ~0x1 | 0x8 =' -v} );
    $t->stdout_like( qr/\n    RPN: '252 16 1 ~ \* & 8 \|'\n/ );
    $t->stdout_like( qr/\n Result: 252 \[ = 0xFC \]\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 123,456-59 + '123.456((3-2)*1+1+(1-3/3))='} );
    $t->exit_is( 0, qq{./c 123,456-59 + '123.456((3-2)*1+1+(1-3/3))='} );
    $t->stdout_is( qq{123643.912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c （１９２０＊＊２＋１０８０＊＊２）＝} );
    $t->exit_is( 0, qq{./c （１９２０＊＊２＋１０８０＊＊２）＝} );
    $t->stdout_is( qq{4852800\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '√(1920**2+1080**2)='} );
    $t->exit_is( 0, qq{./c '√(1920**2+1080**2)='} );
    $t->stdout_is( qq{2202.90717008\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '２π１０＝'} );
    $t->exit_is( 0, qq{./c '２π１０＝'} );
    $t->stdout_is( qq{62.8318530718\n} );  ## 62.83185307179586476925286766559
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ＳＱＲＴ(1920**2+1080**2)='} );
    $t->exit_is( 0, qq{./c 'ＳＱＲＴ(1920**2+1080**2)='} );
    $t->stdout_is( qq{2202.90717008\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sqrt(power(1920,2)+power(1080,2))='} );
    $t->exit_is( 0, qq{./c 'sqrt(power(1920,2)+power(1080,2))='} );
    $t->stdout_is( qq{2202.90717008\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sqrt( power( 1920, 2 ) + power( 1080, 2 ) ) ='} );
    $t->exit_is( 0, qq{./c 'sqrt( power( 1920, 2 ) + power( 1080, 2 ) ) ='} );
    $t->stdout_is( qq{2202.90717008\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sqrt( 1920 ** 2, 1080 ** 2 ) ='} );
    $t->exit_is( 0, qq{./c 'sqrt( 1920 ** 2, 1080 ** 2 ) ='} );
    $t->stdout_is( qq{( 1920, 1080 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'hypot( 1920, 1080 )='} );
    $t->exit_is( 0, qq{./c 'hypot( 1920, 1080 )='} );
    $t->stdout_is( qq{2202.90717008\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angle_deg( 1920, 1080 )='} );
    $t->exit_is( 0, qq{./c 'angle_deg( 1920, 1080 )='} );
    $t->stdout_is( qq{29.3577535428\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angle_deg( 1920, 1080, 0 )='} );
    $t->exit_is( 0, qq{./c 'angle_deg( 1920, 1080, 0 )='} );
    $t->stdout_is( qq{29.3577535428\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angle_deg( 1920, 1080, 1 )='} );
    $t->exit_is( 0, qq{./c 'angle_deg( 1920, 1080, 1 )='} );
    $t->stdout_is( qq{60.6422464572\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dist_between_points( -50, -50, 50, 50 )='} );
    $t->exit_is( 0, qq{./c 'dist_between_points( -50, -50, 50, 50 )='} );
    $t->stdout_is( qq{141.421356237\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dist_between_points( -50, -50, -50, 50, 50 )='} );
    $t->exit_isnt( 0, qq{./c 'dist_between_points( -50, -50, -50, 50, 50 )='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: dist_between_points: \$argc=5: Invalid number of arguments\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dist_between_points( -50, -50, -50, 50, 50, 50 )='} );
    $t->exit_is( 0, qq{./c 'dist_between_points( -50, -50, -50, 50, 50, 50 )='} );
    $t->stdout_is( qq{173.205080757\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'midpt_between_points( -50, -50, 50, 50 )='} );
    $t->exit_is( 0, qq{./c 'midpt_between_points( -50, -50, 50, 50 )='} );
    $t->stdout_is( qq{( 0, 0 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'midpt_between_points( -50, -50, -50, 50, 50 )='} );
    $t->exit_isnt( 0, qq{./c 'midpt_between_points( -50, -50, -50, 50, 50 )='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: midpt_between_points: \$argc=5: Invalid number of arguments\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'midpt_between_points( -50, -50, -50, 50, 50, 50 )='} );
    $t->exit_is( 0, qq{./c 'midpt_between_points( -50, -50, -50, 50, 50, 50 )='} );
    $t->stdout_is( qq{( 0, 0, 0 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angle_between_points( -50, -50, 50, 75 )='} );
    $t->exit_is( 0, qq{./c 'angle_between_points( -50, -50, 50, 75 )='} );
    $t->stdout_is( qq{51.3401917459\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angle_between_points( -50, -50, 50, 75, 0 )='} );
    $t->exit_is( 0, qq{./c 'angle_between_points( -50, -50, 50, 75, 0 )='} );
    $t->stdout_is( qq{51.3401917459\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angle_between_points( -50, -50, 50, 75, 1 )='} );
    $t->exit_is( 0, qq{./c 'angle_between_points( -50, -50, 50, 75, 1 )='} );
    $t->stdout_is( qq{38.6598082541\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angle_between_points( 50, -50, -50, 75, 1 )='} );
    $t->exit_is( 0, qq{./c 'angle_between_points( 50, -50, -50, 75, 1 )='} );
    $t->stdout_is( qq{321.340191746\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angle_between_points( -50, -50, -50, 50, 75, 50 )='} );
    $t->exit_is( 0, qq{./c 'angle_between_points( -50, -50, -50, 50, 75, 50 )='} );
    $t->stdout_is( qq{( 51.3401917459, 31.9928170002 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angle_between_points( -50, -50, -50, 50, 75, 50, 0 )='} );
    $t->exit_is( 0, qq{./c 'angle_between_points( -50, -50, -50, 50, 75, 50, 0 )='} );
    $t->stdout_is( qq{( 51.3401917459, 31.9928170002 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angle_between_points( -50, -50, -50, 50, 75, 50, 1 )='} );
    $t->exit_is( 0, qq{./c 'angle_between_points( -50, -50, -50, 50, 75, 50, 1 )='} );
    $t->stdout_is( qq{( 38.6598082541, 31.9928170002 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angle_between_points( 50, -50, -50, -50, 75, 50, 1 )='} );
    $t->exit_is( 0, qq{./c 'angle_between_points( 50, -50, -50, -50, 75, 50, 1 )='} );
    $t->stdout_is( qq{( 321.340191746, 31.9928170002 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'vector_angle( 100, 100, 100, 0 )'} );
    $t->exit_is( 0, qq{./c 'vector_angle( 100, 100, 100, 0 )'} );
    $t->stdout_is( qq{45\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'vector_angle( 100, 0, 100, 100, 1 )'} );
    $t->exit_is( 0, qq{./c 'vector_angle( 100, 0, 100, 100, 1 )'} );
    $t->stdout_is( qq{0.785398163397\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'vector_angle( 2309627.42153, -5833452.97682, 1143792.85864, -3959659.21279, 3350075.51702, 3699524.90488 )'} );
    $t->exit_is( 0, qq{./c 'vector_angle( 2309627.42153, -5833452.97682, 1143792.85864, -3959659.21279, 3350075.51702, 3699524.90488 )'} );
    $t->stdout_is( qq{127.008055363\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'vector_angle( -3959659.21279, 3350075.51702, 3699524.90488, 2309627.42153, -5833452.97682, 1143792.85864, 1 )'} );
    $t->exit_is( 0, qq{./c 'vector_angle( -3959659.21279, 3350075.51702, 3699524.90488, 2309627.42153, -5833452.97682, 1143792.85864, 1 )'} );
    $t->stdout_is( qq{2.21670874265\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'vector_angle( -100, -100, 100, -100, 0 )'} );
    $t->exit_is( 0, qq{./c 'vector_angle( -100, -100, 100, -100, 0 )'} );
    $t->stdout_is( qq{90\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dist_between_points( geo2xyz( deg2rad( 35.6, 139.0 ), -20 * 1000 ), geo2xyz( deg2rad( 35.68129, 139.76706 ) ) ) / 1000'} );
    $t->exit_is( 0, qq{./c 'dist_between_points( geo2xyz( deg2rad( 35.6, 139.0 ), -20 * 1000 ), geo2xyz( deg2rad( 35.68129, 139.76706 ) ) ) / 1000'} );
    $t->stdout_is( qq{72.7492079698\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sqrt(power(2, 100)+power(2, 100))='} );
    $t->exit_is( 0, qq{./c 'sqrt(power(2, 100)+power(2, 100))='} );
    $t->stdout_is( qq{1592262918131443.25\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'power(2+1,2*2)='} );
    $t->exit_is( 0, qq{./c 'power(2+1,2*2)='} );
    $t->stdout_is( qq{81\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'power(6/2,power(2,1)*2)='} );
    $t->exit_is( 0, qq{./c 'power(6/2,power(2,1)*2)='} );
    $t->stdout_is( qq{81\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'power(-1+2**2,power(2,1)*2)='} );
    $t->exit_is( 0, qq{./c 'power(-1+2**2,power(2,1)*2)='} );
    $t->stdout_is( qq{81\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'power(1+sqrt(4),power(2,1)*2)='} );
    $t->exit_is( 0, qq{./c 'power(1+sqrt(4),power(2,1)*2)='} );
    $t->stdout_is( qq{81\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0.22*10**(-6)='} );
    $t->exit_is( 0, qq{./c '0.22*10**(-6)='} );
    $t->stdout_is( qq{0.00000022\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ｄｅｇ２ｒａｄ（１８０）＝'} );
    $t->exit_is( 0, qq{./c 'ｄｅｇ２ｒａｄ（１８０）＝'} );
    $t->stdout_is( qq{3.14159265359\n} );       ## 3.1415926535897932384626433832795
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ｒａｄ２ｄｅｇ（ｐｉ／２）＝'} );
    $t->exit_is( 0, qq{./c 'ｒａｄ２ｄｅｇ（ｐｉ／２）＝'} );
    $t->stdout_is( qq{90\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '1/cos(deg2rad(45))='} );
    $t->exit_is( 0, qq{./c '1/cos(deg2rad(45))='} );
    $t->stdout_is( qq{1.41421356237\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '１' 'cos(deg2rad(45))'} );
    $t->exit_is( 0, qq{./c '１' 'cos(deg2rad(45))'} );
    $t->stdout_is( qq{0.707106781187\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '1080/sin(deg2rad(45))='} );
    $t->exit_is( 0, qq{./c '1080/sin(deg2rad(45))='} );
    $t->stdout_is( qq{1527.35064736\n} );  ## 1527.3506473629426527058238221465
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rad2deg(asin(1080/1527.3506473629426527058238221465))='} );
    $t->exit_is( 0, qq{./c 'rad2deg(asin(1080/1527.3506473629426527058238221465))='} );
    $t->stdout_is( qq{45\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '1920/cos(deg2rad(45))='} );
    $t->exit_is( 0, qq{./c '1920/cos(deg2rad(45))='} );
    $t->stdout_is( qq{2715.29003976\n} );  ## 2715.2900397563424936992423504826
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rad2deg(acos(1920/2715.2900397563424936992423504826))='} );
    $t->exit_is( 0, qq{./c 'rad2deg(acos(1920/2715.2900397563424936992423504826))='} );
    $t->stdout_is( qq{45\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rad2deg(atan(1080/1920))='} );
    $t->exit_is( 0, qq{./c 'rad2deg(atan(1080/1920))='} );
    $t->stdout_is( qq{29.3577535428\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rad2deg( 2.26892802759263, 2.0943951023932 )'} );
    $t->exit_is( 0, qq{./c 'rad2deg( 2.26892802759263, 2.0943951023932 )'} );
    $t->stdout_is( qq{( 130, 120 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '1920*tan(deg2rad(29.3577535427913))='} );
    $t->exit_is( 0, qq{./c '1920*tan(deg2rad(29.3577535427913))='} );
    $t->stdout_is( qq{1080\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    ## 大阪駅座標：北緯34度42分6.8秒 東経135度29分41.9秒
    ##             度分秒 34° 42′ 6.8″ N, 135° 29′ 41.9″ E
    ##             十進数 34.701889, 135.494972
    ## 北緯は+，東経も+。もし南緯なら-，西経なら-。
    $t = tests::Command->new( qq{./c 'dms2deg( 34, 42, 6.8 )'} );
    $t->exit_is( 0, qq{./c 'dms2deg( 34, 42, 6.8 )'} );
    $t->stdout_is( qq{34.7018888889\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2deg( 135, 29, 41.9 )'} );
    $t->exit_is( 0, qq{./c 'dms2deg( 135, 29, 41.9 )'} );
    $t->stdout_is( qq{135.494972222\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    ## 東京駅座標：北緯35度40分52秒 東経139度46分0秒
    ##             度分秒 35° 40′ 52″ N, 139° 46′ 0″ E
    ##             十進数 35.681111, 139.766667
    ## 北緯は+，東経も+。もし南緯なら-，西経なら-。
    $t = tests::Command->new( qq{./c 'dms2deg( 35, 40, 52 )'} );
    $t->exit_is( 0, qq{./c 'dms2deg( 35, 40, 52 )'} );
    $t->stdout_is( qq{35.6811111111\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2deg( 139, 46, 0 )'} );
    $t->exit_is( 0, qq{./c 'dms2deg( 139, 46, 0 )'} );
    $t->stdout_is( qq{139.766666667\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    ## Galapagos Islands: degrees: -0.3831, -90.42333
    $t = tests::Command->new( qq{./c 'dms2deg( -0, -22, -59.16 )'} );
    $t->exit_is( 0, qq{./c 'dms2deg( -0, -22, -59.16 )'} );
    $t->stdout_is( qq{-0.3831\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2deg( -90, -25, -23.9880000000255 )'} );
    $t->exit_is( 0, qq{./c 'dms2deg( -90, -25, -23.9880000000255 )'} );
    $t->stdout_is( qq{-90.42333\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2deg( 35, 40, 52, 139, 46, 0 )'} );
    $t->exit_is( 0, qq{./c 'dms2deg( 35, 40, 52, 139, 46, 0 )'} );
    $t->stdout_is( qq{( 35.6811111111, 139.766666667 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    ## 大阪駅
    $t = tests::Command->new( qq{./c 'dms2rad( 34, 42, 6.8 )'} );
    $t->exit_is( 0, qq{./c 'dms2rad( 34, 42, 6.8 )'} );
    $t->stdout_is( qq{0.605662217772\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2rad( 135, 29, 41.9 )'} );
    $t->exit_is( 0, qq{./c 'dms2rad( 135, 29, 41.9 )'} );
    $t->stdout_is( qq{2.36483338518\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    ## 東京駅
    $t = tests::Command->new( qq{./c 'dms2rad( 35, 40, 52 )'} );
    $t->exit_is( 0, qq{./c 'dms2rad( 35, 40, 52 )'} );
    $t->stdout_is( qq{0.622752869659\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2rad( 139, 46, 0 )'} );
    $t->exit_is( 0, qq{./c 'dms2rad( 139, 46, 0 )'} );
    $t->stdout_is( qq{2.43938851787\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    ## 大阪駅 → 東京駅
    $t = tests::Command->new( qq{./c 'dms2rad( 35, 40, 52 ) - dms2rad( 34, 42, 6.8 )'} );
    $t->exit_is( 0, qq{./c 'dms2rad( 35, 40, 52 ) - dms2rad( 34, 42, 6.8 )'} );
    $t->stdout_is( qq{0.017090651886\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2rad( 139, 46, 0 ) - dms2rad( 135, 29, 41.9 )'} );
    $t->exit_is( 0, qq{./c 'dms2rad( 139, 46, 0 ) - dms2rad( 135, 29, 41.9 )'} );
    $t->stdout_is( qq{0.074555132695\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    ## Galapagos Islands: degrees: -0.3831, -90.42333
    $t = tests::Command->new( qq{./c 'dms2rad( -0, -22, -59.16 )'} );
    $t->exit_is( 0, qq{./c 'dms2rad( -0, -22, -59.16 )'} );
    $t->stdout_is( qq{-0.006686356364\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2rad( -90, -25, -23.9880000000255 )'} );
    $t->exit_is( 0, qq{./c 'dms2rad( -90, -25, -23.9880000000255 )'} );
    $t->stdout_is( qq{-1.57818482912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2rad( -90, -25.399800000000425, 0 )'} );
    $t->exit_is( 0, qq{./c 'dms2rad( -90, -25.399800000000425, 0 )'} );
    $t->stdout_is( qq{-1.57818482912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2rad( -90.42333, 0, 0 )'} );
    $t->exit_is( 0, qq{./c 'dms2rad( -90.42333, 0, 0 )'} );
    $t->stdout_is( qq{-1.57818482912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2rad( -90, -25, -23.9880000000255, -90, -25, -23.9880000000255 )'} );
    $t->exit_is( 0, qq{./c 'dms2rad( -90, -25, -23.9880000000255, -90, -25, -23.9880000000255 )'} );
    $t->stdout_is( qq{( -1.57818482912, -1.57818482912 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2rad( -90, -25, -23.9880000000255, -90, -25 )'} );
    $t->exit_isnt( 0, qq{./c 'dms2rad( -90, -25, -23.9880000000255, -90, -25 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: dms2rad: \$arg_counter="5": Not a multiple of 3\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2rad( -90, -25 )'} );
    $t->exit_isnt( 0, qq{./c 'dms2rad( -90, -25 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: "dms2rad": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c '1 + ( 2 + ( 3 + dms2rad( -90, -25 ) ) )'} );
    $t->exit_isnt( 0, qq{./c '1 + ( 2 + ( 3 + dms2rad( -90, -25 ) ) )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: dms2rad: \$arg_counter="2": Not a multiple of 3\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'deg2dms( -18.76694 )'} );
    $t->exit_is( 0, qq{./c 'deg2dms( -18.76694 )'} );
    $t->stdout_is( qq{( -18, -46, -0.984000000006 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'deg2dms( 46.8691 )'} );
    $t->exit_is( 0, qq{./c 'deg2dms( 46.8691 )'} );
    $t->stdout_is( qq{( 46, 52, 8.76000000001 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'deg2dms( dms2deg( -18, -46.01640000000010388333333333333333, -0 ) )'} );
    $t->exit_is( 0, qq{./c 'deg2dms( dms2deg( -18, -46.01640000000010388333333333333333, -0 ) )'} );
    $t->stdout_is( qq{( -18, -46, -0.984000000006 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'deg2dms( dms2deg( 46, 52.1460000000001855, 0 ) )'} );
    $t->exit_is( 0, qq{./c 'deg2dms( dms2deg( 46, 52.1460000000001855, 0 ) )'} );
    $t->stdout_is( qq{( 46, 52, 8.76000000001 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'deg2dms( -0.3831 )'} );
    $t->exit_is( 0, qq{./c 'deg2dms( -0.3831 )'} );
    $t->stdout_is( qq{( -0, -22, -59.16 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2deg( deg2dms( -0.3831 ) )'} );
    $t->exit_is( 0, qq{./c 'dms2deg( deg2dms( -0.3831 ) )'} );
    $t->stdout_is( qq{-0.3831\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'deg2dms( 0.3831 )'} );
    $t->exit_is( 0, qq{./c 'deg2dms( 0.3831 )'} );
    $t->stdout_is( qq{( 0, 22, 59.16 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2deg( deg2dms( 0.3831 ) )'} );
    $t->exit_is( 0, qq{./c 'dms2deg( deg2dms( 0.3831 ) )'} );
    $t->stdout_is( qq{0.3831\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'deg2dms( 40.6983333333333, 143.595 )'} );
    $t->exit_is( 0, qq{./c 'deg2dms( 40.6983333333333, 143.595 )'} );
    $t->stdout_is( qq{( 40, 41, 53.9999999999, 143, 35, 42 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2dms( -0.3831, 0, 0 )'} );
    $t->exit_is( 0, qq{./c 'dms2dms( -0.3831, 0, 0 )'} );
    $t->stdout_is( qq{( -0, -22, -59.16 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2dms( 0.3831, 0, 0, -69.00439, 0, 0, 39.5822, 0, 0 )'} );
    $t->exit_is( 0, qq{./c 'dms2dms( 0.3831, 0, 0, -69.00439, 0, 0, 39.5822, 0, 0 )'} );
    $t->stdout_is( qq{( 0, 22, 59.16, -69, 0, -15.804, 39, 34, 55.92 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dms2dms( -30, -5 + 5.5, -24 )'} );
    $t->exit_is( 0, qq{./c 'dms2dms( -30, -5 + 5.5, -24 )'} );
    $t->stdout_is( qq{( -29, -59, -54 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_radius( deg2rad( 0 ) ) / 1000 ='} );
    $t->exit_is( 0, qq{./c 'geo_radius( deg2rad( 0 ) ) / 1000 ='} );
    $t->stdout_is( qq{6378.137\n}, qq{地球の赤道半径（km）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_radius( deg2rad( 35.68129 ) ) / 1000 ='} );
    $t->exit_is( 0, qq{./c 'geo_radius( deg2rad( 35.68129 ) ) / 1000 ='} );
    $t->stdout_is( qq{6370.90194344\n}, qq{地球が楕円である事を考慮して地球の中心から東京駅（地表）までの距離（km）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'radius_of_lat( deg2rad( 35.68129 ) ) / 1000 ='} );
    $t->exit_is( 0, qq{./c 'radius_of_lat( deg2rad( 35.68129 ) ) / 1000 ='} );
    $t->stdout_is( qq{5186.70483555\n}, qq{地球が楕円である事を考慮して東京駅を通る緯線の半径（km）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_distance_m( deg2rad( 35.68129 ), deg2rad( 139.76706 ), deg2rad( 34.70248 ), deg2rad( 135.49595 ) ) / 1000'} );
    $t->exit_is( 0, qq{./c 'geo_distance_m( deg2rad( 35.68129 ), deg2rad( 139.76706 ), deg2rad( 34.70248 ), deg2rad( 135.49595 ) ) / 1000'} );
    $t->stdout_is( qq{403.822719846\n}, qq{東京駅から大阪駅までの距離（km）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_distance_m( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) ) / 1000'} );
    $t->exit_is( 0, qq{./c 'geo_distance_m( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) ) / 1000'} );
    $t->stdout_is( qq{14056.1311832\n}, qq{東京駅から昭和基地までの距離（km）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_distance_km( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_distance_km( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->stdout_is( qq{14056.1311832\n}, qq{東京駅から昭和基地までの距離（km）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

#    $t = tests::Command->new( qq{./c 'geo_distance_km( deg2rad( -69.00439, 39.5822, -77.3169444444444, 39.7033333333333 ), 1 )'} );
#    $t->exit_is( 0, qq{./c 'geo_distance_km( deg2rad( -69.00439, 39.5822, -77.3169444444444, 39.7033333333333 ), 1 )'} );
#    $t->stdout_is( qq{924.322901757\n}, qq{昭和基地からドームふじ基地までの距離（km）, ハバーサイン (Haversine) 公式} );
#    $t->stderr_is( qq{}, qq{STDERR is silent.} );
#    undef( $t );
#
#    $t = tests::Command->new( qq{./c 'geo_distance_km( deg2rad( -69.00439, 39.5822, -77.3169444444444, 39.7033333333333 ), 2 )'} );
#    $t->exit_is( 0, qq{./c 'geo_distance_km( deg2rad( -69.00439, 39.5822, -77.3169444444444, 39.7033333333333 ), 2 )'} );
#    $t->stdout_is( qq{927.683443436\n}, qq{昭和基地からドームふじ基地までの距離（km）, ヒュベニ (Hubeny) の公式} );
#    $t->stderr_is( qq{}, qq{STDERR is silent.} );
#    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_azimuth( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_azimuth( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->stdout_is( qq{206.108012524\n}, qq{東京駅から昭和基地までの方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_azimuth( deg2rad( 51.50324, -0.1134, 43.64524, -79.38063 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_azimuth( deg2rad( 51.50324, -0.1134, 43.64524, -79.38063 ) )'} );
    $t->stdout_is( qq{294.538064998\n}, qq{ウォータールー駅からユニオン駅までの方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_dist_m_and_azimuth( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_dist_m_and_azimuth( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->stdout_is( qq{( 14056131.1832, 206.108012524 )\n}, qq{東京駅から昭和基地までの距離（m）と方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_dist_km_and_azimuth( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_dist_km_and_azimuth( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->stdout_is( qq{( 14056.1311832, 206.108012524 )\n}, qq{東京駅から昭和基地までの距離（km）と方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_rl_distance_m( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_rl_distance_m( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->stdout_is( qq{14484256.5649\n}, qq{東京駅から昭和基地までの等角航路の距離（m）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_rl_distance_km( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_rl_distance_km( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->stdout_is( qq{14484.2565649\n}, qq{東京駅から昭和基地までの等角航路の距離（km）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_rl_azimuth( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_rl_azimuth( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->stdout_is( qq{216.733277422\n}, qq{東京駅から昭和基地までの等角航路の方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_rl_azimuth( deg2rad( -0.3831, -90.42333, 35.68129, 139.76706 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_rl_azimuth( deg2rad( -0.3831, -90.42333, 35.68129, 139.76706 ) )'} );
    $t->stdout_is( qq{286.477790179\n}, qq{ガラパゴス諸島から東京駅。( \$dlon > pi )} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_rl_azimuth( deg2rad( 35.68129, 139.76706, -0.3831, -90.42333 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_rl_azimuth( deg2rad( 35.68129, 139.76706, -0.3831, -90.42333 ) )'} );
    $t->stdout_is( qq{106.477790179\n}, qq{東京駅からガラパゴス諸島。( \$dlon < -pi )} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_rl_dist_m_and_azimuth( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_rl_dist_m_and_azimuth( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->stdout_is( qq{( 14484256.5649, 216.733277422 )\n}, qq{東京駅から昭和基地までの等角航路の距離（m）と方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_rl_dist_km_and_azimuth( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_rl_dist_km_and_azimuth( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->stdout_is( qq{( 14484.2565649, 216.733277422 )\n}, qq{東京駅から昭和基地までの等角航路の距離（km）と方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_all_m( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_all_m( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->stdout_is( qq{( 14056131.1832, 206.108012524, 14484256.5649, 216.733277422 )\n}, qq{大圏航路（Great Circle）と 等角航路（Rhumb Line）（m）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_all_km( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->stdout_is( qq{( 14056.1311832, 206.108012524, 14484.2565649, 216.733277422 )\n}, qq{大圏航路（Great Circle）と 等角航路（Rhumb Line）（km）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_all_km( deg2rad( 51.50324, -0.1134, 51.50324, -0.1134 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( deg2rad( 51.50324, -0.1134, 51.50324, -0.1134 ) )'} );
    $t->stdout_is( qq{( 0, 0, 0, 0 )\n}, qq{同一地点の距離と方位角} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_all_km( deg2rad( 0, 90, 0, -90 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( deg2rad( 0, 90, 0, -90 ) )'} );
    $t->stdout_is( qq{( 19903.5933909, 270, 20037.5083428, 270 )\n}, qq{赤道上のケース} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_all_km( deg2rad( 0, 180, 0, -180 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( deg2rad( 0, 180, 0, -180 ) )'} );
    $t->stdout_is( qq{( 0, 0, 0, 0 )\n}, qq{対蹠点（真裏）, 経度の正規化（ー）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_all_km( deg2rad( 0, -180, 0, 180 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( deg2rad( 0, -180, 0, 180 ) )'} );
    $t->stdout_is( qq{( 0, 0, 0, 0 )\n}, qq{対蹠点（真裏）, 経度の正規化（＋）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_all_km( deg2rad( 0, 0, 45, -10 ) )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( deg2rad( 0, 0, 45, -10 ) )'} );
    $t->stdout_is( qq{( 5081.68969015, 350.091119424, 5082.78218063, 348.739975473 )\n}, qq{ラジアンの正規化（ー）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_all_km( 10, 10, -10, -10 )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( 10, 10, -10, -10 )'} );
    $t->stdout_is( qq{( 10045.2740731, 309.826898594, 10058.0659261, 316.502246503 )\n}, qq{引数（座標）の正規化} );
    $t->stderr_like( qr/^Coordinates out of range: /, qq{警告メッセージ} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_all_km( 1, 4, 2, -100 )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( 1, 4, 2, -100 )'} );
    $t->stdout_is( qq{( 1341.45302198, 319.995434444, 1346.08951591, 312.190223662 )\n}, qq{引数（座標）の正規化} );
    $t->stderr_like( qr/^Coordinates out of range: /, qq{警告メッセージ} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_all_km( 100, 100, -100, -100 )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( 100, 100, -100, -100 )'} );
    $t->stdout_is( qq{( 9315.0650115, 49.4032576339, 9323.62154307, 43.7610906052 )\n}, qq{引数（座標）の正規化} );
    $t->stderr_like( qr/^Coordinates out of range: /, qq{警告メッセージ} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'geo_all_km( 1, -4, 1, 4 )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( 1, -4, 1, 4 )'} );
    $t->stdout_is( qq{( 5386.30789906, 45.7429575198, 5930.42524018, 90 )\n}, qq{( P  A B  dec ) = ( 1  0 1  0 )} );
    $t->stderr_like( qr/^Coordinates out of range: /, qq{警告メッセージ} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'epoch2local( 1763999942 )'} );
    $t->exit_is( 0, qq{./c 'epoch2local( 1763999942 )'} );
    $t->stdout_is( qq{( 2025, 11, 25, 0, 59, 2 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'epoch2gmt( 1763999942 )'} );
    $t->exit_is( 0, qq{./c 'epoch2gmt( 1763999942 )'} );
    $t->stdout_is( qq{( 2025, 11, 24, 15, 59, 2 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'is_leap( 1996 )'} );
    $t->exit_is( 0, qq{./c 'is_leap( 1996 )'} );
    $t->stdout_is( qq{1\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'is_leap( 1999 )'} );
    $t->exit_is( 0, qq{./c 'is_leap( 1999 )'} );
    $t->stdout_is( qq{0\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'is_leap( 2000 )'} );
    $t->exit_is( 0, qq{./c 'is_leap( 2000 )'} );
    $t->stdout_is( qq{1\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'is_leap( 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000, 2100 )'} );
    $t->exit_is( 0, qq{./c 'is_leap( 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000, 2100 )'} );
    $t->stdout_is( qq{( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age( l2e( 2026-05-01 ), l2e( 2026-06-14 ) )'} );
    $t->exit_is( 0, qq{./c 'age( l2e( 2026-05-01 ), l2e( 2026-06-14 ) )'} );
    $t->stdout_is( qq{( 0, 44 )\n}, qq{平月の31日（5月）を正しくまたいで計算できているか} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age( l2e( 2025年12月25日 ), l2e( 2026-06-14 ) )'} );
    $t->exit_is( 0, qq{./c 'age( l2e( 2025年12月25日 ), l2e( 2026-06-14 ) )'} );
    $t->stdout_is( qq{( 0, 171 )\n}, qq{年をまたいでも、エポック秒ベースで正確な日数が引けているか} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age( l2e( 2024年2月28日 ), l2e( 2024年3月1日 ) )'} );
    $t->exit_is( 0, qq{./c 'age( l2e( 2024年2月28日 ), l2e( 2024年3月1日 ) )'} );
    $t->stdout_is( qq{( 0, 2 )\n}, qq{1日齢ではなく2日齢になること} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age( l2e( 2001年6月14日 ), l2e( 2026-06-14 ) )'} );
    $t->exit_is( 0, qq{./c 'age( l2e( 2001年6月14日 ), l2e( 2026-06-14 ) )'} );
    $t->stdout_is( qq{( 25, 0 )\n}, qq{当日なので、きっちり25歳になっていること} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age( l2e( 2001年6月15日 ), l2e( 2026-06-14 ) )'} );
    $t->exit_is( 0, qq{./c 'age( l2e( 2001年6月15日 ), l2e( 2026-06-14 ) )'} );
    $t->stdout_is( qq{( 24, 364 )\n}, qq{フライングして25歳にならず「24歳」を維持できていること} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age( l2e( 1999-03-02 ), l2e( 2020-03-01 ) )'} );
    $t->exit_is( 0, qq{./c 'age( l2e( 1999-03-02 ), l2e( 2020-03-01 ) )'} );
    $t->stdout_is( qq{( 20, 365 )\n}, qq{日齢の最大値} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age( l2e( 2026年6月15日 ), l2e( 2026-06-14 ) )'} );
    $t->exit_is( 0, qq{./c 'age( l2e( 2026年6月15日 ), l2e( 2026-06-14 ) )'} );
    $t->stdout_is( qq{( 0, -1 )\n}, qq{誕生日が未来} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age( l2e( 2026年06月14日 ), l2e( 2001-6-15 ) )'} );
    $t->exit_is( 0, qq{./c 'age( l2e( 2026年06月14日 ), l2e( 2001-6-15 ) )'} );
    $t->stdout_is( qq{( -24, -364 )\n}, qq{誕生日が未来} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age( l2e( 2000年1月1日 ) )'} );
    $t->exit_is( 0, qq{./c 'age( l2e( 2000年1月1日 ) )'} );
    $t->stdout_like( qr/^\( \d+, \d+ \)\n$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age_of_moon( 0, 1, 1 )'} );
    $t->exit_is( 0, qq{./c 'age_of_moon( 0, 1, 1 )'} );
    $t->stdout_is( qq{24\n}, qq{既存の挙動との変化を検知する為だけのテスト。西暦1900年より前や、西暦0年のような極端な過去のエポック秒を用いた計算なので非推奨の使い方。} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age_of_moon( 1900, 2, 28 )'} );
    $t->exit_is( 0, qq{./c 'age_of_moon( 1900, 2, 28 )'} );
    $t->stdout_is( qq{28.3\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age_of_moon( 1999, 12, 31 )'} );
    $t->exit_is( 0, qq{./c 'age_of_moon( 1999, 12, 31 )'} );
    $t->stdout_is( qq{23\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age_of_moon( 2000, 1, 1 )'} );
    $t->exit_is( 0, qq{./c 'age_of_moon( 2000, 1, 1 )'} );
    $t->stdout_is( qq{24\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age_of_moon( 2000, 2, 28 )'} );
    $t->exit_is( 0, qq{./c 'age_of_moon( 2000, 2, 28 )'} );
    $t->stdout_is( qq{23\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age_of_moon( 2000, 2, 29 )'} );
    $t->exit_is( 0, qq{./c 'age_of_moon( 2000, 2, 29 )'} );
    $t->stdout_is( qq{24\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age_of_moon( 2000, 03, 01 )'} );
    $t->exit_is( 0, qq{./c 'age_of_moon( 2000, 03, 01 )'} );
    $t->stdout_is( qq{25\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age_of_moon( 2025, 12, 19 )'} );
    $t->exit_is( 0, qq{./c 'age_of_moon( 2025, 12, 19 )'} );
    $t->stdout_is( qq{28.7\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age_of_moon( 2025, 12, 20 )'} );
    $t->exit_is( 0, qq{./c 'age_of_moon( 2025, 12, 20 )'} );
    $t->stdout_is( qq{0.2\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age_of_moon_instant( gmt2epoch( 1969年7月20日 20時17分40秒 ) )'} );
    $t->exit_is( 0, qq{./c 'age_of_moon_instant( gmt2epoch( 1969年7月20日 20時17分40秒 ) )'} );
    $t->stdout_is( qq{6.24701057982\n}, qq{アポロ11号が月面に着陸した時} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'local2epoch( 2000, 12, 31, 23, 59, 59 )'} );
    $t->exit_is( 0, qq{./c 'local2epoch( 2000, 12, 31, 23, 59, 59 )'} );
    $t->stdout_is( qq{978274799\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'local2epoch( ２０２６／３／１１　１６：００：０１ )'} );
    $t->exit_is( 0, qq{./c 'local2epoch( ２０２６／３／１１　１６：００：０１ )'} );
    $t->stdout_is( qq{1773212401\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'local2epoch( 2026-03-11 16:00:01 )'} );
    $t->exit_is( 0, qq{./c 'local2epoch( 2026-03-11 16:00:01 )'} );
    $t->stdout_is( qq{1773212401\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'local2epoch( 2026-03-11, 16:00:01 )'} );
    $t->exit_is( 0, qq{./c 'local2epoch( 2026-03-11, 16:00:01 )'} );
    $t->stdout_is( qq{1773212401\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gmt2epoch( 2000, 12, 31, 23, 59, 59 )'} );
    $t->exit_is( 0, qq{./c 'gmt2epoch( 2000, 12, 31, 23, 59, 59 )'} );
    $t->stdout_is( qq{978307199\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sec2dhms( local2epoch( 2030, 1, 1 ) - now )'} );
    $t->exit_is( 0, qq{./c 'sec2dhms( local2epoch( 2030, 1, 1 ) - now )'} );
    $t->stdout_like( qr/^\( \d+, \d+, \d+, \d+ \)\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sec2dhms( gmt2epoch( 2020, 1, 1 ) - now )'} );
    $t->exit_is( 0, qq{./c 'sec2dhms( local2epoch( 2020, 1, 1 ) - now )'} );
    $t->stdout_like( qr/^\( \-\d+, \-?\d+, \-?\d+, \-?\d+ \)\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sec2dhms( 0 )'} );
    $t->exit_is( 0, qq{./c 'sec2dhms( 0 )'} );
    $t->stdout_is( qq{( 0, 0, 0, 0 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'epoch2local( local2epoch( 2020, 1, 1, 15, 0, 0 ) + dhms2sec( 10 ) )'} );
    $t->exit_is( 0, qq{./c 'epoch2local( local2epoch( 2020, 1, 1, 15, 0, 0 ) + dhms2sec( 10 ) )'} );
    $t->stdout_is( qq{( 2020, 1, 11, 15, 0, 0 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'epoch2local( local2epoch( 2020, 1, 1, 15, 0, 0 ) + dhms2sec( -2, 3, -4, 5 ) )'} );
    $t->exit_is( 0, qq{./c 'epoch2local( local2epoch( 2020, 1, 1, 15, 0, 0 ) + dhms2sec( -2, 3, -4, 5 ) )'} );
    $t->stdout_is( qq{( 2019, 12, 30, 17, 56, 5 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dhms2dhms( 0, 24 / SAKUBOU )'} );
    $t->exit_is( 0, qq{./c 'dhms2dhms( 0, 24 / SAKUBOU )'} );
    $t->stdout_is( qq{( 0, 0, 48, 45.7797882084 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ri2meter( 1 )'} );
    $t->exit_is( 0, qq{./c 'ri2meter( 1 )'} );
    $t->stdout_is( qq{3927.27272727\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'meter2ri( 4000 )'} );
    $t->exit_is( 0, qq{./c 'meter2ri( 4000 )'} );
    $t->stdout_is( qq{1.01851851852\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'mile2meter( 1 )'} );
    $t->exit_is( 0, qq{./c 'mile2meter( 1 )'} );
    $t->stdout_is( qq{1609.344\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'meter2mile( 2000 )'} );
    $t->exit_is( 0, qq{./c 'meter2mile( 2000 )'} );
    $t->stdout_is( qq{1.24274238447\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'nautical_mile2meter( 1 )'} );
    $t->exit_is( 0, qq{./c 'nautical_mile2meter( 1 )'} );
    $t->stdout_is( qq{1852\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'meter2nautical_mile( 2000 )'} );
    $t->exit_is( 0, qq{./c 'meter2nautical_mile( 2000 )'} );
    $t->stdout_is( qq{1.07991360691\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'inch2mm( 0.25 )'} );
    $t->exit_is( 0, qq{./c 'inch2mm( 0.25 )'} );
    $t->stdout_is( qq{6.35\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'mm2inch( 12.7 )'} );
    $t->exit_is( 0, qq{./c 'mm2inch( 12.7 )'} );
    $t->stdout_is( qq{0.5\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'pound2gram( 1 )'} );
    $t->exit_is( 0, qq{./c 'pound2gram( 1 )'} );
    $t->stdout_is( qq{453.59237\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gram2pound( 500 )'} );
    $t->exit_is( 0, qq{./c 'gram2pound( 500 )'} );
    $t->stdout_is( qq{1.10231131092\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ounce2gram( 1 )'} );
    $t->exit_is( 0, qq{./c 'ounce2gram( 1 )'} );
    $t->stdout_is( qq{28.349523125\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gram2ounce( 30 )'} );
    $t->exit_is( 0, qq{./c 'gram2ounce( 30 )'} );
    $t->stdout_is( qq{1.05821885849\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'kgf2newton( 6.5 )'} );
    $t->exit_is( 0, qq{./c 'kgf2newton( 6.5 )'} );
    $t->stdout_is( qq{63.743225\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'newton2kgf( 64 )'} );
    $t->exit_is( 0, qq{./c 'newton2kgf( 64 )'} );
    $t->stdout_is( qq{6.52618376306\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'laptimer( 0 )'} );
    $t->exit_is( 0, qq{./c 'laptimer( 0 )'} );
    $t->stdout_is( qq{0\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo '' | ./c 'laptimer( 1 )'} );
    $t->exit_is( 0, qq{echo '' | ./c 'laptimer( 1 )'} );
    $t->stdout_like( qr/^Elaps         Date\-Time\n/ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{printf "\n\n" | ./c 'laptimer( 2 )'} );
    $t->exit_is( 0, qq{printf "\n\n" | ./c 'laptimer( 2 )'} );
    $t->stdout_like( qr/^Lap  Split\-Time    Lap\-Time      Date\-Time\n/ );
    $t->stdout_like( qr/\r2\/2  00:00:00\./ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{printf "\nq\n" | ./c 'laptimer( 10 )'} );
    $t->exit_is( 0, qq{printf "\nq\n" | ./c 'laptimer( 10 )'} );
    $t->stdout_like( qr/^Lap    Split\-Time    Lap\-Time      Date\-Time\n/ );
    $t->stdout_like( qr/\r 2\/10  00:00:00\./ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo '' | ./c 'timer( local2epoch( 2025, 1, 1  ) )'} );
    $t->exit_is( 0, qq{echo '' | ./c 'timer( local2epoch( 2025, 1, 1  ) )'} );
    $t->stdout_like( qr/^2025\-01\-01 00:00:00\.000  TARGET\n/ );
    $t->stdout_like( qr/\n\d+\.\d+\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo '' | ./c 'timer( 3 )'} );
    $t->exit_is( 0, qq{echo '' | ./c 'timer( 3 )'} );
    $t->stdout_like( qr/^20\d{2}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}  TARGET\n/ );
    $t->stdout_like( qr/\n\-\d+\.\d+\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'timer( 1 )'} );
    $t->exit_is( 0, qq{./c 'timer( 1 )'} );
    $t->stdout_like( qr/^20\d{2}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}  TARGET\n/ );
    $t->stdout_like( qr/\n\d+\.\d+\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo '' | ./c 'stopwatch()'} );
    $t->exit_is( 0, qq{echo '' | ./c 'stopwatch()'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo '' | ./c 'bpm( 10, stopwatch() )'} );
    $t->exit_is( 0, qq{echo '' | ./c 'bpm( 10, stopwatch() )'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo '' | ./c 'bpm15()'} );
    $t->exit_is( 0, qq{echo '' | ./c 'bpm15()'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo '' | ./c 'bpm30()'} );
    $t->exit_is( 0, qq{echo '' | ./c 'bpm30()'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo '' | ./c 'tachymeter( stopwatch() )'} );
    $t->exit_is( 0, qq{echo '' | ./c 'tachymeter( stopwatch() )'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo '' | ./c 'telemeter( stopwatch() )'} );
    $t->exit_is( 0, qq{echo '' | ./c 'telemeter( stopwatch() )'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'telemeter_m( 8 )'} );
    $t->exit_is( 0, qq{./c 'telemeter_m( 8 )'} );
    $t->stdout_is( qq{2725.2\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'telemeter_km( 8 )'} );
    $t->exit_is( 0, qq{./c 'telemeter_km( 8 )'} );
    $t->stdout_is( qq{2.7252\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'telemeter( 8, 20 )'} );
    $t->exit_is( 0, qq{./c 'telemeter( 8, 20 )'} );
    $t->stdout_is( qq{2749.6\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'exp( -2.3 )'} );
    $t->exit_is( 0, qq{./c 'exp( -2.3 )'} );
    $t->stdout_is( qq{0.100258843723\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'exp( -2 )'} );
    $t->exit_is( 0, qq{./c 'exp( -2 )'} );
    $t->stdout_is( qq{0.135335283237\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'exp( -1 )'} );
    $t->exit_is( 0, qq{./c 'exp( -1 )'} );
    $t->stdout_is( qq{0.367879441171\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'exp( 0 )'} );
    $t->exit_is( 0, qq{./c 'exp( 0 )'} );
    $t->stdout_is( qq{1\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'exp( 1 )'} );
    $t->exit_is( 0, qq{./c 'exp( 1 )'} );
    $t->stdout_is( qq{2.71828182846\n}, qq{Napier's number} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'exp( 2 )'} );
    $t->exit_is( 0, qq{./c 'exp( 2 )'} );
    $t->stdout_is( qq{7.38905609893\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'exp( 2.3 )'} );
    $t->exit_is( 0, qq{./c 'exp( 2.3 )'} );
    $t->stdout_is( qq{9.97418245481\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'exp( -1, 0, 1 )'} );
    $t->exit_is( 0, qq{./c 'exp( -1, 0, 1 )'} );
    $t->stdout_is( qq{( 0.367879441171, 1, 2.71828182846 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log(3)='} );
    $t->exit_is( 0, qq{./c 'log(3)='} );
    $t->stdout_is( qq{1.09861228867\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log( -123.456 ) ='} );
    $t->exit_isnt( 0, qq{./c 'log( -123.456 ) ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: log\( -123.456 \): Must be a positive number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log(0)/log(2)='} );
    $t->exit_isnt( 0, qq{./c 'log(0)/log(2)='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: log\( 0 \): Must be a positive number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log(~0+1)/log(2)='} );
    $t->exit_is( 0, qq{./c 'log(~0+1)/log(2)='} );
    $expect = qq{64 [ = 0x40 ]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{32 [ = 0x20 ]\n};
    }
    $t->stdout_is( $expect, qq{${UV_bit_width}bit: perlの整数は固定幅ではないが基本は64bitが多いはず。} );
    $t->stderr_is( qq{}, qq{"~0+1": perlの整数は固定幅ではないので桁溢れしない。} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log( 10, 100, 1000 )'} );
    $t->exit_is( 0, qq{./c 'log( 10, 100, 1000 )'} );
    $t->stdout_is( qq{( 2.30258509299, 4.60517018599, 6.90775527898 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'exp2( 10 )'} );
    $t->exit_is( 0, qq{./c 'exp2( 10 )'} );
    $t->stdout_is( qq{1024\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'exp2( 8, 16, 32 )'} );
    $t->exit_is( 0, qq{./c 'exp2( 8, 16, 32 )'} );
    $t->stdout_is( qq{( 256, 65536, 4294967296 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log2( -123.456 ) ='} );
    $t->exit_isnt( 0, qq{./c 'log2( -123.456 ) ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: log2\( -123.456 \): Must be a positive number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log2(0)='} );
    $t->exit_isnt( 0, qq{./c 'log2(0)='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: log2\( 0 \): Must be a positive number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log2( 4294967296 )'} );
    $t->exit_is( 0, qq{./c 'log2( 4294967296 )'} );
    $t->stdout_is( qq{32\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log2( 256, 65536, 4294967296 )'} );
    $t->exit_is( 0, qq{./c 'log2( 256, 65536, 4294967296 )'} );
    $t->stdout_is( qq{( 8, 16, 32 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'exp10( 5 )'} );
    $t->exit_is( 0, qq{./c 'exp10( 5 )'} );
    $t->stdout_is( qq{100000\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'exp10( 1, 2, 3 )'} );
    $t->exit_is( 0, qq{./c 'exp10( 1, 2, 3 )'} );
    $t->stdout_is( qq{( 10, 100, 1000 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log10( -123.456 ) ='} );
    $t->exit_isnt( 0, qq{./c 'log10( -123.456 ) ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: log10\( -123.456 \): Must be a positive number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log10(0)='} );
    $t->exit_isnt( 0, qq{./c 'log10(0)='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: log10\( 0 \): Must be a positive number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log10( 4294967296 )'} );
    $t->exit_is( 0, qq{./c 'log10( 4294967296 )'} );
    $t->stdout_is( qq{9.63295986125\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'log10( 10, 100, 1000 )'} );
    $t->exit_is( 0, qq{./c 'log10( 10, 100, 1000 )'} );
    $t->stdout_is( qq{( 1, 2, 3 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'pow_inv( ~0+1, 2 )'} );
    $t->exit_is( 0, qq{./c 'pow_inv( ~0+1, 2 )'} );
    $expect = qq{64 [ = 0x40 ]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{32 [ = 0x20 ]\n};
    }
    $t->stdout_is( $expect, qq{${UV_bit_width}bit: perlの整数は固定幅ではないが基本は64bitが多いはず。} );
    $t->stderr_is( qq{}, qq{"~0+1": perlの整数は固定幅ではないので桁溢れしない。} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linstep( ~0, -1, 2 )'} );
    $t->exit_is( 0, qq{./c 'linstep( ~0, -1, 2 )'} );
    $expect = qq{( 18446744073709551615, 18446744073709551614 ) [ = ( -1, -2 ) ] [ = ( 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFE ) ]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{( 4294967295, 4294967294 ) [ = ( -1, -2 ) ] [ = ( 0xFFFFFFFF, 0xFFFFFFFE ) ]\n};
    }
    $t->stdout_is( $expect );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'pow_inv( 4294967296, 2 )'} );
    $t->exit_is( 0, qq{./c 'pow_inv( 4294967296, 2 )'} );
    $t->stdout_is( qq{32\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'pow_inv( 4294967297, 2 )'} );
    $t->exit_is( 0, qq{./c 'pow_inv( 4294967297, 2 )'} );
    $t->stdout_is( qq{32.0000000003\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '2PI10='} );
    $t->exit_is( 0, qq{./c '2PI10='} );
    $t->stdout_is( qq{62.8318530718\n} );  ## 62.83185307179586476925286766559
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '2･PI･10='} );
    $t->exit_is( 0, qq{./c '2PI10='} );
    $t->stdout_is( qq{62.8318530718\n} );  ## 62.83185307179586476925286766559
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '２・ＰＩ・１０＝'} );
    $t->exit_is( 0, qq{./c '2PI10='} );
    $t->stdout_is( qq{62.8318530718\n} );  ## 62.83185307179586476925286766559
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '2PI10'} );
    $t->exit_is( 0, qq{./c '2PI10'} );
    $t->stdout_is( qq{62.8318530718\n} );  ## 62.83185307179586476925286766559
    undef( $t );

    $t = tests::Command->new( qq{./c ' ' '2PI10='} );
    $t->exit_is( 0, qq{./c ' ' '2PI10='} );
    $t->stdout_is( qq{62.8318530718\n} );  ## 62.83185307179586476925286766559
    undef( $t );

    $t = tests::Command->new( qq{./c '2PI10=' ' '} );
    $t->exit_is( 0, qq{./c '2PI10=' ' '} );
    $t->stdout_is( qq{62.8318530718\n} );  ## 62.83185307179586476925286766559
    undef( $t );

    $t = tests::Command->new( qq{./c '2PI10=' ' ' -d} );
    $t->exit_is( 0, qq{./c '2PI10=' ' ' -d} );
    $t->stdout_like( qr/\n Result: 62\.8318530718\n$/ );  ## 62.83185307179586476925286766559
    undef( $t );

    $t = tests::Command->new( qq{./c ')(='} );
    $t->exit_isnt( 0, qq{./c ')(='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: parser: error: "BEGIN", "\)": Wrong combination\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c '123' '2(='} );
    $t->exit_isnt( 0, qq{./c '123' '2(='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: parser: error: The position of the "\)" is incorrect\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c '123' '2(2='} );
    $t->exit_isnt( 0, qq{./c '123' '2(2='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: parser: error: The position of the "\)" is incorrect\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c '15/5='} );
    $t->exit_is( 0, qq{./c '15/5='} );
    $t->stdout_is( qq{3\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '5/0='} );
    $t->exit_isnt( 0, qq{./c '5/0='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: "5 \/ 0": Illegal division by zero\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c '5%-1.0='} );
    $t->exit_is( 0, qq{./c '5%-1.0='} );
    $t->stdout_is( qq{0\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '5%-0.9='} );
    $t->exit_is( 0, qq{./c '5%-0.9='} );
    $t->stdout_is( qq{0.5\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '5%0='} );
    $t->exit_isnt( 0, qq{./c '5%0='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: Division by zero: Illegal modulus operand\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c '5%0.9='} );
    $t->exit_is( 0, qq{./c '5%0.9='} );
    $t->stdout_is( qq{0.5\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '5%1.0='} );
    $t->exit_is( 0, qq{./c '5%1.0='} );
    $t->stdout_is( qq{0\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '10 % 3'} );
    $t->exit_is( 0, qq{./c '10 % 3'} );
    $t->stdout_is( qq{1\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '10 % -3'} );
    $t->exit_is( 0, qq{./c '10 % -3'} );
    $t->stdout_is( qq{1\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '-10 % 3'} );
    $t->exit_is( 0, qq{./c '-10 % 3'} );
    $t->stdout_is( qq{-1\n}, qq{-10} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '-10 % -3'} );
    $t->exit_is( 0, qq{./c '-10 % -3'} );
    $t->stdout_is( qq{-1\n}, qq{-10} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '10.987 % 3'} );
    $t->exit_is( 0, qq{./c '10.987 % 3'} );
    $t->stdout_is( qq{1.987\n}, qq{-10} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '12(3 2)2='} );
    $t->exit_is( 0, qq{./c '12(3 2)2='} );
    $t->stdout_is( qq{144\n}, qq{-10} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '2 3 4 ='} );
    $t->exit_is( 0, qq{./c '2 3 4 ='} );
    $t->stdout_is( qq{24\n}, qq{-10} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '-10='} );
    $t->exit_is( 0, qq{./c '-10='} );
    $t->stdout_is( qq{-10\n}, qq{-10} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '='} );
    $t->exit_is( 0, qq{./c '='} );
    $t->stdout_is( qq{0\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'testfunc(10)='} );
    $t->exit_isnt( 0, qq{./c 'testfunc(10)='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
#    $t->stderr_like( qr/^c: error: "testfunc": The function is not defined\.\n/ );
    $t->stderr_is( qq{c: parser: error: "testfunc": There is a problem with the calculation formula.\n} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'unknownfunc(10)='} );
    $t->exit_isnt( 0, qq{./c 'unknownfunc(10)='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: lexer: error: "unknownfunc\(\)": unknown function\.\n/ );
    $t->stderr_like( qr/\nc: lexer: info: Supported functions: / );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rad2deg(atan2(100, 200='} );
    $t->exit_is( 0, qq{./c 'rad2deg(atan2(100, 200='} );
    $t->stdout_is( qq{26.5650511771\n} );
    $t->stderr_like( qr/^c: parser: warn: "atan2\(": "\)" may be incorrect\.\n/ );
    $t->stderr_like( qr/\nc: parser: warn: "rad2deg\(": "\)" may be incorrect\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rad2deg(atan2(100, 200)='} );
    $t->exit_is( 0, qq{./c 'rad2deg(atan2(100, 200)='} );
    $t->stdout_is( qq{26.5650511771\n} );
    $t->stderr_unlike( qr/^c: parser: warn: "atan2\(": "\)" may be incorrect\.\n/ );
    $t->stderr_like( qr/^c: parser: warn: "rad2deg\(": "\)" may be incorrect\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rad2deg(atan2(100, 200))='} );
    $t->exit_is( 0, qq{./c 'rad2deg(atan2(100, 200))='} );
    $t->stdout_is( qq{26.5650511771\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'fmod( 10.234, 3 )'} );
    $t->exit_is( 0, qq{./c 'fmod( 10.234, 3 )'} );
    $t->stdout_is( qq{1.234\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'fmod( 10, -1.2 )'} );
    $t->exit_is( 0, qq{./c 'fmod( 10, -1.2 )'} );
    $t->stdout_is( qq{0.4\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'math_mod( -100, -10 )'} );
    $t->exit_is( 0, qq{./c 'math_mod( -100, -10 )'} );
    $t->stdout_is( qq{0\n}, qq{( A B C D ) = ( 0 0 0 1 )} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'math_mod( 120, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'math_mod( 120, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: Division by zero: Illegal modulus operand\.\n/, qq{error message} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'math_mod( 10, -1.2 )'} );
    $t->exit_is( 0, qq{./c 'math_mod( 10, -1.2 )'} );
    $t->stdout_is( qq{-0.8\n}, qq{( A B C D ) = ( 0 0 1 1 )} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'math_mod( -1.2, 1.2 )'} );
    $t->exit_is( 0, qq{./c 'math_mod( -1.2, 1.2 )'} );
    $t->stdout_is( qq{0\n}, qq{( A B C D ) = ( 0 1 0 0 )} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'math_mod( 1.2, 12.1 )'} );
    $t->exit_is( 0, qq{./c 'math_mod( 1.2, 12.1 )'} );
    $t->stdout_is( qq{1.2\n}, qq{( A B C D ) = ( 0 1 1 0 )} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'math_mod( -120, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'math_mod( -120, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: Division by zero: Illegal modulus operand\.\n/, qq{error message} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'math_mod( -10, -1.2 )'} );
    $t->exit_is( 0, qq{./c 'math_mod( -10, -1.2 )'} );
    $t->stdout_is( qq{-0.4\n}, qq{( A B C D ) = ( 1 0 0 1 )} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'math_mod( -1.2, 12.1 )'} );
    $t->exit_is( 0, qq{./c 'math_mod( -1.2, 12.1 )'} );
    $t->stdout_is( qq{10.9\n}, qq{( A B C D ) = ( 1 1 0 0 )} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'abs(-29.3577535427913)='} );
    $t->exit_is( 0, qq{./c 'abs(-29.3577535427913)='} );
    $t->stdout_is( qq{29.3577535428\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '( abs( -1.2, 1.2 ) )'} );
    $t->exit_is( 0, qq{./c '( abs( -1.2, 1.2 ) )'} );
    $t->stdout_is( qq{( 1.2, 1.2 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'int(10/3*100+0.5)/100='} );
    $t->exit_is( 0, qq{./c 'int(10/3*100+0.5)/100='} );
    $t->stdout_is( qq{3.33\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '( int( -1.2, 1.2 ) )'} );
    $t->exit_is( 0, qq{./c '( int( -1.2, 1.2 ) )'} );
    $t->stdout_is( qq{( -1, 1 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'floor( 192.168 ) ='} );
    $t->exit_is( 0, qq{./c 'floor( 192.168 ) ='} );
    $t->stdout_is( qq{192\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'floor( -192.168 ) ='} );
    $t->exit_is( 0, qq{./c 'floor( -192.168 ) ='} );
    $t->stdout_is( qq{-193\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '( floor( -1.2, 1.2 ) )'} );
    $t->exit_is( 0, qq{./c '( floor( -1.2, 1.2 ) )'} );
    $t->stdout_is( qq{( -2, 1 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ceil( 192.168 ) ='} );
    $t->exit_is( 0, qq{./c 'ceil( 192.168 ) ='} );
    $t->stdout_is( qq{193\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ceil( -192.168 ) ='} );
    $t->exit_is( 0, qq{./c 'ceil( -192.168 ) ='} );
    $t->stdout_is( qq{-192\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '( ceil( -1.2, 1.2 ) )'} );
    $t->exit_is( 0, qq{./c '( ceil( -1.2, 1.2 ) )'} );
    $t->stdout_is( qq{( -1, 2 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rounddown( 192.168 ) ='} );
    $t->exit_isnt( 0, qq{./c 'rounddown( 192.168 ) ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: rounddown\(\): \$argc=1: Insufficient arguments\.\n/, qq{Insufficient arguments.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'round( 192.168 ) ='} );
    $t->exit_isnt( 0, qq{./c 'round( 192.168 ) ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: round\(\): \$argc=1: Insufficient arguments\.\n/, qq{Insufficient arguments.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'roundup( 192.168 ) ='} );
    $t->exit_isnt( 0, qq{./c 'roundup( 192.168 ) ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: roundup\(\): \$argc=1: Insufficient arguments\.\n/, qq{Insufficient arguments.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rounddown( 192.168, 2 ) ='} );
    $t->exit_is( 0, qq{./c 'rounddown( 192.168, 2 ) ='} );
    $t->stdout_is( qq{192.16\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'round( 192.168, 2 ) ='} );
    $t->exit_is( 0, qq{./c 'round( 192.168, 2 ) ='} );
    $t->stdout_is( qq{192.17\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'roundup( 192.168, 2 ) ='} );
    $t->exit_is( 0, qq{./c 'roundup( 192.168, 2 ) ='} );
    $t->stdout_is( qq{192.17\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rounddown( -192.168, 2 ) ='} );
    $t->exit_is( 0, qq{./c 'rounddown( -192.168, 2 ) ='} );
    $t->stdout_is( qq{-192.16\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'round( -192.168, 2 ) ='} );
    $t->exit_is( 0, qq{./c 'round( -192.168, 2 ) ='} );
    $t->stdout_is( qq{-192.17\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'roundup( -192.168, 2 ) ='} );
    $t->exit_is( 0, qq{./c 'roundup( -192.168, 2 ) ='} );
    $t->stdout_is( qq{-192.17\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rounddown( -192.168, 3 ) ='} );
    $t->exit_is( 0, qq{./c 'rounddown( -192.168, 3 ) ='} );
    $t->stdout_is( qq{-192.168\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'round( -192.168, 3 ) ='} );
    $t->exit_is( 0, qq{./c 'round( -192.168, 3 ) ='} );
    $t->stdout_is( qq{-192.168\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'roundup( -192.168, 3 ) ='} );
    $t->exit_is( 0, qq{./c 'roundup( -192.168, 3 ) ='} );
    $t->stdout_is( qq{-192.168\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rounddown( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 ) ='} );
    $t->exit_is( 0, qq{./c 'rounddown( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 ) ='} );
    $t->stdout_is( qq{( -1, -0.5, -0.4, 0, 0.4, 0.5, 1 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'round( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 ) ='} );
    $t->exit_is( 0, qq{./c 'round( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 ) ='} );
    $t->stdout_is( qq{( -1, -0.5, -0.4, 0, 0.4, 0.5, 1 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'roundup( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 ) ='} );
    $t->exit_is( 0, qq{./c 'roundup( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 ) ='} );
    $t->stdout_is( qq{( -1, -0.5, -0.4, 0, 0.4, 0.5, 1 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rounddown( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 ) ='} );
    $t->exit_is( 0, qq{./c 'rounddown( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 ) ='} );
    $t->stdout_is( qq{( -1, 0, 0, 0, 0, 0, 1 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'round( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 ) ='} );
    $t->exit_is( 0, qq{./c 'round( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 ) ='} );
    $t->stdout_is( qq{( -1, -1, 0, 0, 0, 1, 1 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'roundup( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 ) ='} );
    $t->exit_is( 0, qq{./c 'roundup( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 ) ='} );
    $t->stdout_is( qq{( -1, -1, -1, 0, 1, 1, 1 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'percentage( 2, 3 )'} );
    $t->exit_is( 0, qq{./c 'percentage( 2, 3 )'} );
    $t->stdout_is( qq{66.6666666667\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'percentage( 2, 3, 1 )'} );
    $t->exit_is( 0, qq{./c 'percentage( 2, 3, 1 )'} );
    $t->stdout_is( qq{66.7\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'percentage( 2, 3, 0 )'} );
    $t->exit_is( 0, qq{./c 'percentage( 2, 3, 0 )'} );
    $t->stdout_is( qq{67\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'percentage( 2, 3, -1 )'} );
    $t->exit_is( 0, qq{./c 'percentage( 2, 3, -1 )'} );
    $t->stdout_is( qq{70\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'percentage( 2 )'} );
    $t->exit_isnt( 0, qq{./c 'percentage( 2 )'} );
    $t->stdout_is( qq{} );
    $t->stderr_like( qr/^c: evaluator: error: "percentage": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'percentage()'} );
    $t->exit_isnt( 0, qq{./c 'percentage()'} );
    $t->stdout_is( qq{} );
    $t->stderr_like( qr/^c: evaluator: error: "percentage": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'percentage( 2, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'percentage( 2, 0 )'} );
    $t->stdout_is( qq{} );
    $t->stderr_like( qr/^c: evaluator: error: Illegal division by zero.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ratio_scaling( 3, 10, 20 )'} );
    $t->exit_is( 0, qq{./c 'ratio_scaling( 3, 10, 20 )'} );
    $t->stdout_is( qq{66.6666666667\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ratio_scaling( 3, 10, 20, 1 )'} );
    $t->exit_is( 0, qq{./c 'ratio_scaling( 3, 10, 20, 1 )'} );
    $t->stdout_is( qq{66.7\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ratio_scaling( 0, 10, 20 )'} );
    $t->exit_isnt( 0, qq{./c 'ratio_scaling( 0, 10, 20 )'} );
    $t->stdout_is( qq{} );
    $t->stderr_like( qr/^c: evaluator: error: Illegal division by zero.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'is_prime( 29 )'} );
    $t->exit_is( 0, qq{./c 'is_prime( 29 )'} );
    $t->stdout_is( qq{1\n}, qq{29は素数} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'is_prime( 29.1 )'} );
    $t->exit_is( 0, qq{./c 'is_prime( 29.1 )'} );
    $t->stdout_is( qq{0\n}, qq{小数点付きの数は素数ではない} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'is_prime( -2 )'} );
    $t->exit_is( 0, qq{./c 'is_prime( -2 )'} );
    $t->stdout_is( qq{0\n}, qq{2未満の数は素数ではない} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'is_prime( 2 )'} );
    $t->exit_is( 0, qq{./c 'is_prime( 2 )'} );
    $t->stdout_is( qq{1\n}, qq{2は素数} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'is_prime( 4 )'} );
    $t->exit_is( 0, qq{./c 'is_prime( 4 )'} );
    $t->stdout_is( qq{0\n}, qq{2以外の偶数は素数ではない} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'is_prime( 0xfffffffb )'} );
    $t->exit_is( 0, qq{./c 'is_prime( 0xfffffffb )'} );
    $t->stdout_is( qq{1 [ = 0x1 ]\n}, qq{32bitクラスの整数（素数）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'is_prime( 0xfffffffd )'} );
    $t->exit_is( 0, qq{./c 'is_prime( 0xfffffffd )'} );
    $t->stdout_is( qq{0 [ = 0x0 ]\n}, qq{32bitクラスの整数（非素数）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'is_prime( 1576770817, 1576770818 )'} );
    $t->exit_is( 0, qq{./c 'is_prime( 1576770817, 1576770818 )'} );
    $t->stdout_is( qq{( 1, 0 )\n}, qq{まとめて評価する} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'prime_factorize( 1234567890 )'} );
    $t->exit_is( 0, qq{./c 'prime_factorize( 1234567890 )'} );
    $t->stdout_is( qq{( 2, 3, 3, 5, 3607, 3803 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'prime_factorize( 2 ** 32 )'} );
    $t->exit_is( 0, qq{./c 'prime_factorize( 2 ** 32 )'} );
    $t->stdout_is( qq{( 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'prime_factorize( ( 2 ** 32 ) - 1 )'} );
    $t->exit_is( 0, qq{./c 'prime_factorize( ( 2 ** 32 ) - 1 )'} );
    $t->stdout_is( qq{( 3, 5, 17, 257, 65537 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'prime_factorize( 2 )'} );
    $t->exit_is( 0, qq{./c 'prime_factorize( 2 )'} );
    $t->stdout_is( qq{2\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'prime_factorize( -10 )'} );
    $t->exit_isnt( 0, qq{./c 'prime_factorize( -10 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: prime_factorize: \-10: Cannot be less than 2\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'prime_factorize( 2.345 )'} );
    $t->exit_isnt( 0, qq{./c 'prime_factorize( 2.345 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: prime_factorize: 2\.345: Decimals cannot be specified\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'get_prime( 32.1 )'} );
    $t->exit_isnt( 0, qq{./c 'get_prime( 32.1 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: get_prime: 32\.1: Decimals cannot be specified\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'get_prime( 64 )'} );
    $t->exit_isnt( 0, qq{./c 'get_prime( 64 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: get_prime: 64: Cannot specify a value greater than 32\.\n/ );
    undef( $t );

    ## 64bit: 3473826439 [ = 0xCF0E6287 ]
    ## 32bit: 2942933887 [ = -1352033409 ] [ = 0xAF699B7F ]
    my $gp32_expect = qr/^\d+ \[ = 0x[\dA-F]{1,8} \]\n$/;
    if( $UV_bit_width == 32 ){
        $gp32_expect = qr/^\d+(?: \[ = \-\d+ \])? \[ = 0x[\dA-F]{1,8} \]\n$/;
    }
    $t = tests::Command->new( qq{./c 'get_prime( 32 )|0'} );
    $t->exit_is( 0, qq{./c 'get_prime( 32 )|0'} );
    $t->stdout_like( $gp32_expect, qq{\$UV_bit_width="$UV_bit_width"} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'get_prime( 24 )|0'} );
    $t->exit_is( 0, qq{./c 'get_prime( 24 )|0'} );
    $t->stdout_like( qr/^\d+ \[ = 0x[\dA-F]{1,6} \]\n$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'get_prime( 16 )|0'} );
    $t->exit_is( 0, qq{./c 'get_prime( 16 )|0'} );
    $t->stdout_like( qr/^\d+ \[ = 0x[\dA-F]{1,4} \]\n$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'get_prime( 4 )|0'} );
    $t->exit_is( 0, qq{./c 'get_prime( 4 )|0'} );
    $t->stdout_like( qr/^\d+ \[ = 0x[\dA-F]{1} \]\n$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'get_prime( 3 )'} );
    $t->exit_isnt( 0, qq{./c 'get_prime( 3 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: get_prime: 3: Cannot specify a value less than 4\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gcd( 0 ) ='} );
    $t->exit_is( 0, qq{./c 'gcd( 0 ) ='} );
    $t->stdout_is( qq{0\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gcd( 138 ) ='} );
    $t->exit_is( 0, qq{./c 'gcd( 138 ) ='} );
    $t->stdout_is( qq{138\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gcd( 2040, 1920, 1080 ) ='} );
    $t->exit_is( 0, qq{./c 'gcd( 2040, 1920, 1080 ) ='} );
    $t->stdout_is( qq{120\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'lcm( 1920, 1080 ) ='} );
    $t->exit_is( 0, qq{./c 'lcm( 1920, 1080 ) ='} );
    $t->stdout_is( qq{17280\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ncr( -1.0, 2.0 )'} );
    $t->exit_isnt( 0, qq{./c 'ncr( -1.0, 2.0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: nCr\( \-1, 2 \): N\[=\-1\] must be a non-negative integer\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ncr( 1.1, 2.0 )'} );
    $t->exit_isnt( 0, qq{./c 'ncr( 1.1, 2.0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: nCr\( 1\.1, 2 \): N\[=1\.1\] must be a non-negative integer\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ncr( 1.0, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'ncr( 1.0, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: nCr\( 1, 0 \): R\[=0\] must be a positive integer\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ncr( 1.0, 2.1 )'} );
    $t->exit_isnt( 0, qq{./c 'ncr( 1.0, 2.1 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: nCr\( 1, 2\.1 \): R\[=2\.1\] must be a positive integer\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ncr( 1.0, 2.0 )'} );
    $t->exit_is( 0, qq{./c 'ncr( 1.0, 2.0 )'} );
    $t->stdout_is( qq{0\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ncr( 7.0, 2.0 )'} );
    $t->exit_is( 0, qq{./c 'ncr( 7.0, 2.0 )'} );
    $t->stdout_is( qq{21\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'min( 5 ) ='} );
    $t->exit_is( 0, qq{./c 'min( 5 ) ='} );
    $t->stdout_is( qq{5\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'max( 5 ) ='} );
    $t->exit_is( 0, qq{./c 'max( 5 ) ='} );
    $t->stdout_is( qq{5\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'min( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $t->exit_is( 0, qq{./c 'min( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $t->stdout_is( qq{1\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'max( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $t->exit_is( 0, qq{./c 'max( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $t->stdout_is( qq{9\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'min( 5, 4, 3, min( 5, 4, 3, 1, 2, 9, 8, 7, 6 ), 2, 9, 8, 7, 6 ) ='} );
    $t->exit_is( 0, qq{./c 'min( 5, 4, 3, min( 5, 4, 3, 1, 2, 9, 8, 7, 6 ), 2, 9, 8, 7, 6 ) ='} );
    $t->stdout_is( qq{1\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'max( 5, 4, 3, 1, 2, max( 5, 4, 3, 1, 2, 9, 8, 7, 6 ), 8, 7, 6 ) ='} );
    $t->exit_is( 0, qq{./c 'max( 5, 4, 3, 1, 2, max( 5, 4, 3, 1, 2, 9, 8, 7, 6 ), 8, 7, 6 ) ='} );
    $t->stdout_is( qq{9\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'min() ='} );
    $t->exit_isnt( 0, qq{./c 'min() ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: "min": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'shuffle( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $t->exit_is( 0, qq{./c 'shuffle( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $t->stdout_like( qr/^\( \d, \d, \d, \d, \d, \d, \d, \d, \d \)\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'min( shuffle( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ) ='} );
    $t->exit_is( 0, qq{./c 'min( shuffle( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ) ='} );
    $t->stdout_is( qq{1\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'uniq( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $t->exit_is( 0, qq{./c 'uniq( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $t->stdout_is( qq{( 5, 4, 3, 1, 2, 9, 8, 7, 6 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'uniq( 5, 4, 3, 1, 2, 1, 3, 4, 5, 9, 8, 7, 6 ) ='} );
    $t->exit_is( 0, qq{./c 'uniq( 5, 4, 3, 1, 2, 1, 3, 4, 5, 9, 8, 7, 6 ) ='} );
    $t->stdout_is( qq{( 5, 4, 3, 1, 2, 9, 8, 7, 6 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'max( uniq( 5, 4, 3, 1, 2, 1, 3, 4, 5, 9, 8, 7, 6 ) ) ='} );
    $t->exit_is( 0, qq{./c 'max( uniq( 5, 4, 3, 1, 2, 1, 3, 4, 5, 9, 8, 7, 6 ) ) ='} );
    $t->stdout_is( qq{9\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'first( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $t->exit_is( 0, qq{./c 'first( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ='} );
    $t->stdout_is( qq{5\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'slice( 2025, 12 )'} );
    $t->exit_isnt( 0, qq{./c 'slice( 2025, 12 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: slice: \$argc=2: Not enough arguments\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'slice( 2025, 12, 16, 1.2, 1.3 )'} );
    $t->exit_isnt( 0, qq{./c 'slice( 2025, 12, 16, 1.2, 1.3 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: slice: \$offset=1\.2: \$offset cannot be a decimal number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'slice( 2025, 12, 16, -1.2, 1.3 )'} );
    $t->exit_isnt( 0, qq{./c 'slice( 2025, 12, 16, -1.2, 1.3 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: slice: \$offset=\-1\.2: \$offset cannot be a decimal number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'slice( 2025, 12, 16, 1, 1.3 )'} );
    $t->exit_isnt( 0, qq{./c 'slice( 2025, 12, 16, 1, 1.3 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: slice: \$length=1\.3: \$length cannot be a decimal number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'slice( 2025, 12, 16, 3, 1 )'} );
    $t->exit_isnt( 0, qq{./c 'slice( 2025, 12, 16, 3, 1 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: slice: \$offset=3, \$argc=3: \$offset is large\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'slice( 2025, 12, 16, 0, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'slice( 2025, 12, 16, 0, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: slice: \$length=0: \$length must be greater than 0\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'slice( 2025, 12, 16, 0, 4 )'} );
    $t->exit_is( 0, qq{./c 'slice( 2025, 12, 16, 0, 4 )'} );
    $t->stdout_is( qq{( 2025, 12, 16 )\n} );
    $t->stderr_like( qr/^c: tbl_prvdr: warn: \$length=4: Decrease the value of \$length\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'slice( 2025, 12, 16, -2, 3 )'} );
    $t->exit_is( 0, qq{./c 'slice( 2025, 12, 16, -2, 3 )'} );
    $t->stdout_is( qq{( 12, 16 )\n} );
    $t->stderr_like( qr/^c: tbl_prvdr: warn: \$length=3: Decrease the value of \$length\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'slice( 2025, 12, 16, 0, 3 )'} );
    $t->exit_is( 0, qq{./c 'slice( 2025, 12, 16, 0, 3 )'} );
    $t->stdout_is( qq{( 2025, 12, 16 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'slice( 2025, 12, 16, -1, 1 )'} );
    $t->exit_is( 0, qq{./c 'slice( 2025, 12, 16, -1, 1 )'} );
    $t->stdout_is( qq{16\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sum( 1, 2, 3, 4, 5, 6, 7, 8, 9 ) ='} );
    $t->exit_is( 0, qq{./c 'sum( 1, 2, 3, 4, 5, 6, 7, 8, 9 ) ='} );
    $t->stdout_is( qq{45\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sum( 0.1, 2.3, 4.5, 6.7, 8.9 ) ='} );
    $t->exit_is( 0, qq{./c 'sum( 0.1, 2.3, 4.5, 6.7, 8.9 ) ='} );
    $t->stdout_is( qq{22.5\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'prod( linstep( 1, 1, 10 ) )'} );
    $t->exit_is( 0, qq{./c 'prod( linstep( 1, 1, 10 ) )'} );
    $t->stdout_is( qq{3628800\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'prod( linstep( 0, 1, 10 ) )'} );
    $t->exit_is( 0, qq{./c 'prod( linstep( 0, 1, 10 ) )'} );
    $t->stdout_is( qq{0\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'prod( linstep( -1, 2, 6 ) )'} );
    $t->exit_is( 0, qq{./c 'prod( linstep( -1, 2, 6 ) )'} );
    $t->stdout_is( qq{-945\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'avg( 1, 2, 3, 4, 5, 6, 7, 8, 9 ) ='} );
    $t->exit_is( 0, qq{./c 'avg( 1, 2, 3, 4, 5, 6, 7, 8, 9 ) ='} );
    $t->stdout_is( qq{5\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'avg( 0.1, 2.3, 4.5, 6.7, 8.9 ) ='} );
    $t->exit_is( 0, qq{./c 'avg( 0.1, 2.3, 4.5, 6.7, 8.9 ) ='} );
    $t->stdout_is( qq{4.5\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'add_each( -10 )'} );
    $t->exit_isnt( 0, qq{./c 'add_each( -10 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: add_each\(\): \$argc=1: Insufficient number of arguments\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'add_each( 100, 200, -10 )'} );
    $t->exit_is( 0, qq{./c 'add_each( 100, 200, -10 )'} );
    $t->stdout_is( qq{( 90, 190 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'mul_each( ( 1 / 25.4 ) * 300 )'} );
    $t->exit_isnt( 0, qq{./c 'mul_each( ( 1 / 25.4 ) * 300 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: mul_each\(\): \$argc=1: Insufficient number of arguments\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'mul_each( 210, 297, ( 1 / 25.4 ) * 300 )'} );
    $t->exit_is( 0, qq{./c 'mul_each( 210, 297, ( 1 / 25.4 ) * 300 )'} );
    $t->stdout_is( qq{( 2480.31496063, 3507.87401575 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linspace( 4, 10, 3 )'} );
    $t->exit_is( 0, qq{./c 'linspace( 4, 10, 3 )'} );
    $t->stdout_is( qq{( 4, 7, 10 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linspace( -10, 10, 5 )'} );
    $t->exit_is( 0, qq{./c 'linspace( -10, 10, 5 )'} );
    $t->stdout_is( qq{( -10, -5, 0, 5, 10 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linspace( 10, -10, 5 )'} );
    $t->exit_is( 0, qq{./c 'linspace( 10, -10, 5 )'} );
    $t->stdout_is( qq{( 10, 5, 0, -5, -10 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linspace( -10, 10, 9 )'} );
    $t->exit_is( 0, qq{./c 'linspace( -10, 10, 9 )'} );
    $t->stdout_is( qq{( -10, -7.5, -5, -2.5, 0, 2.5, 5, 7.5, 10 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linspace( -10, 10, 9, 0 )'} );
    $t->exit_is( 0, qq{./c 'linspace( -10, 10, 9, 0 )'} );
    $t->stdout_is( qq{( -10, -8, -5, -3, 0, 3, 5, 8, 10 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linspace( 0x64, 0xff, 5 )'} );
    $t->exit_is( 0, qq{./c 'linspace( 0x64, 0xff, 5 )'} );
    $t->stdout_is( qq{( 100, 138.75, 177.5, 216.25, 255 ) [ = ( 0x64, 138.75, 177.5, 216.25, 0xFF ) ]\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linspace( -10, 10 )'} );
    $t->exit_isnt( 0, qq{./c 'linspace( -10, 10 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: "linspace": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linspace( -10, 10, 3, 1, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'linspace( -10, 10, 3, 1, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linspace: \$arg_counter="5": The number of operands is incorrect\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linspace( -10, 10, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'linspace( -10, 10, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linspace\(\): \$length\[=0\] is less than 2\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linspace( -10, 10, 1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'linspace( -10, 10, 1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linspace\(\): \$length\[=1\.2\] is less than 2\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linspace( -10, 10, 2.1 )'} );
    $t->exit_isnt( 0, qq{./c 'linspace( -10, 10, 2.1 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linspace\(\): \$length\[=2\.1\] is a decimal number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linstep( 4, 10, 3 )'} );
    $t->exit_is( 0, qq{./c 'linstep( 4, 10, 3 )'} );
    $t->stdout_is( qq{( 4, 14, 24 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linstep( 4, -10, 3 )'} );
    $t->exit_is( 0, qq{./c 'linstep( 4, -10, 3 )'} );
    $t->stdout_is( qq{( 4, -6, -16 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linstep( 4, -10, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'linstep( 4, -10, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linstep\(\): \$length\[=0\] is less than 1\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linstep( 4, 10, -1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'linstep( 4, 10, -1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linstep\(\): \$length\[=\-1\.2\] is less than 1\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linstep( 4, 10, 1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'linstep( 4, 10, 1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linstep\(\): \$length\[=1\.2\] is a decimal number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linstep( 4, -10, 1 )'} );
    $t->exit_is( 0, qq{./c 'linstep( 4, -10, 1 )'} );
    $t->stdout_is( qq{4\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linstep( -1.1, -1 sqrt( 2 ), 3 )'} );
    $t->exit_is( 0, qq{./c 'linstep( -1.1, -1 sqrt( 2 ), 3 )'} );
    $t->stdout_is( qq{( -1.1, -2.51421356237, -3.92842712475 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'mul_growth( 0, 1, 10 )'} );
    $t->exit_is( 0, qq{./c 'mul_growth( 0, 1, 10 )'} );
    $t->stdout_is( qq{( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'mul_growth( 1, 1, -1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'mul_growth( 1, 1, -1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: mul_growth\(\): \$length\[=\-1\.2\] is less than 1\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'mul_growth( 1, 1, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'mul_growth( 1, 1, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: mul_growth\(\): \$length\[=0\] is less than 1\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'mul_growth( -100, 0, 1 )'} );
    $t->exit_is( 0, qq{./c 'mul_growth( -100, 0, 1 )'} );
    $t->stdout_is( qq{-100\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'mul_growth( 1, 1, 1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'mul_growth( 1, 1, 1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: mul_growth\(\): \$length\[=1\.2\] is a decimal number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'mul_growth( 100, 0.5, 2 )'} );
    $t->exit_is( 0, qq{./c 'mul_growth( 100, 0.5, 2 )'} );
    $t->stdout_is( qq{( 100, 50 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'mul_growth( 4, 2, 5 )'} );
    $t->exit_is( 0, qq{./c 'mul_growth( 4, 2, 5 )'} );
    $t->stdout_is( qq{( 4, 8, 16, 32, 64 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gen_fibo_seq( 0, 1, 10 )'} );
    $t->exit_is( 0, qq{./c 'gen_fibo_seq( 0, 1, 10 )'} );
    $t->stdout_is( qq{( 0, 1, 1, 2, 3, 5, 8, 13, 21, 34 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gen_fibo_seq( 2, 1, 10 )'} );
    $t->exit_is( 0, qq{./c 'gen_fibo_seq( 2, 1, 10 )'} );
    $t->stdout_is( qq{( 2, 1, 3, 4, 7, 11, 18, 29, 47, 76 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gen_fibo_seq( -2, 5, 10 )'} );
    $t->exit_is( 0, qq{./c 'gen_fibo_seq( -2, 5, 10 )'} );
    $t->stdout_is( qq{( -2, 5, 3, 8, 11, 19, 30, 49, 79, 128 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gen_fibo_seq( 2, 1, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'gen_fibo_seq( 2, 1, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: gen_fibo_seq\(\): \$length\[=0\] is less than 2\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gen_fibo_seq( 2, 1, -1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'gen_fibo_seq( 2, 1, -1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: gen_fibo_seq\(\): \$length\[=\-1\.2\] is less than 2\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gen_fibo_seq( 2, 1, 2.1 )'} );
    $t->exit_isnt( 0, qq{./c 'gen_fibo_seq( 2, 1, 2.1 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: gen_fibo_seq\(\): \$length\[=2\.1\] is a decimal number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gen_fibo_seq( -100, 100, 2 )'} );
    $t->exit_is( 0, qq{./c 'gen_fibo_seq( -100, 100, 2 )'} );
    $t->stdout_is( qq{( -100, 100 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gen_fibo_seq( -5.4, 3.2, 10 )'} );
    $t->exit_is( 0, qq{./c 'gen_fibo_seq( -5.4, 3.2, 10 )'} );
    $t->stdout_is( qq{( -5.4, 3.2, -2.2, 1, -1.2, -0.2, -1.4, -1.6, -3, -4.6 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'paper_size( -1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'paper_size( -1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: paper_size\(\): \$size\[=\-1\.2\] is negative\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'paper_size( 1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'paper_size( 1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: paper_size\(\): \$size\[=1\.2\] is a decimal number\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'paper_size( 0 )'} );
    $t->exit_is( 0, qq{./c 'paper_size( 0 )'} );
    $t->stdout_is( qq{( 841, 1189 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'paper_size( 4 )'} );
    $t->exit_is( 0, qq{./c 'paper_size( 4 )'} );
    $t->stdout_is( qq{( 210, 297 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'paper_size( 19, 0 )'} );
    $t->exit_is( 0, qq{./c 'paper_size( 19, 0 )'} );
    $t->stdout_is( qq{( 1, 1 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'paper_size( 20, 0 )'} );
    $t->exit_is( 0, qq{./c 'paper_size( 20, 0 )'} );
    $t->stdout_is( qq{( 0, 1 )\n} );
    $t->stderr_is( qq{paper_size(): A20: The short side reaches 0 mm.\n} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'paper_size( 100, 0 )'} );
    $t->exit_is( 0, qq{./c 'paper_size( 100, 0 )'} );
    $t->stdout_is( qq{( 0, 0 )\n} );
    $t->stderr_is( qq{paper_size(): A20: The short side reaches 0 mm.\npaper_size(): A21: The long side reaches 0 mm.\n} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'paper_size( 0, 1 )'} );
    $t->exit_is( 0, qq{./c 'paper_size( 0, 1 )'} );
    $t->stdout_is( qq{( 1030, 1456 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'paper_size( 4, 1 )'} );
    $t->exit_is( 0, qq{./c 'paper_size( 4, 1 )'} );
    $t->stdout_is( qq{( 257, 364 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'paper_size( 100, 1 )'} );
    $t->exit_is( 0, qq{./c 'paper_size( 100, 1 )'} );
    $t->stdout_is( qq{( 0, 0 )\n} );
    $t->stderr_is( qq{paper_size(): B21: The short side reaches 0 mm.\npaper_size(): B22: The long side reaches 0 mm.\n} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'min( rand( 10 ), rand( 10 ), rand( 10 ), rand( 10 ), rand( 10 ) )' -v} );
    $t->exit_is( 0, qq{./c 'min( rand( 10 ), rand( 10 ), rand( 10 ), rand( 10 ), rand( 10 ) )' -v} );
    $t->stdout_like( qr/\n    RPN: '# # 10 rand # 10 rand # 10 rand # 10 rand # 10 rand min'\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rand(-10)'} );
    $t->exit_is( 0, qq{./c 'rand(-10)'} );
    $t->stdout_like( qr/^\-\d\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rand(0)'} );
    $t->exit_is( 0, qq{./c 'rand(0)'} );
    $t->stdout_like( qr/^0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rand(10)'} );
    $t->exit_is( 0, qq{./c 'rand(10)'} );
    $t->stdout_like( qr/^\d\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'int( rand( 2 ) )'} );
    $t->exit_is( 0, qq{./c 'int( rand( 2 ) )'} );
    $t->stdout_like( qr/^[01]$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '***='} );
    $t->exit_isnt( 0, qq{./c '***='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: "\*\*": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c '1+2*3+='} );
    $t->exit_isnt( 0, qq{./c '1+2*3+='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: "\+": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c '()='} );
    $t->exit_is( 0, qq{./c '()='} );
    $t->stdout_is( qq{0\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '1_2='} );
    $t->exit_isnt( 0, qq{./c '1_2='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: lexer: error: "_2=": Could not interpret\.\n/ );
    $t->stderr_like( qr/\nc: lexer: info: Supported operators: / );
    $t->stderr_like( qr/\nc: lexer: info: Supported functions: / );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sqrt(#)='} );
    $t->exit_isnt( 0, qq{./c 'sqrt(#)='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: lexer: error: "#\)=": Could not interpret\.\n/ );
    $t->stderr_like( qr/\nc: lexer: info: Supported operators: / );
    $t->stderr_like( qr/\nc: lexer: info: Supported functions: / );
    undef( $t );

    $t = tests::Command->new( qq{./c '( 1 + 2 + 3, 4 ) ='} );
    $t->exit_is( 0, qq{./c '( 1 + 2 + 3, 4 ) ='} );
    $t->stdout_is( qq{( 6, 4 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '123' '+2=' -v} );
    $t->exit_is( 0, qq{./c '123' '+2=' -v} );
    $t->stdout_like( qr/123 \+ 2 = 125\n/ );
    $t->stdout_like( qr/\n Result: 125\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '123' '2=' -v} );
    $t->exit_is( 0, qq{./c '123' '2=' -v} );
    $t->stdout_like( qr/^123 \* 2 = 246\n/ );
    $t->stdout_like( qr/\n Result: 246\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '1+(2+(3+(4+(5+(6+((7+8*9)))))))='} );
    $t->exit_is( 0, qq{./c '1+(2+(3+(4+(5+(6+((7+8*9)))))))='} );
    $t->stdout_is( qq{100\n}, qq{result: 100} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sqrt(4)=' =r} );
    $t->exit_isnt( 0, qq{./c 'sqrt(4)=' =r} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_is( qq{c: engine: warn: "=r": Ignore. The calculation process has been completed.\n} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sqrt(power(2, 100)+power(2,100))='} );
    $t->exit_isnt( 0, qq{./c 'sqrt(power(2, 100)+power(2,100))='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: pow: \$arg_counter="1": The number of operands is incorrect\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sqrt(-1)'} );
    $t->exit_isnt( 0, qq{./c 'sqrt(-1)'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: Can't take sqrt of \-1\.\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c '12345678901 + 0.1234'} );
    $t->exit_is( 0, qq{./c '12345678901 + 0.1234'} );
    $t->stdout_is( qq{12345678901.1\n}, , qq{result: 12345678901.1} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '123456789012 + 0.1234'} );
    $t->exit_is( 0, qq{./c '123456789012 + 0.1234'} );
    $t->stdout_is( qq{123456789012\n}, , qq{result: 123456789012} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '1234567890123 + 0.1234'} );
    $t->exit_is( 0, qq{./c '1234567890123 + 0.1234'} );
    $t->stdout_is( qq{1234567890123\n}, , qq{result: 1234567890123} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '-0.1234567890123'} );
    $t->exit_is( 0, qq{./c '-0.1234567890123'} );
    $t->stdout_is( qq{-0.123456789012\n}, , qq{result: -0.123456789012} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{Script Structure} => sub{
    my $t;

    $t = tests::Command->new( qq{./c '1+(2+(3+(4+(5+(6+((7+8*9)))))))=' --test-test -d} );
    $t->exit_is( 0, qq{./c '1+(2+(3+(4+(5+(6+((7+8*9)))))))=' --test-test -d} );
    ## OutputFunc
    $t->stdout_like( qr/\nengine: \$help_of_unknown_operator="  \*\*\*\n/, 'OutputFunc' );
    ## TableProvider
    $t->stdout_like( qr/\ntbl_prvdr: test: \$opeIdx=""\n/, 'TableProvider' );
    $t->stdout_like( qr/\ntbl_prvdr: test: \$bSentinel="0"\n/, 'TableProvider' );
    ## FormulaStack
    $t->stdout_like( qr/Pop\(\): enmpy/, 'FormulaStack' );
    $t->stdout_like( qr/GetNewer\(\): enmpy/, 'FormulaStack' );
    ## FormulaEvaluator
    $t->stdout_like( qr/\nevaluator: scalar\( \@\{ \$self->\{RPN\} \} \) = 3\n/, 'FormulaEvaluator' );
    $t->stdout_like( qr/\nevaluator: scalar\( \@\{ \$self->\{TOKENS\} \} \) = 2\n/, 'FormulaEvaluator' );
    $t->stdout_like( qr/\nevaluator: GetUsage\(\) test: \$usage=""\n/, 'FormulaEvaluator' );
    $t->stdout_like( qr/\n Result: 100\n/, qq{result: 100} );
    $t->stderr_like( qr/^Use of uninitialized value \$opeIdx / );
    $t->stderr_like( qr/\nc: evaluator: warn: There may be an error in the calculation formula\.\n/, 'FormulaEvaluator' );
    $t->stderr_like( qr/\nc: evaluator: error: "\*": Unexpected errors\.\n/, 'FormulaEvaluator' );
    undef( $t );

    $t = tests::Command->new( qq{./c '1+(2+(3+(4+(5+(6+((7+8*9)))))))=' --test-test} );
    $t->exit_is( 0, qq{./c '1+(2+(3+(4+(5+(6+((7+8*9)))))))=' --test-test} );
    ## OutputFunc
    $t->stdout_unlike( qr/\nengine: \$help_unknown_operator="  \*\*\*\n/, 'OutputFunc' );
    ## TableProvider
    $t->stdout_unlike( qr/\ntbl_prvdr: test: \$opeIdx=""\n/, 'TableProvider' );
    $t->stdout_unlike( qr/\ntbl_prvdr: test: \$bSentinel="0"\n/, 'TableProvider' );
    ## FormulaStack
    $t->stdout_unlike( qr/Pop\(\): enmpy/, 'FormulaStack' );
    $t->stdout_unlike( qr/GetNewer\(\): enmpy/, 'FormulaStack' );
    ## FormulaEvaluator
    $t->stdout_unlike( qr/\nevaluator: scalar\( \@FormulaEvaluator::RPN \) = 3\n/, 'FormulaEvaluator' );
    $t->stdout_unlike( qr/\nevaluator: scalar\( \@FormulaEvaluator::Tokens \) = 2\n/, 'FormulaEvaluator' );
    $t->stdout_unlike( qr/\nevaluator: GetUsage\(\) test: \$usage=""\n/, 'FormulaEvaluator' );
    $t->stdout_is( qq{100\n}, qq{result: 100} );
    $t->stderr_like( qr/^Use of uninitialized value \$opeIdx / );
    $t->stderr_like( qr/\nc: evaluator: warn: There may be an error in the calculation formula\.\n/, 'FormulaEvaluator' );
    $t->stderr_like( qr/\nc: evaluator: error: "\*": Unexpected errors\.\n/, 'FormulaEvaluator' );
    undef( $t );
};

subtest qq{aliases} => sub{
    my $t;

    $t = tests::Command->new( qq{./c 'mmod( 10, -1.2 )'} );
    $t->exit_is( 0, qq{./c 'mmod( 10, -1.2 )'} );
    $t->stdout_is( qq{-0.8\n}, qq{( A B C D ) = ( 0 0 1 1 )} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'pct( 2, 3, 1 )'} );
    $t->exit_is( 0, qq{./c 'pct( 2, 3, 1 )'} );
    $t->stdout_is( qq{66.7\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'rs( 3, 10, 20 )'} );
    $t->exit_is( 0, qq{./c 'rs( 3, 10, 20 )'} );
    $t->stdout_is( qq{66.6666666667\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'pf( 1234567890 )'} );
    $t->exit_is( 0, qq{./c 'pf( 1234567890 )'} );
    $t->stdout_is( qq{( 2, 3, 3, 5, 3607, 3803 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'dist( 100, 100, 0, 0 )'} );
    $t->exit_is( 0, qq{./c 'dist( 100, 100, 0, 0 )'} );
    $t->stdout_is( qq{141.421356237\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'midpt( 100, 100, 0, 0 )'} );
    $t->exit_is( 0, qq{./c 'midpt( 100, 100, 0, 0 )'} );
    $t->stdout_is( qq{( 50, 50 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angle( 100, 100, 0, 0 )'} );
    $t->exit_is( 0, qq{./c 'angle( 100, 100, 0, 0 )'} );
    $t->stdout_is( qq{-135\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'va( 100, 100, 100, 100 )'} );
    $t->exit_is( 0, qq{./c 'va( 100, 100, 100, 100 )'} );
    $t->stdout_is( qq{0\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'angular_distance( -100, 100, 100, -100 )'} );
    $t->exit_is( 0, qq{./c 'angular_distance( -100, 100, 100, -100 )'} );
    $t->stdout_is( qq{180\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ang_dist( -100, 100, 100, -100 )'} );
    $t->exit_is( 0, qq{./c 'ang_dist( -100, 100, 100, -100 )'} );
    $t->stdout_is( qq{180\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gd_m( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) ) / 1000'} );
    $t->exit_is( 0, qq{./c 'gd_m( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) ) / 1000'} );
    $t->stdout_is( qq{14056.1311832\n}, qq{東京駅から昭和基地までの距離（大圏航路）（m->km）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gd_km( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->exit_is( 0, qq{./c 'gd_km( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->stdout_is( qq{14056.1311832\n}, qq{東京駅から昭和基地までの距離（大圏航路）（km）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gazm( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->exit_is( 0, qq{./c 'gazm( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->stdout_is( qq{206.108012524\n}, qq{東京駅から昭和基地までの方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gd_m_azm( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->exit_is( 0, qq{./c 'gd_m_azm( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->stdout_is( qq{( 14056131.1832, 206.108012524 )\n}, qq{東京駅から昭和基地までの距離（大圏航路）（m）と方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gd_km_azm( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->exit_is( 0, qq{./c 'gd_km_azm( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) )'} );
    $t->stdout_is( qq{( 14056.1311832, 206.108012524 )\n}, qq{東京駅から昭和基地までの距離（大圏航路）（km）と方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gd_rl_m( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) ) / 1000'} );
    $t->exit_is( 0, qq{./c 'gd_rl_m( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) ) / 1000'} );
    $t->stdout_is( qq{14484.2565649\n}, qq{東京駅から昭和基地までの距離（等角航路）（m->km）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gd_rl_km( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->exit_is( 0, qq{./c 'gd_rl_km( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->stdout_is( qq{14484.2565649\n}, qq{東京駅から昭和基地までの距離（等角航路）（km）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gazm_rl( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->exit_is( 0, qq{./c 'gazm_rl( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->stdout_is( qq{216.733277422\n}, qq{東京駅から昭和基地までの等角航路の方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gd_rl_m_azm( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->exit_is( 0, qq{./c 'gd_rl_m_azm( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->stdout_is( qq{( 14484256.5649, 216.733277422 )\n}, qq{東京駅から昭和基地までの等角航路の距離（m）と方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'gd_rl_km_azm( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->exit_is( 0, qq{./c 'gd_rl_km_azm( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) )'} );
    $t->stdout_is( qq{( 14484.2565649, 216.733277422 )\n}, qq{東京駅から昭和基地までの等角航路の距離（km）と方角（度）} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'kgf2n( 6.5 )'} );
    $t->exit_is( 0, qq{./c 'kgf2n( 6.5 )'} );
    $t->stdout_is( qq{63.743225\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'n2kgf( 64 )'} );
    $t->exit_is( 0, qq{./c 'n2kgf( 64 )'} );
    $t->stdout_is( qq{6.52618376306\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '里→メートル( 1 )'} );
    $t->exit_is( 0, qq{./c '里→メートル( 1 )'} );
    $t->stdout_is( qq{3927.27272727\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'メートル→里( 4000 )'} );
    $t->exit_is( 0, qq{./c 'メートル→里( 4000 )'} );
    $t->stdout_is( qq{1.01851851852\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'マイル→メートル( 1 )'} );
    $t->exit_is( 0, qq{./c 'マイル→メートル( 1 )'} );
    $t->stdout_is( qq{1609.344\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'メートル→マイル( 2000 )'} );
    $t->exit_is( 0, qq{./c 'メートル→マイル( 2000 )'} );
    $t->stdout_is( qq{1.24274238447\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '海里→メートル( 1 )'} );
    $t->exit_is( 0, qq{./c '海里→メートル( 1 )'} );
    $t->stdout_is( qq{1852\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'メートル→海里( 2000 )'} );
    $t->exit_is( 0, qq{./c 'メートル→海里( 2000 )'} );
    $t->stdout_is( qq{1.07991360691\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ポンド→グラム( 1 )'} );
    $t->exit_is( 0, qq{./c 'ポンド→グラム( 1 )'} );
    $t->stdout_is( qq{453.59237\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'グラム→ポンド( 500 )'} );
    $t->exit_is( 0, qq{./c 'グラム→ポンド( 500 )'} );
    $t->stdout_is( qq{1.10231131092\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'オンス→グラム( 1 )'} );
    $t->exit_is( 0, qq{./c 'オンス→グラム( 1 )'} );
    $t->stdout_is( qq{28.349523125\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'グラム→オンス( 30 )'} );
    $t->exit_is( 0, qq{./c 'グラム→オンス( 30 )'} );
    $t->stdout_is( qq{1.05821885849\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'kgf2n( 2.3 )'} );
    $t->exit_is( 0, qq{./c 'kgf2n( 2.3 )'} );
    $t->stdout_is( qq{22.555295\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'n2kgf( 23 )'} );
    $t->exit_is( 0, qq{./c 'n2kgf( 23 )'} );
    $t->stdout_is( qq{2.34534728985\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'キログラム重→ニュートン( 2.25 )'} );
    $t->exit_is( 0, qq{./c 'キログラム重→ニュートン( 2.25 )'} );
    $t->stdout_is( qq{22.0649625\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'ニュートン→キログラム重( 17 )'} );
    $t->exit_is( 0, qq{./c 'ニュートン→キログラム重( 17 )'} );
    $t->stdout_is( qq{1.73351756206\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{printf "\n\n" | ./c 'lt( 2 )'} );
    $t->exit_is( 0, qq{printf "\n\n" | ./c 'lt( 2 )'} );
    $t->stdout_like( qr/^Lap  Split\-Time    Lap\-Time      Date\-Time\n/ );
    $t->stdout_like( qr/\r2\/2  00:00:00\./ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo '' | ./c 'sw()'} );
    $t->exit_is( 0, qq{echo '' | ./c 'sw()'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'age_of_moon_i( l2e( 2025, 12, 5, 12 ) )'} );
    $t->exit_is( 0, qq{./c 'age_of_moon_i( l2e( 2025, 12, 5, 12 ) )'} );
    $t->stdout_is( qq{14.705978187\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sec2dhms( dhms2sec( 0, 24 / SAKUBOU, 0, 0 ), 3 )'} );
    $t->exit_is( 0, qq{./c 'sec2dhms( dhms2sec( 0, 24 / SAKUBOU, 0, 0 ), 3 )'} );
    $t->stdout_is( qq{( 0, 0, 48, 45.78 )\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '90 - CHIJIKU'} );
    $t->exit_is( 0, qq{./c '90 - CHIJIKU'} );
    $t->stdout_is( qq{66.564\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{-d, --debug} => sub{
    my $t;

    $t = tests::Command->new( qq{echo | ./c -d} );
    $t->exit_is( 0, qq{echo | ./c -d} );
    $t->stdout_like( qr/^dbg: arg="\-d", \@val=0\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo | ./c --debug} );
    $t->exit_is( 0, qq{echo | ./c --debug} );
    $t->stdout_like( qr/^dbg: arg="\-\-debug", \@val=0\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo | ./c -dv} );
    $t->exit_is( 0, qq{echo | ./c -dv} );
    $t->stdout_like( qr/dbg: arg="\-d", \@val=1\ndbg: arg="\-v", \@val=0\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c -d '-20-3*2(1+sqrt(4))='} );
    $t->exit_is( 0, qq{./c -d '-20-3*2(1+sqrt(4))='} );
    $t->stdout_like( qr/^dbg: arg="\-d", \@val=1\n/ );
    $t->stdout_like( qr/\nRemain RPN: \-20 3 2\n/ );
    $t->stdout_like( qr/\n Result: \-38\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{-v, --verbose} => sub{
    my $t;

    $t = tests::Command->new( qq{./c 'sqrt(2**100)=' -v} );
    $t->exit_is( 0, qq{./c 'sqrt(2**100)=' -v} );
    $t->stdout_like( qr/^2 \*\* 100 = 1\.26765060022823e\+30\n/ );
    $t->stdout_like( qr/\nsqrt\( 1\.26765060022823e\+30 \) = 1\.12589990684262e\+15\n/ );
    $t->stdout_like( qr/\n Result: 1125899906842624 \[ = 1\.12589990684262e\+15 \]\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'sqrt(power(2, 100)+power(2, 100))=' --verbose} );
    $t->exit_is( 0, qq{./c 'sqrt(power(2, 100)+power(2, 100))=' --verbose} );
    $t->stdout_like( qr/\n Result: 1592262918131443\.25 \[ = 1\.59226291813144e\+15 \]\n/ );  ## 1592262918131443.1411559535896932
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '0.22*10**(-6)=' --verbose} );
    $t->exit_is( 0, qq{./c '0.22*10**(-6)=' --verbose} );
    $t->stdout_like( qr/\n Result: 0.00000022 \[ = 2\.2e\-07 \]\n/ );            ## 0.00000022
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c -v '-20-3*2(1+sqrt(4))='} );
    $t->exit_is( 0, qq{./c -v '-20-3*2(1+sqrt(4))='} );
    $t->stdout_like( qr/^3 \* 2 = 6\n/ );
    $t->stdout_like( qr/\nsqrt\( 4 \) = 2\n/ );
    $t->stdout_like( qr/\n1 \+ 2 = 3\n/ );
    $t->stdout_like( qr/\n6 \* 3 = 18\n/ );
    $t->stdout_like( qr/\n\-20 \- 18 = \-38\n/ );
    $t->stdout_like( qr/\n Result: \-38\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '10*-3*-5+-4/2=' --verbose} );
    $t->exit_is( 0, qq{./c '10*-3*-5+-4/2=' --verbose} );
    $t->stdout_like( qr/^10 \* \-3 = \-30\n/ );
    $t->stdout_like( qr/\n\-30 \* \-5 = 150\n/ );
    $t->stdout_like( qr/\n\-4 \/ 2 = \-2\n/ );
    $t->stdout_like( qr/\n150 \+ \-2 = 148\n/ );
    $t->stdout_like( qr/\n Result: 148\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c --verbose '0x0d*0xff/(-0x5*-0x0d)='} );
    $t->exit_is( 0, qq{./c --verbose '0x0d*0xff/(-0x5*-0x0d)='} );
    $t->stdout_like( qr/^13 \* 255 = 3315\n/ );
    $t->stdout_like( qr/\n\-5 \* \-13 = 65\n/ );
    $t->stdout_like( qr/\n3315 \/ 65 = 51\n/ );
    $t->stdout_like( qr/\n Result: 51 \[ = 0x33 \]\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c 'linstep( 0.00000022, -1, 2 )' -v} );
    $t->exit_is( 0, qq{./c 'linstep( 0.00000022, -1, 2 )' -v} );
    $t->stdout_like( qr/\n Result: \( 0\.00000022, \-0\.99999978 \) \[ = \( 2\.2e\-07, \-0\.99999978 \) \]\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{-r, --rpn} => sub{
    my $t;

    $t = tests::Command->new( qq{./c '10*-3' '*-5+-4/2=' -r} );
    $t->exit_is( 0, qq{./c '10*-3' '*-5+-4/2=' -r} );
    $t->stdout_is( qq{10 -3 * -5 * -4 2 / +\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '10*-3' '*-5+-4/2=' --rpn} );
    $t->exit_is( 0, qq{./c '10*-3' '*-5+-4/2=' --rpn} );
    $t->stdout_is( qq{10 -3 * -5 * -4 2 / +\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c '10*-3' '*-5+-4/2=' --rpn --verbose} );
    $t->exit_is( 0, qq{./c '10*-3' '*-5+-4/2=' --rpn --verbose} );
    $t->stdout_like( qr/^Remain RPN: 10\n/ );
    $t->stdout_like( qr/\nRemain RPN: 150 \-4 2\n/ );
    $t->stdout_like( qr/\n10 \-3 \* \-5 \* \-4 2 \/ \+\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{--version} => sub{
    my $t;

    $t = tests::Command->new( qq{./c --version} );
    $t->exit_is( 0, qq{./c --version} );
    $t->stdout_like( qr/^Version: \d/ );
    $t->stdout_like( qr/\n   Perl: v\d/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{-h, --help} => sub{
    my $t;

    $t = tests::Command->new( qq{./c -h} );
    $t->exit_is( 0, qq{./c -h} );
    $t->stdout_like( qr/^Usage: c / );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c --help} );
    $t->exit_is( 0, qq{./c --help} );
    $t->stdout_like( qr/^Usage: c / );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{./c --test-test --help} );
    $t->exit_is( 0, qq{./c --test-test --help} );
    $t->stdout_like( qr/^Usage: c / );
    $t->stdout_like( qr/\n  =     Equals sign. In \*c\* script, it has the meaning of terminating the/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

#    $t = tests::Command->new( qq{export PATH="./tests:\$PATH" && ./c --test-test --help} );
#    $t->exit_is( 0, qq{export PATH="./tests:\$PATH" && ./c --test-test --help} );
    $t = tests::Command->new( qq{PATH="./tests:\$PATH" ./c --test-test --help} );
    $t->exit_is( 0, qq{PATH="./tests:\$PATH" ./c --test-test --help} );
    $t->stdout_like( qr/^Usage: c / );
    $t->stdout_like( qr/\n  =     Equals sign. In \*c\* script, it has the meaning of terminating the/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

#    $t = tests::Command->new( qq{export COLUMNS="70" && export LINES="30" && ./c --help} );
#    $t->exit_is( 0, qq{export COLUMNS="70" && export LINES="30" && ./c --help} );
    $t = tests::Command->new( qq{COLUMNS="70" LINES="30" ./c --help} );
    $t->exit_is( 0, qq{COLUMNS="70" LINES="30" ./c --help} );
    $t->stdout_like( qr/^Usage: c /, qq{Specified character width.} );
    $t->stdout_like( qr/\n  =     Equals sign. In \*c\* script, it has the meaning of terminating\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

#    $t = tests::Command->new( qq{unset COLUMNS && unset LINES && ./c --help} );
#    $t->exit_is( 0, qq{unset COLUMNS && unset LINES && ./c --help} );
    $t = tests::Command->new( qq{env -u COLUMNS -u LINES ./c --help} );
    $t->exit_is( 0, qq{env -u COLUMNS -u LINES ./c --help} );
    $t->stdout_like( qr/^Usage: c / );
    $t->stdout_like( qr/\n  =     Equals sign. In \*c\* script, it has the meaning of terminating the\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{-b, --banner} => sub{
    my $t;

    $t = tests::Command->new( qq{./c -b 's2d( d2s( 0, 24 / 29.53, 0, 0 ), 1 )'} );
    $t->exit_is( 0, qq{./c -b 's2d( d2s( 0, 24 / 29.53, 0, 0 ), 1 )'} );
    $t->stdout_is( qq{( 0, 0, 48, 45.8 )\n} );
    $t->stderr_like( qr/\nC \- The Flat\-Text Calculator \(Perl Script\)\n/ );
    undef( $t );

    $t = tests::Command->new( qq{./c --banner 'paper_size( 4 )'} );
    $t->exit_is( 0, qq{./c --banner 'paper_size( 4 )'} );
    $t->stdout_is( qq{( 210, 297 )\n} );
    $t->stderr_like( qr/\nC \- The Flat\-Text Calculator \(Perl Script\)\n/ );
    undef( $t );
};

subtest qq{user-rc ( Run Command )} => sub{
    my $t;

    $t = tests::Command->new( qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $t->exit_is( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $t->stdout_is( qq{403.822719846\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    `rm -f .c.rc`;

    $t = tests::Command->new( qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $t->exit_isnt( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: lexer: error: "tokyo_st_coord, osaka_st_coord \)=": Could not interpret\.\n/ );
    undef( $t );

    `gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.failed && mv .c.rc.failed .c.rc`;

    $t = tests::Command->new( qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $t->exit_isnt( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/c: lexer: error: \.\/tests\/\.\.\/\.c\.rc: Failed to load user rc file: / );
    undef( $t );

    `gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.duplicate && mv .c.rc.duplicate .c.rc`;

    $t = tests::Command->new( qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )' -v} );
    $t->exit_is( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )' -v} );
    $t->stdout_like( qr/\n Result: 403\.822719846\n/ );
    $t->stderr_is( qq{c: lexer: warn: "osaka_st_coord": "deg2rad( 34.70248, 135.49595 )" -> "deg2rad( 34.70248, 135.49595 )": Overwrites the existing definition.\n} );
    undef( $t );

    `gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.deploy && mv .c.rc.deploy .c.rc`;

    $t = tests::Command->new( qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )' -v} );
    $t->exit_is( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )' -v} );
    $t->stdout_like( qr/\n Result: 403\.822719846\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{-u, --user-defined} => sub{
    my $t;

    `rm -f .c.rc`;

    $t = tests::Command->new( qq{./c -u} );
    $t->exit_is( 0, qq{./c -u} );
    $t->stdout_like( qr/^=== User Defined ===\n/ );
    $t->stdout_like( qr/\n====================\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    `gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.deploy && mv .c.rc.deploy .c.rc`;

    $t = tests::Command->new( qq{./c --user-defined} );
    $t->exit_is( 0, qq{./c --user-defined} );
    $t->stdout_like( qr/^=== User Defined ===\n/ );
    $t->stdout_like( qr/\n====================\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{STDIN} => sub{
    my $t;

    $t = tests::Command->new( qq{echo '１２３，４５６－５９ ＋ １２３．４５６＊２＝' | ./c} );
    $t->exit_is( 0, qq{echo '１２３，４５６－５９ ＋ １２３．４５６＊２＝' | ./c} );
    $t->stdout_is( qq{123643.912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Command->new( qq{echo '123 2(=' | ./c} );
    $t->exit_isnt( 0, qq{echo '123 2(=' | ./c} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: parser: error: The position of the "\)" is incorrect\.\n/ );
    undef( $t );
};

&tests::Command::TestPostProc( $ENV{TEST_TARGET_CMD} );
