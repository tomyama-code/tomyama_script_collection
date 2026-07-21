#!/usr/bin/env perl
################################################################################
## - $Revision: 1.13 $
################################################################################

use strict;
use warnings;

#use lib '.';
use FindBin;            # first released with perl 5.00307
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Tester;

my $UV_bit_width = log( ~0 + 1 ) / log( 2 );    # perlの整数は固定幅ではないので桁溢れしない。
#print( qq{\$UV_bit_width="$UV_bit_width"\n} );

`gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.deploy && mv .c.rc.deploy .c.rc`;

use FTCalc;

if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    my %def_val;
    $def_val{def_timeout} = 2.0;
    &FTCalc::set_default_value( %def_val );
}

## 座標：緯度・経度

## ガラパゴス諸島
my $deg_Galapagos_Iss_Lat = "-0.3831";
my $deg_Galapagos_Iss_Lon = "-90.42333";
my $deg_Galapagos_Iss     = "$deg_Galapagos_Iss_Lat, $deg_Galapagos_Iss_Lon";
my $dms_Galapagos_Iss_Lat = "-0, -22, -59.16";
my $dms_Galapagos_Iss_Lon = "-90, -25, -23.9880000000255";

## マダガスカル島
my $deg_Madagascar_Lat = "-18.76694";
my $deg_Madagascar_Lon = "46.8691";
my $deg_Madagascar     = "$deg_Madagascar_Lat, $deg_Madagascar_Lon";

## ウォータールー駅
my $deg_Waterloo_St = "51.50324, -0.1134";

## ユニオン駅
my $deg_Union_St = "43.64524, -79.38063";

## 東京駅
my $deg_Tokyo_St_Lat = "35.68129";
my $deg_Tokyo_St_Lon = "139.76706";
my $deg_Tokyo_St     = "$deg_Tokyo_St_Lat, $deg_Tokyo_St_Lon";
my $dms_Tokyo_St_Lat = "35, 40, 52.6439999999894";
my $dms_Tokyo_St_Lon = "139, 46, 1.41599999995151";
my $dms_Tokyo_St     = "$dms_Tokyo_St_Lat, $dms_Tokyo_St_Lon";

## 大阪駅
my $deg_Osaka_St_Lat = "34.70248";
my $deg_Osaka_St_Lon = "135.49595";
my $deg_Osaka_St     = "$deg_Osaka_St_Lat, $deg_Osaka_St_Lon";
my $dms_Osaka_St_Lat = "34, 42, 6.8";
my $dms_Osaka_St_Lon = "135, 29, 41.9";
my $dms_Osaka_St     = "$dms_Osaka_St_Lat, $dms_Osaka_St_Lon";

## 昭和基地
my $deg_Showa_Base_Lat = "-69.00439";
my $deg_Showa_Base_Lon = "39.5822";
my $deg_Showa_Base     = "$deg_Showa_Base_Lat, $deg_Showa_Base_Lon";
my $dms_Showa_Base = "-69, 0, -15.8040000000028, 39, 34, 55.920000000001";

subtest qq{Normal (In-Proc Test)} => sub{
    my $c = FTCalc->new();
    my $t;
    my $res;

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{123456-59+123.456*2=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 123643.912 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{123456-(59+123.456)*2=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 123091.088 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{123+45*6-7=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 386, qq{整数の計算} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{１２３，４５６－５９ ＋ １２３．４５６＊２＝} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 123643.912 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{１２３，４５６－５９ ＋ １２３．４５６（３－１）＝} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 123643.912 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{１２３，４５６－５９ ＋ １２３．４５６（３－２＊１＋１）＝} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 123643.912 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{１２３，４５６－５９ ＋ １２３．４５６（（３－２）＊１＋１）＝} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 123643.912 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{１２３，４５６＋－５９ ＋ １２３．４５６（（３－２）＊１＋１）＝} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 123643.912 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{round( geo_distance_km( 北緯５１．５０３２４度、西経０．１１３４度,　南緯６９．００４３９°，東経３９．５８２２° ), 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 13756 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{round( geo_distance_km( 51°30'11.6639999999933"N, 0°6'48.24"W,　69°0'15.8040000000028"S，39°34'55.920000000001"E ), 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 13756 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{2--10=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 12 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{2/-10=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -0.2 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{3+10%3=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 4 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    my $os_org = $c->_getOutputSel();
    $c->_setOutputSel( FTC_FSC_OUTPUT_RESULT );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{3+0xf*2=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 33, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 33 \[ = 0x21 \]\n}, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{0x0055**2-0XC-2=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 7211, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 7211 \[ = 0x1C2B \]\n}, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{0x9+0xc&0xe=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 4, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 4 \[ = 0x4 \]\n}, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{0x9&0xc+0xe=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 8, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 8 \[ = 0x8 \]\n}, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{0x9+0xc|0xe=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 31, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 31 \[ = 0x1F \]\n}, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{0x9|0xc+0xe=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 27, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 27 \[ = 0x1B \]\n}, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{0x1 ^ 0x2 =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 3, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 3 [ = 0x3 ]\n}, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{0x3 ^ 0x2 =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 1 [ = 0x1 ]\n}, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{0x3 ^ 0x3 =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 0 [ = 0x0 ]\n}, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{5 ^ 3 =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 6, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 6 [ = 0x6 ]\n}, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{0x6 << 1} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 12, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 12 [ = 0xC ]\n}, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{0x6 >> 1} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 3, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 3 [ = 0x3 ]\n}, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    my $num_of_shifts = $UV_bit_width - 1;
    my $expect_L = qq{ Result: 9223372036854775808 [ = -9223372036854775808 ] [ = 0x8000000000000000 ]\n};
    my $arg_R = 9223372036854775808;
    if( $UV_bit_width == 32 ){
        $expect_L = qq{ Result: 2147483648 [ = -2147483648 ] [ = 0x80000000 ]\n};
        $arg_R = 2147483648;
    }

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{1 << $num_of_shifts} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, $arg_R, qq{数値のみ受け取る} );
    $t->stdout_is( $expect_L, qq{UVの最大シフト数: $num_of_shifts} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{$arg_R >> $num_of_shifts} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{数値のみ受け取る} );
    $t->stdout_is( qq{ Result: 1 [ = 0x1 ]\n}, qq{UVの最大シフト数: $num_of_shifts} );
    $t->stderr_is( qq{} );

    my $expect = qq{ Result: 18446744073709551615 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    $arg_R = 18446744073709551615;
    if( $UV_bit_width == 32 ){
        $expect = qq{ Result: 4294967295 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
        $arg_R  = 4294967295;
    }
    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{~1+1=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, $arg_R, qq{数値のみ受け取る} );
    $t->stdout_is( $expect, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $expect = qq{ Result: 18446744073709551615 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    $arg_R  = 18446744073709551615;
    if( $UV_bit_width == 32 ){
        $expect = qq{ Result: 4294967295 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
        $arg_R  = 4294967295;
    }
    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{1+~1=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, $arg_R, qq{数値のみ受け取る} );
    $t->stdout_is( $expect, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $expect = qq{ Result: 36893488147419103232 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    $arg_R  = 36893488147419103232;
    if( $UV_bit_width == 32 ){
        $expect = qq{ Result: 8589934588 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
        $arg_R  = 8589934588;
    }
    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{~1*2=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, $arg_R, qq{数値のみ受け取る} );
    $t->stdout_is( $expect, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $expect = qq{ Result: 36893488147419103232 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    $arg_R  = 36893488147419103232;
    if( $UV_bit_width == 32 ){
        $expect = qq{ Result: 8589934588 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
        $arg_R  = 8589934588;
    }
    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{2*~1=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, $arg_R, qq{数値のみ受け取る} );
    $t->stdout_is( $expect, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $expect = qq{ Result: 36893488147419103232 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    $arg_R  = 36893488147419103232;
    if( $UV_bit_width == 32 ){
        $expect = qq{ Result: 8589934588 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
        $arg_R  = 8589934588;
    }
    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{2*~1=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, $arg_R, qq{数値のみ受け取る} );
    $t->stdout_is( $expect, qq{複雑な書式をそのまま出力していること} );
    $t->stderr_is( qq{} );

    $c->_setOutputSel( $os_org );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{（１９２０＊＊２＋１０８０＊＊２）＝} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 4852800 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{√(1920**2+1080**2)=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2202.90717008 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{２π１０＝} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 62.8318530718, qq{２π１０＝62.83185307179586476925286766559} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ＳＱＲＴ(1920**2+1080**2)=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2202.90717008, qq{2202.90717008} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{sqrt(power(1920,2)+power(1080,2))=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2202.90717008, qq{2202.90717008} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{sqrt( power( 1920, 2 ) + power( 1080, 2 ) ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2202.90717008, qq{2202.90717008} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{sqrt( 1920 ** 2, 1080 ** 2 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 1920, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 1080, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{hypot( 1920, 1080 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2202.90717008, qq{2202.90717008} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angle_deg( 1920, 1080 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 29.3577535428, qq{29.3577535428} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angle_deg( 1920, 1080, 0 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 29.3577535428, qq{29.3577535428} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angle_deg( 1920, 1080, 1 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 60.6422464572, qq{60.6422464572} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dist_between_points( -50, -50, 50, 50 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 141.421356237, qq{141.421356237} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

#    $t = tests::Tester->run_blk( sub{
#        $res = $c->formula( qq{dist_between_points( -50, -50, -50, 50, 50 )=} );
#    } );
#    #$t->dump();
#    ok( defined( $t->exception ), '例外（die）が発生すること' );
#    $t->exit_isnt( 0 );
#    #equal( $res, 141.421356237, qq{141.421356237} );
#    $t->stdout_is( qq{} );
##    $t->stderr_like( qr/^c: evaluator: error: dist_between_points: \$argc=5: Invalid number of arguments\.\n/ );
#    $t->exception_like( qr/^FTCalc: warn: There is no data in the standard input / );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dist_between_points( -50, -50, -50, 50, 50, 50 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 173.205080757, qq{173.205080757} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{midpt_between_points( -50, -50, 50, 50 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 0, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 0, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );




    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{midpt_between_points( -50, -50, -50, 50, 50, 50 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 0, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 0, qq{リストを受け取る} );
    equal( ${ $res }[ 2 ], 0, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angle_between_points( -50, -50, 50, 75 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 51.3401917459, qq{51.3401917459} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angle_between_points( -50, -50, 50, 75, 0 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 51.3401917459, qq{51.3401917459} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angle_between_points( -50, -50, 50, 75, 1 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 38.6598082541, qq{38.6598082541} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angle_between_points( 50, -50, -50, 75, 1 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 321.340191746, qq{321.340191746} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angle_between_points( -50, -50, -50, 50, 75, 50 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 51.3401917459, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 31.9928170002, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angle_between_points( -50, -50, -50, 50, 75, 50, 0 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 51.3401917459, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 31.9928170002, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angle_between_points( -50, -50, -50, 50, 75, 50, 1 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 38.6598082541, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 31.9928170002, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angle_between_points( 50, -50, -50, -50, 75, 50, 1 )=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 321.340191746, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 31.9928170002, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{vector_angle( 100, 100, 100, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 45 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{vector_angle( 100, 0, 100, 100, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.785398163397, qq{0.785398163397} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{vector_angle( 2309627.42153, -5833452.97682, 1143792.85864, -3959659.21279, 3350075.51702, 3699524.90488 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 127.008055363, qq{127.008055363} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{vector_angle( -3959659.21279, 3350075.51702, 3699524.90488, 2309627.42153, -5833452.97682, 1143792.85864, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2.21670874265, qq{2.21670874265} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{vector_angle( -100, -100, 100, -100, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 90 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dist_between_points( geo2xyz( deg2rad( 35.6, 139.0 ), -20 * 1000 ), geo2xyz( deg2rad( $deg_Tokyo_St ) ) ) / 1000} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 72.7492079698, qq{72.7492079698} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

#    $t = tests::Tester->run_blk( sub{
#        $res = $c->formula( qq{sqrt(pow(2, 100)+pow(2, 100))=} );
#    } );
#    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
#    $t->exit_is( 0 );
#    equal( $res, 1592262918131443.25, qq{1592262918131443.25} );
#    $t->stdout_is( qq{} );
#    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{pow(2+1,2*2)=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 81 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{pow(6/2,pow(2,1)*2)=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 81 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{pow(-1+2**2,pow(2,1)*2)=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 81 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{pow(1+sqrt(4),pow(2,1)*2)=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 81 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

#    $t = tests::Tester->run_blk( sub{
#        $res = $c->formula( qq{0.22*10**(-6)=} );
#    } );
#    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
#    $t->exit_is( 0 );
#    equal( $res, 0.00000022, qq{0.00000022} );
#    $t->stdout_is( qq{} );
#    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ｄｅｇ２ｒａｄ（１８０）＝} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 3.14159265359, qq{ｄｅｇ２ｒａｄ（１８０）＝3.14159265359} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ｒａｄ２ｄｅｇ（ｐｉ／２）＝} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 90 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{1/cos(deg2rad(45))=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.41421356237, qq{1/cos(deg2rad(45))=1.41421356237} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{1080/sin(deg2rad(45))=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1527.35064736, qq{1080/sin(deg2rad(45))=1527.35064736} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rad2deg(asin(1080/1527.3506473629426527058238221465))=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 45 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{1920/cos(deg2rad(45))=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2715.29003976 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rad2deg(acos(1920/2715.2900397563424936992423504826))=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 45 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rad2deg(atan(1080/1920))=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 29.3577535428 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rad2deg( 2.26892802759263, 2.0943951023932 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 130, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 120, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{1920*tan(deg2rad(29.3577535427913))=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1080 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2deg( $dms_Osaka_St_Lat )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 34.7018888889 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2deg( $dms_Osaka_St_Lon )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 135.494972222 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2deg( $dms_Tokyo_St_Lat )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 35.68129 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2deg( $dms_Tokyo_St_Lon )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 139.76706 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2deg( $dms_Galapagos_Iss_Lat )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -0.3831 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2deg( $dms_Galapagos_Iss_Lon )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -90.42333 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2deg( $dms_Tokyo_St )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 35.68129, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 139.76706, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2rad( $dms_Osaka_St_Lat )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.605662217772 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2rad( $dms_Osaka_St_Lon )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2.36483338518 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2rad( $dms_Tokyo_St_Lat )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.622755991859 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2rad( $dms_Tokyo_St_Lon )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2.43939538283 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2rad( $dms_Tokyo_St_Lat ) - dms2rad( $dms_Osaka_St_Lat )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.017093774087 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2rad( $dms_Tokyo_St_Lon ) - dms2rad( $dms_Osaka_St_Lon )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.074561997656 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2rad( $dms_Galapagos_Iss_Lat )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -0.006686356364 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2rad( $dms_Galapagos_Iss_Lon )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -1.57818482912 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2rad( -90, -25.399800000000425, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -1.57818482912 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2rad( $deg_Galapagos_Iss_Lon, 0, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -1.57818482912 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2rad( $dms_Galapagos_Iss_Lon, $dms_Galapagos_Iss_Lon )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], -1.57818482912, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], -1.57818482912, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{deg2dms( $deg_Madagascar_Lat )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], -18, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], -46, qq{リストを受け取る} );
    equal( ${ $res }[ 2 ], -0.984000000006, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{deg2dms( $deg_Madagascar_Lon )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 46, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 52, qq{リストを受け取る} );
    equal( ${ $res }[ 2 ], 8.76000000001, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{deg2dms( dms2deg( -18, -46.01640000000010388333333333333333, -0 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], -18, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], -46, qq{リストを受け取る} );
    equal( ${ $res }[ 2 ], -0.984000000006, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{deg2dms( dms2deg( 46, 52.1460000000001855, 0 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 46, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 52, qq{リストを受け取る} );
    equal( ${ $res }[ 2 ], 8.76000000001, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{deg2dms( abs( $deg_Galapagos_Iss_Lat ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{( \$d == 0 and \$deg < 0 ) : true, false} );
    equal( ${ $res }[ 0 ], 0, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 22, qq{リストを受け取る} );
    equal( ${ $res }[ 2 ], 59.16, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2deg( deg2dms( $deg_Galapagos_Iss_Lat ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -0.3831 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{deg2dms( $deg_Galapagos_Iss_Lat )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], '-0', qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], -22, qq{リストを受け取る} );
    equal( ${ $res }[ 2 ], -59.16, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2deg( deg2dms( $deg_Galapagos_Iss_Lat ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -0.3831 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{deg2dms( 40.6983333333333, 143.595 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 6, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 40, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], 41, qq{リストを受け取る} );
    equal( ${ $res }[ 2 ], 53.9999999999, qq{リストを受け取る} );
    equal( ${ $res }[ 3 ], 143, qq{リストを受け取る} );
    equal( ${ $res }[ 4 ], 35, qq{リストを受け取る} );
    equal( ${ $res }[ 5 ], 42, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2dms( $deg_Galapagos_Iss_Lat, 0, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], '-0', qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], -22, qq{リストを受け取る} );
    equal( ${ $res }[ 2 ], -59.16, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2dms( $deg_Galapagos_Iss_Lat, 0, 0, $deg_Showa_Base_Lat, 0, 0, $deg_Showa_Base_Lon, 0, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 9, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], '-0', qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], -22, qq{リストを受け取る} );
    equal( ${ $res }[ 2 ], -59.16, qq{リストを受け取る} );
    equal( ${ $res }[ 3 ], -69, qq{リストを受け取る} );
    equal( ${ $res }[ 4 ], 0, qq{リストを受け取る} );
    equal( ${ $res }[ 5 ], -15.804, qq{リストを受け取る} );
    equal( ${ $res }[ 6 ], 39, qq{リストを受け取る} );
    equal( ${ $res }[ 7 ], 34, qq{リストを受け取る} );
    equal( ${ $res }[ 8 ], 55.92, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dms2dms( -30, -5 + 5.5, -24 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], -29, qq{リストを受け取る} );
    equal( ${ $res }[ 1 ], -59, qq{リストを受け取る} );
    equal( ${ $res }[ 2 ], -54, qq{リストを受け取る} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_radius( deg2rad( 0 ) ) / 1000 =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 6378.137, qq{地球の赤道半径（km）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_radius( deg2rad( $deg_Tokyo_St_Lat ) ) / 1000 =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 6370.90194344, qq{地球が楕円である事を考慮して地球の中心から東京駅（地表）までの距離（km）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{radius_of_lat( deg2rad( $deg_Tokyo_St_Lat ) ) / 1000 =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 5186.70483555, qq{地球が楕円である事を考慮して東京駅を通る緯線の半径（km）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_distance_m( deg2rad( $deg_Tokyo_St_Lat ), deg2rad( $deg_Tokyo_St_Lon ), deg2rad( $deg_Osaka_St_Lat ), deg2rad( $deg_Osaka_St_Lon ) ) / 1000} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 403.822719846, qq{東京駅から大阪駅までの距離（km）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_distance_m( dms2rad( $dms_Tokyo_St ), dms2rad( $dms_Showa_Base ) ) / 1000} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 14056.1311832, qq{東京駅から昭和基地までの距離（km）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_azimuth( dms2rad( $dms_Tokyo_St ), dms2rad( $dms_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 206.108012524, qq{東京駅から昭和基地までの方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_azimuth( deg2rad( $deg_Waterloo_St ), deg2rad( $deg_Union_St ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 294.538064998, qq{ウォータールー駅からユニオン駅までの方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_dist_m_and_azimuth( dms2rad( $dms_Tokyo_St ), dms2rad( $dms_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 14056131.1832, qq{東京駅から昭和基地までの距離（m）} );
    equal( ${ $res }[ 1 ], 206.108012524, qq{東京駅から昭和基地までの方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_dist_km_and_azimuth( dms2rad( $dms_Tokyo_St ), dms2rad( $dms_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 14056.1311832, qq{東京駅から昭和基地までの距離（km）} );
    equal( ${ $res }[ 1 ], 206.108012524, qq{東京駅から昭和基地までの方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_rl_distance_m( deg2rad( $deg_Tokyo_St ), deg2rad( $deg_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 14484256.5649, qq{東京駅から昭和基地までの等角航路の距離（m）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_rl_distance_km( deg2rad( $deg_Tokyo_St ), deg2rad( $deg_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 14484.2565649, qq{東京駅から昭和基地までの等角航路の距離（km）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_rl_azimuth( deg2rad( $deg_Tokyo_St ), deg2rad( $deg_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 216.733277422, qq{東京駅から昭和基地までの等角航路の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_rl_azimuth( deg2rad( $deg_Galapagos_Iss ), deg2rad( $deg_Tokyo_St ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 286.477790179, qq{ガラパゴス諸島から東京駅までの等角航路の方角（度）。( \$dlon > pi )} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_rl_azimuth( deg2rad( $deg_Tokyo_St ), deg2rad( $deg_Galapagos_Iss ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 106.477790179, qq{東京駅からガラパゴス諸島までの等角航路の方角（度）。( \$dlon < -pi )} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_rl_dist_m_and_azimuth( deg2rad( $deg_Tokyo_St ), deg2rad( $deg_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 14484256.5649, qq{東京駅から昭和基地までの等角航路の距離（m）} );
    equal( ${ $res }[ 1 ], 216.733277422, qq{東京駅から昭和基地までの等角航路の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_rl_dist_km_and_azimuth( deg2rad( $deg_Tokyo_St ), deg2rad( $deg_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{リストを受け取る} );
    equal( ${ $res }[ 0 ], 14484.2565649, qq{東京駅から昭和基地までの等角航路の距離（km）} );
    equal( ${ $res }[ 1 ], 216.733277422, qq{東京駅から昭和基地までの等角航路の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_all_m( deg2rad( $deg_Tokyo_St ), deg2rad( $deg_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 4, qq{東京駅から昭和基地まで} );
    equal( ${ $res }[ 0 ], 14056131.1832, qq{大圏航路（Great Circle）の距離（m）} );
    equal( ${ $res }[ 1 ], 206.108012524, qq{大圏航路（Great Circle）の方角（度）} );
    equal( ${ $res }[ 2 ], 14484256.5649, qq{等角航路（Rhumb Line）の距離（m）} );
    equal( ${ $res }[ 3 ], 216.733277422, qq{等角航路（Rhumb Line）の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_all_km( deg2rad( $deg_Tokyo_St ), deg2rad( $deg_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 4, qq{東京駅から昭和基地まで} );
    equal( ${ $res }[ 0 ], 14056.1311832, qq{大圏航路（Great Circle）の距離（km）} );
    equal( ${ $res }[ 1 ], 206.108012524, qq{大圏航路（Great Circle）の方角（度）} );
    equal( ${ $res }[ 2 ], 14484.2565649, qq{等角航路（Rhumb Line）の距離（km）} );
    equal( ${ $res }[ 3 ], 216.733277422, qq{等角航路（Rhumb Line）の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_all_km( deg2rad( $deg_Waterloo_St ), deg2rad( $deg_Waterloo_St ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 4, qq{同一地点の距離と方位角} );
    equal( ${ $res }[ 0 ], 0, qq{大圏航路（Great Circle）の距離（km）} );
    equal( ${ $res }[ 1 ], 0, qq{大圏航路（Great Circle）の方角（度）} );
    equal( ${ $res }[ 2 ], 0, qq{等角航路（Rhumb Line）の距離（km）} );
    equal( ${ $res }[ 3 ], 0, qq{等角航路（Rhumb Line）の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_all_km( deg2rad( 0, 90, 0, -90 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 4, qq{赤道上のケース} );
    equal( ${ $res }[ 0 ], 19903.5933909, qq{大圏航路（Great Circle）の距離（km）} );
    equal( ${ $res }[ 1 ], 270, qq{大圏航路（Great Circle）の方角（度）} );
    equal( ${ $res }[ 2 ], 20037.5083428, qq{等角航路（Rhumb Line）の距離（km）} );
    equal( ${ $res }[ 3 ], 270, qq{等角航路（Rhumb Line）の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_all_km( deg2rad( 0, 180, 0, -180 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 4, qq{対蹠点（真裏）, 経度の正規化（ー）} );
    equal( ${ $res }[ 0 ], 0, qq{大圏航路（Great Circle）の距離（km）} );
    equal( ${ $res }[ 1 ], 0, qq{大圏航路（Great Circle）の方角（度）} );
    equal( ${ $res }[ 2 ], 0, qq{等角航路（Rhumb Line）の距離（km）} );
    equal( ${ $res }[ 3 ], 0, qq{等角航路（Rhumb Line）の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_all_km( deg2rad( 0, -180, 0, 180 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 4, qq{対蹠点（真裏）, 経度の正規化（＋）} );
    equal( ${ $res }[ 0 ], 0, qq{大圏航路（Great Circle）の距離（km）} );
    equal( ${ $res }[ 1 ], 0, qq{大圏航路（Great Circle）の方角（度）} );
    equal( ${ $res }[ 2 ], 0, qq{等角航路（Rhumb Line）の距離（km）} );
    equal( ${ $res }[ 3 ], 0, qq{等角航路（Rhumb Line）の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{geo_all_km( deg2rad( 0, 0, 45, -10 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 4, qq{ラジアンの正規化（ー）} );
    equal( ${ $res }[ 0 ], 5081.68969015, qq{大圏航路（Great Circle）の距離（km）} );
    equal( ${ $res }[ 1 ], 350.091119424, qq{大圏航路（Great Circle）の方角（度）} );
    equal( ${ $res }[ 2 ], 5082.78218063, qq{等角航路（Rhumb Line）の距離（km）} );
    equal( ${ $res }[ 3 ], 348.739975473, qq{等角航路（Rhumb Line）の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

#    $t = tests::Tester->run_blk( sub{
#        $res = $c->formula( qq{geo_all_km( 10, 10, -10, -10 )} );
#    } );
#    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
#    $t->exit_is( 0 );
#    equal( scalar( @{ $res } ), 4, qq{引数（座標）の正規化} );
#    equal( ${ $res }[ 0 ], 10045.2740731, qq{大圏航路（Great Circle）の距離（km）} );
#    equal( ${ $res }[ 1 ], 309.826898594, qq{大圏航路（Great Circle）の方角（度）} );
#    equal( ${ $res }[ 2 ], 10058.0659261, qq{等角航路（Rhumb Line）の距離（km）} );
#    equal( ${ $res }[ 3 ], 316.502246503, qq{等角航路（Rhumb Line）の方角（度）} );
#    $t->stdout_is( qq{} );
#    $t->stderr_like( qr/^Coordinates out of range: /, qq{警告メッセージ} );

#    $t = tests::Tester->run_blk( sub{
#        $res = $c->formula( qq{geo_all_km( 1, 4, 2, -100 )} );
#    } );
#    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
#    $t->exit_is( 0 );
#    equal( scalar( @{ $res } ), 4, qq{引数（座標）の正規化} );
#    equal( ${ $res }[ 0 ], 1341.45302198, qq{大圏航路（Great Circle）の距離（km）} );
#    equal( ${ $res }[ 1 ], 319.995434444, qq{大圏航路（Great Circle）の方角（度）} );
#    equal( ${ $res }[ 2 ], 1346.08951591, qq{等角航路（Rhumb Line）の距離（km）} );
#    equal( ${ $res }[ 3 ], 312.190223662, qq{等角航路（Rhumb Line）の方角（度）} );
#    $t->stdout_is( qq{} );
#    $t->stderr_like( qr/^Coordinates out of range: /, qq{警告メッセージ} );

#    $t = tests::Tester->run_blk( sub{
#        $res = $c->formula( qq{geo_all_km( 100, 100, -100, -100 )} );
#    } );
#    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
#    $t->exit_is( 0 );
#    equal( scalar( @{ $res } ), 4, qq{引数（座標）の正規化} );
#    equal( ${ $res }[ 0 ], 9315.0650115, qq{大圏航路（Great Circle）の距離（km）} );
#    equal( ${ $res }[ 1 ], 49.4032576339, qq{大圏航路（Great Circle）の方角（度）} );
#    equal( ${ $res }[ 2 ], 9323.62154307, qq{等角航路（Rhumb Line）の距離（km）} );
#    equal( ${ $res }[ 3 ], 43.7610906052, qq{等角航路（Rhumb Line）の方角（度）} );
#    $t->stdout_is( qq{} );
#    $t->stderr_like( qr/^Coordinates out of range: /, qq{警告メッセージ} );

#    $t = tests::Tester->run_blk( sub{
#        $res = $c->formula( qq{geo_all_km( 1, -4, 1, 4 )} );
#    } );
#    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
#    $t->exit_is( 0 );
#    equal( scalar( @{ $res } ), 4, qq{( P  A B  dec ) = ( 1  0 1  0 )} );
#    equal( ${ $res }[ 0 ], 5386.30789906, qq{大圏航路（Great Circle）の距離（km）} );
#    equal( ${ $res }[ 1 ], 45.7429575198, qq{大圏航路（Great Circle）の方角（度）} );
#    equal( ${ $res }[ 2 ], 5930.42524018, qq{等角航路（Rhumb Line）の距離（km）} );
#    equal( ${ $res }[ 3 ], 90, qq{等角航路（Rhumb Line）の方角（度）} );
#    $t->stdout_is( qq{} );
#    $t->stderr_like( qr/^Coordinates out of range: /, qq{警告メッセージ} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{epoch2local( 1763999942 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 6, qq{年月日時分秒} );
    equal( ${ $res }[ 0 ], 2025 );
    equal( ${ $res }[ 1 ], 11 );
    equal( ${ $res }[ 2 ], 25 );
    equal( ${ $res }[ 3 ], 0 );
    equal( ${ $res }[ 4 ], 59 );
    equal( ${ $res }[ 5 ], 2 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{epoch2gmt( 1763999942 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 6, qq{年月日時分秒} );
    equal( ${ $res }[ 0 ], 2025 );
    equal( ${ $res }[ 1 ], 11 );
    equal( ${ $res }[ 2 ], 24 );
    equal( ${ $res }[ 3 ], 15 );
    equal( ${ $res }[ 4 ], 59 );
    equal( ${ $res }[ 5 ], 2 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{is_leap( 1996 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{is_leap( 1996 ) => 1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{is_leap( 1999 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{is_leap( 1999 ) => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{is_leap( 2000 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{is_leap( 2000 ) => 1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{is_leap( 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000, 2100 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 10, qq{閏年判定の確認} );
    equal( ${ $res }[ 0 ], 1, qq{is_leap( 1200 ) => 1} );
    equal( ${ $res }[ 1 ], 0, qq{is_leap( 1300 ) => 0} );
    equal( ${ $res }[ 2 ], 0, qq{is_leap( 1400 ) => 0} );
    equal( ${ $res }[ 3 ], 0, qq{is_leap( 1500 ) => 0} );
    equal( ${ $res }[ 4 ], 1, qq{is_leap( 1600 ) => 1} );
    equal( ${ $res }[ 5 ], 0, qq{is_leap( 1700 ) => 0} );
    equal( ${ $res }[ 6 ], 0, qq{is_leap( 1800 ) => 0} );
    equal( ${ $res }[ 7 ], 0, qq{is_leap( 1900 ) => 0} );
    equal( ${ $res }[ 8 ], 1, qq{is_leap( 2000 ) => 1} );
    equal( ${ $res }[ 9 ], 0, qq{is_leap( 2100 ) => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age( l2e( 2026-05-01 ), l2e( 2026-06-14 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{平月の31日（5月）を正しくまたいで計算できているか} );
    equal( ${ $res }[ 0 ], 0, qq{0 年} );
    equal( ${ $res }[ 1 ], 44, qq{44 日齢} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age( l2e( 2025年12月25日 ), l2e( 2026-06-14 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{年をまたいでも、エポック秒ベースで正確な日数が引けているか} );
    equal( ${ $res }[ 0 ], 0, qq{0 年} );
    equal( ${ $res }[ 1 ], 171, qq{171 日齢} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age( l2e( 2024年2月28日 ), l2e( 2024年3月1日 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{1日齢ではなく2日齢になること} );
    equal( ${ $res }[ 0 ], 0, qq{0 年} );
    equal( ${ $res }[ 1 ], 2, qq{2 日齢} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age( l2e( 2001年6月14日 ), l2e( 2026-06-14 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{当日なので、きっちり25歳になっていること} );
    equal( ${ $res }[ 0 ], 25, qq{25 年} );
    equal( ${ $res }[ 1 ], 0, qq{0 日齢} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age( l2e( 2001年6月15日 ), l2e( 2026-06-14 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{フライングして25歳にならず「24歳」を維持できていること} );
    equal( ${ $res }[ 0 ], 24, qq{24 年} );
    equal( ${ $res }[ 1 ], 364, qq{364 日齢} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age( l2e( 2001年6月15日 ), l2e( 2026-06-14 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{フライングして25歳にならず「24歳」を維持できていること} );
    equal( ${ $res }[ 0 ], 24, qq{24 年} );
    equal( ${ $res }[ 1 ], 364, qq{364 日齢} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age( l2e( 1999-03-02 ), l2e( 2020-03-01 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{日齢の最大値} );
    equal( ${ $res }[ 0 ], 20, qq{20 年} );
    equal( ${ $res }[ 1 ], 365, qq{365 日齢} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age( l2e( 2026年6月15日 ), l2e( 2026-06-14 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{誕生日が未来} );
    equal( ${ $res }[ 0 ], 0, qq{0 年} );
    equal( ${ $res }[ 1 ], -1, qq{-1 日齢} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age( l2e( 2026年06月14日 ), l2e( 2001-6-15 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{誕生日が未来} );
    equal( ${ $res }[ 0 ], -24, qq{-24 年} );
    equal( ${ $res }[ 1 ], -364, qq{-364 日齢} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age( l2e( 2000年1月1日 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{誕生日} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age_of_moon( 0, 1, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 24, qq{既存の挙動との変化を検知する為だけのテスト。西暦0年は存在しない。} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age_of_moon( 1900, 2, 28 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 28.3 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age_of_moon( 1999, 12, 31 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 23 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age_of_moon( 2000, 1, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 24 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age_of_moon( 2000, 2, 28 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 23 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age_of_moon( 2000, 2, 29 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 24 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age_of_moon( 2000, 03, 01 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 25 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age_of_moon( 2025, 12, 19 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 28.7 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age_of_moon( 2025, 12, 20 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.2 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age_of_moon_instant( gmt2epoch( 1969年7月20日 20時17分40秒 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 6.24701057982, qq{アポロ11号が月面に着陸した時} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{local2epoch( 2000, 12, 31, 23, 59, 59 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 978274799 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{local2epoch( ２０２６／３／１１　１６：００：０１ )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1773212401 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{local2epoch( 2026-03-11 16:00:01 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1773212401 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{local2epoch( 2026-03-11, 16:00:01 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1773212401 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gmt2epoch( 2000, 12, 31, 23, 59, 59 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 978307199 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{sec2dhms( gmt2epoch( 2040, 1, 1 ) - now )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 4, qq{未来} );
    ok( ${ $res }[ 0 ] >= 0, qq{日: ( ${ $res }[ 0 ] >= 0 )} );
    ok( ${ $res }[ 1 ] >= 0, qq{時: ( ${ $res }[ 1 ] >= 0 )} );
    ok( ${ $res }[ 2 ] >= 0, qq{分: ( ${ $res }[ 2 ] >= 0 )} );
    ok( ${ $res }[ 3 ] >= 0, qq{秒: ( ${ $res }[ 3 ] >= 0 )} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{sec2dhms( gmt2epoch( 2020, 1, 1 ) - now )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 4, qq{過去} );
    ok( ${ $res }[ 0 ] <= 0, qq{日: ( ${ $res }[ 0 ] <= 0 )} );
    ok( ${ $res }[ 1 ] <= 0, qq{時: ( ${ $res }[ 1 ] <= 0 )} );
    ok( ${ $res }[ 2 ] <= 0, qq{分: ( ${ $res }[ 2 ] <= 0 )} );
    ok( ${ $res }[ 3 ] <= 0, qq{秒: ( ${ $res }[ 3 ] <= 0 )} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{sec2dhms( 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 4, qq{日時分秒} );
    equal( ${ $res }[ 0 ], 0 );
    equal( ${ $res }[ 1 ], 0 );
    equal( ${ $res }[ 2 ], 0 );
    equal( ${ $res }[ 3 ], 0 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{epoch2local( local2epoch( 2020, 1, 1, 15, 0, 0 ) + dhms2sec( 10 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 6, qq{年月日時分秒} );
    equal( ${ $res }[ 0 ], 2020 );
    equal( ${ $res }[ 1 ], 1 );
    equal( ${ $res }[ 2 ], 11 );
    equal( ${ $res }[ 3 ], 15 );
    equal( ${ $res }[ 4 ], 0 );
    equal( ${ $res }[ 5 ], 0 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{epoch2local( local2epoch( 2020, 1, 1, 15, 0, 0 ) + dhms2sec( -2, 3, -4, 5 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 6, qq{年月日時分秒} );
    equal( ${ $res }[ 0 ], 2019 );
    equal( ${ $res }[ 1 ], 12 );
    equal( ${ $res }[ 2 ], 30 );
    equal( ${ $res }[ 3 ], 17 );
    equal( ${ $res }[ 4 ], 56 );
    equal( ${ $res }[ 5 ], 5 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dhms2dhms( 0, 24 / SAKUBOU )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 4, qq{日時分秒} );
    equal( ${ $res }[ 0 ], 0 );
    equal( ${ $res }[ 1 ], 0 );
    equal( ${ $res }[ 2 ], 48 );
    equal( ${ $res }[ 3 ], 45.7797882084 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ri2meter( 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 3927.27272727, qq{ri2meter( 1 ) => 3927.27272727} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{meter2ri( 4000 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.01851851852, qq{meter2ri( 4000 ) => 1.01851851852} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{mile2meter( 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1609.344, qq{mile2meter( 1 ) => 1609.344} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{meter2mile( 2000 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.24274238447, qq{meter2mile( 2000 ) => 1.24274238447} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{nautical_mile2meter( 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1852, qq{nautical_mile2meter( 1 ) => 1852} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{meter2nautical_mile( 2000 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.07991360691, qq{meter2nautical_mile( 2000 ) => 1.07991360691} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{inch2mm( 0.25 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 6.35, qq{inch2mm( 0.25 ) => 6.35} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{mm2inch( 12.7 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.5, qq{mm2inch( 12.7 ) => 0.5} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{pound2gram( 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 453.59237, qq{pound2gram( 1 ) => 453.59237} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gram2pound( 500 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.10231131092, qq{gram2pound( 500 ) => 1.10231131092} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ounce2gram( 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 28.349523125, qq{ounce2gram( 1 ) => 28.349523125} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gram2ounce( 30 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.05821885849, qq{gram2ounce( 30 ) => 1.05821885849} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{kgf2newton( 6.5 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 63.743225, qq{kgf2newton( 6.5 ) => 63.743225} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{newton2kgf( 64 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 6.52618376306, qq{newton2kgf( 64 ) => 6.52618376306} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{laptimer( 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{laptimer( 0 ) => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{telemeter_m( 8 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2725.2, qq{telemeter_m( 8 ) => 2725.2} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{telemeter_km( 8 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2.7252, qq{telemeter_km( 8 ) => 2.7252} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{telemeter( 8, 20 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2749.6, qq{telemeter( 8, 20 ) => 2749.6} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{exp( -2.3 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.100258843723, qq{exp( -2.3 ) => 0.100258843723} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{exp( -2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.135335283237, qq{exp( -2 ) => 0.135335283237} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{exp( -1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.367879441171, qq{exp( -1 ) => 0.367879441171} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{exp( 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{exp( 0 ) => 1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{exp( 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2.71828182846, qq{exp( 1 ) => 2.71828182846} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{exp( 2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 7.38905609893, qq{exp( 2 ) => 7.38905609893} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{exp( 2.3 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 9.97418245481, qq{exp( 2.3 ) => 9.97418245481} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{exp( -1, 0, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{3回の一括処理} );
    equal( ${ $res }[ 0 ], 0.367879441171, qq{exp( -1 ) => 0.367879441171} );
    equal( ${ $res }[ 1 ], 1,              qq{exp(  0 ) => 1} );
    equal( ${ $res }[ 2 ], 2.71828182846,  qq{exp(  1 ) => 2.71828182846} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{log(3)=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.09861228867, qq{log(3) => 1.09861228867} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $os_org = $c->_getOutputSel();
    $c->_setOutputSel( FTC_FSC_OUTPUT_RESULT );

    $expect = qq{ Result: 64 [ = 0x40 ]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{ Result: 32 [ = 0x20 ]\n};
    }
    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{log(~0+1)/log(2)=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{${UV_bit_width}bit: perlの整数は固定幅ではないが基本は64bitが多いはず。} );
    equal( $res, $UV_bit_width, qq{"~0+1": perlの整数は固定幅ではないので桁溢れしない。} );
    $t->stdout_is( $expect );
    $t->stderr_is( qq{} );

    $c->_setOutputSel( $os_org );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{log( 10, 100, 1000 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{3回の一括処理} );
    equal( ${ $res }[ 0 ], 2.30258509299, qq{log(   10 ) => 2.30258509299} );
    equal( ${ $res }[ 1 ], 4.60517018599, qq{log(  100 ) => 4.60517018599} );
    equal( ${ $res }[ 2 ], 6.90775527898, qq{log( 1000 ) => 6.90775527898} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{exp2( 10 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1024, qq{exp2( 10 ) => 1024} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{exp2( 8, 16, 32 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{3回の一括処理} );
    equal( ${ $res }[ 0 ],        256, qq{exp2(  8 ) => 256} );
    equal( ${ $res }[ 1 ],      65536, qq{exp2( 16 ) => 65536} );
    equal( ${ $res }[ 2 ], 4294967296, qq{exp2( 32 ) => 4294967296} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{log2( 4294967296 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 32, qq{log2( 4294967296 ) => 32} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{log2( 256, 65536, 4294967296 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{3回の一括処理} );
    equal( ${ $res }[ 0 ],  8, qq{log2(        256 ) =>  8} );
    equal( ${ $res }[ 1 ], 16, qq{log2(      65536 ) => 16} );
    equal( ${ $res }[ 2 ], 32, qq{log2( 4294967296 ) => 32} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{exp10( 5 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 100000, qq{exp10( 5 ) => 100000} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{exp10( 1, 2, 3 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{3回の一括処理} );
    equal( ${ $res }[ 0 ],   10, qq{exp10( 1 ) =>   10} );
    equal( ${ $res }[ 1 ],  100, qq{exp10( 2 ) =>  100} );
    equal( ${ $res }[ 2 ], 1000, qq{exp10( 3 ) => 1000} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{log10( 4294967296 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 9.63295986125, qq{log10( 4294967296 ) => 9.63295986125} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{log10( 10, 100, 1000 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{3回の一括処理} );
    equal( ${ $res }[ 0 ], 1, qq{log10(   10 ) => 1} );
    equal( ${ $res }[ 1 ], 2, qq{log10(  100 ) => 2} );
    equal( ${ $res }[ 2 ], 3, qq{log10( 1000 ) => 3} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $os_org = $c->_getOutputSel();
    $c->_setOutputSel( FTC_FSC_OUTPUT_RESULT );

    $expect = qq{ Result: 64 [ = 0x40 ]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{ Result: 32 [ = 0x20 ]\n};
    }
    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{pow_inv( ~0+1, 2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{${UV_bit_width}bit: perlの整数は固定幅ではないが基本は64bitが多いはず。} );
    equal( $res, $UV_bit_width, qq{"~0+1": perlの整数は固定幅ではないので桁溢れしない。} );
    $t->stdout_is( $expect );
    $t->stderr_is( qq{} );

    $expect = qq{ Result: ( 18446744073709551615, 18446744073709551614 ) [ = ( -1, -2 ) ] [ = ( 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFE ) ]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{ Result: ( 4294967295, 4294967294 ) [ = ( -1, -2 ) ] [ = ( 0xFFFFFFFF, 0xFFFFFFFE ) ]\n};
    }
    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{linstep( ~0, -1, 2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{2個のリストがあれば良し} );
    $t->stdout_is( $expect );
    $t->stderr_is( qq{} );

    $c->_setOutputSel( $os_org );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{pow_inv( 4294967296, 2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 32, qq{pow_inv( 4294967296, 2 ) => 32} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{pow_inv( 4294967297, 2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 32.0000000003, qq{pow_inv( 4294967297, 2 ) => 32.0000000003} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{2PI10=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 62.8318530718, qq{2PI10 => 62.8318530718} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{2･PI･10=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 62.8318530718, qq{2･PI･10 => 62.8318530718} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{２・ＰＩ・１０＝} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 62.8318530718, qq{２・ＰＩ・１０ => 62.8318530718} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{15/5=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 3, qq{15/5 => 3} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{5%-1.0=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{5%-1.0 => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{5%-0.9=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.5, qq{5%-0.9 => 0.5} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{5%0.9=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.5, qq{5%0.9 => 0.5} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{5%1.0=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{5%1.0 => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{10 % 3} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{10 % 3 => 1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{10 % -3} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{10 % -3 => 1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{-10 % 3} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -1, qq{-10 % 3 => -1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{-10 % -3} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -1, qq{-10 % -3 => -1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{10.987 % 3} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.987, qq{10.987 % 3 => 1.987} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{12(3 2)2=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{暗黙の乗算記号(*)を補完} );
    equal( $res, 144, qq{12(3 2)2 => 144} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{2 3 4 =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{暗黙の乗算記号(*)を補完} );
    equal( $res, 24, qq{2 3 4 => 24} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{-10=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -10, qq{-10 => -10} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{0 => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rad2deg(atan2(100, 200))=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 26.5650511771, qq{rad2deg(atan2(100, 200)) => 26.5650511771} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{fmod( 10.234, 3 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.234, qq{fmod( 10.234, 3 ) => 1.234} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{fmod( 10, -1.2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0.4, qq{fmod( 10, -1.2 ) => 0.4} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{math_mod( -100, -10 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{( A B C D ) = ( 0 0 0 1 )} );
    equal( $res, 0, qq{math_mod( -100, -10 ) => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{math_mod( 10, -1.2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{( A B C D ) = ( 0 0 1 1 )} );
    equal( $res, -0.8, qq{math_mod( 10, -1.2 ) => -0.8} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{math_mod( -1.2, 1.2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{( A B C D ) = ( 0 1 0 0 )} );
    equal( $res, 0, qq{math_mod( -1.2, 1.2 ) => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{math_mod( 1.2, 12.1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{( A B C D ) = ( 0 1 1 0 )} );
    equal( $res, 1.2, qq{math_mod( 1.2, 12.1 ) => 1.2} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{math_mod( -10, -1.2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{( A B C D ) = ( 1 0 0 1 )} );
    equal( $res, -0.4, qq{math_mod( -10, -1.2 ) => -0.4} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{math_mod( -1.2, 12.1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{( A B C D ) = ( 1 1 0 0 )} );
    equal( $res, 10.9, qq{math_mod( -1.2, 12.1 ) => 10.9} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{abs(-29.3577535427913)=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 29.3577535428, qq{abs(-29.3577535427913) => 29.3577535428} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{( abs( -1.2, 1.2 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{2回の一括処理} );
    equal( ${ $res }[ 0 ], 1.2, qq{abs( -1.2 ) => 1.2} );
    equal( ${ $res }[ 1 ], 1.2, qq{abs(  1.2 ) => 1.2} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{int(10/3*100+0.5)/100=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 3.33, qq{int(10/3*100+0.5)/100 => 3.33} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{( int( -1.2, 1.2 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{2回の一括処理} );
    equal( ${ $res }[ 0 ], -1, qq{int( -1.2 ) => -1} );
    equal( ${ $res }[ 1 ],  1, qq{int(  1.2 ) =>  1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{floor( 192.168 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 192, qq{floor( 192.168 ) => 192} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{floor( -192.168 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -193, qq{floor( -192.168 ) => -193} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{( floor( -1.2, 1.2 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{2回の一括処理} );
    equal( ${ $res }[ 0 ], -2, qq{floor( -1.2 ) => -2} );
    equal( ${ $res }[ 1 ],  1, qq{floor(  1.2 ) =>  1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ceil( 192.168 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 193, qq{ceil( 192.168 ) => 193} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ceil( -192.168 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -192, qq{ceil( -192.168 ) => -192} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{( ceil( -1.2, 1.2 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{2回の一括処理} );
    equal( ${ $res }[ 0 ], -1, qq{ceil( -1.2 ) => -1} );
    equal( ${ $res }[ 1 ],  2, qq{ceil(  1.2 ) =>  2} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rounddown( 192.168, 2 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 192.16, qq{rounddown( 192.168, 2 ) => 192.16} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{round( 192.168, 2 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 192.17, qq{round( 192.168, 2 ) => 192.17} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{roundup( 192.168, 2 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 192.17, qq{roundup( 192.168, 2 ) => 192.17} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rounddown( -192.168, 2 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -192.16, qq{rounddown( -192.168, 2 ) => -192.16} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{round( -192.168, 2 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -192.17, qq{round( -192.168, 2 ) => -192.17} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{roundup( -192.168, 2 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -192.17, qq{roundup( -192.168, 2 ) => -192.17} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rounddown( -192.168, 3 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -192.168, qq{rounddown( -192.168, 3 ) => -192.168} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{round( -192.168, 3 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -192.168, qq{round( -192.168, 3 ) => -192.168} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{roundup( -192.168, 3 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -192.168, qq{roundup( -192.168, 3 ) => -192.168} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rounddown( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 7, qq{7回の一括処理} );
    equal( ${ $res }[ 0 ], -1  , qq{rounddown( -1  , 1 ) => -1  } );
    equal( ${ $res }[ 1 ], -0.5, qq{rounddown( -0.5, 1 ) => -0.5} );
    equal( ${ $res }[ 2 ], -0.4, qq{rounddown( -0.4, 1 ) => -0.4} );
    equal( ${ $res }[ 3 ],  0  , qq{rounddown(  0  , 1 ) =>  0  } );
    equal( ${ $res }[ 4 ],  0.4, qq{rounddown(  0.4, 1 ) =>  0.4} );
    equal( ${ $res }[ 5 ],  0.5, qq{rounddown(  0.5, 1 ) =>  0.5} );
    equal( ${ $res }[ 6 ],  1  , qq{rounddown(  1  , 1 ) =>  1  } );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{round( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 7, qq{7回の一括処理} );
    equal( ${ $res }[ 0 ], -1  , qq{round( -1  , 1 ) => -1  } );
    equal( ${ $res }[ 1 ], -0.5, qq{round( -0.5, 1 ) => -0.5} );
    equal( ${ $res }[ 2 ], -0.4, qq{round( -0.4, 1 ) => -0.4} );
    equal( ${ $res }[ 3 ],  0  , qq{round(  0  , 1 ) =>  0  } );
    equal( ${ $res }[ 4 ],  0.4, qq{round(  0.4, 1 ) =>  0.4} );
    equal( ${ $res }[ 5 ],  0.5, qq{round(  0.5, 1 ) =>  0.5} );
    equal( ${ $res }[ 6 ],  1  , qq{round(  1  , 1 ) =>  1  } );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{roundup( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 7, qq{7回の一括処理} );
    equal( ${ $res }[ 0 ], -1  , qq{roundup( -1  , 1 ) => -1  } );
    equal( ${ $res }[ 1 ], -0.5, qq{roundup( -0.5, 1 ) => -0.5} );
    equal( ${ $res }[ 2 ], -0.4, qq{roundup( -0.4, 1 ) => -0.4} );
    equal( ${ $res }[ 3 ],  0  , qq{roundup(  0  , 1 ) =>  0  } );
    equal( ${ $res }[ 4 ],  0.4, qq{roundup(  0.4, 1 ) =>  0.4} );
    equal( ${ $res }[ 5 ],  0.5, qq{roundup(  0.5, 1 ) =>  0.5} );
    equal( ${ $res }[ 6 ],  1  , qq{roundup(  1  , 1 ) =>  1  } );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rounddown( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 7, qq{7回の一括処理} );
    equal( ${ $res }[ 0 ], -1, qq{rounddown( -1  , 0 ) => -1} );
    equal( ${ $res }[ 1 ],  0, qq{rounddown( -0.5, 0 ) =>  0} );
    equal( ${ $res }[ 2 ],  0, qq{rounddown( -0.4, 0 ) =>  0} );
    equal( ${ $res }[ 3 ],  0, qq{rounddown(  0  , 0 ) =>  0} );
    equal( ${ $res }[ 4 ],  0, qq{rounddown(  0.4, 0 ) =>  0} );
    equal( ${ $res }[ 5 ],  0, qq{rounddown(  0.5, 0 ) =>  0} );
    equal( ${ $res }[ 6 ],  1, qq{rounddown(  1  , 0 ) =>  1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{round( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 7, qq{7回の一括処理} );
    equal( ${ $res }[ 0 ], -1, qq{round( -1  , 0 ) => -1} );
    equal( ${ $res }[ 1 ], -1, qq{round( -0.5, 0 ) => -1} );
    equal( ${ $res }[ 2 ],  0, qq{round( -0.4, 0 ) =>  0} );
    equal( ${ $res }[ 3 ],  0, qq{round(  0  , 0 ) =>  0} );
    equal( ${ $res }[ 4 ],  0, qq{round(  0.4, 0 ) =>  0} );
    equal( ${ $res }[ 5 ],  1, qq{round(  0.5, 0 ) =>  1} );
    equal( ${ $res }[ 6 ],  1, qq{round(  1  , 0 ) =>  1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{roundup( -1, -0.5, -0.4, 0, 0.4, 0.5, 1, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 7, qq{7回の一括処理} );
    equal( ${ $res }[ 0 ], -1, qq{roundup( -1  , 0 ) => -1} );
    equal( ${ $res }[ 1 ], -1, qq{roundup( -0.5, 0 ) => -1} );
    equal( ${ $res }[ 2 ], -1, qq{roundup( -0.4, 0 ) => -1} );
    equal( ${ $res }[ 3 ],  0, qq{roundup(  0  , 0 ) =>  0} );
    equal( ${ $res }[ 4 ],  1, qq{roundup(  0.4, 0 ) =>  1} );
    equal( ${ $res }[ 5 ],  1, qq{roundup(  0.5, 0 ) =>  1} );
    equal( ${ $res }[ 6 ],  1, qq{roundup(  1  , 0 ) =>  1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{percentage( 2, 3 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 66.6666666667, qq{percentage( 2, 3 ) => 66.6666666667} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{percentage( 2, 3, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 66.7, qq{percentage( 2, 3, 1 ) => 66.7} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{percentage( 2, 3, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 67, qq{percentage( 2, 3, 0 ) => 67} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{percentage( 2, 3, -1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 70, qq{percentage( 2, 3, -1 ) => 70} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ratio_scaling( 3, 10, 20 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 66.6666666667, qq{ratio_scaling( 3, 10, 20 ) => 66.6666666667} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ratio_scaling( 3, 10, 20, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 66.7, qq{ratio_scaling( 3, 10, 20, 1 ) => 66.7} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{is_prime( 29 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{29は素数} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{is_prime( 29.1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{小数点付きの数は素数ではない} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{is_prime( -2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{2未満の数は素数ではない} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{is_prime( 2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{2は素数} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{is_prime( 4 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{2以外の偶数は素数ではない} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{is_prime( 0xfffffffb )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{32bitクラスの整数（素数）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{is_prime( 0xfffffffd )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{32bitクラスの整数（非素数）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{is_prime( 1576770817, 1576770818 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{2回の一括処理} );
    equal( ${ $res }[ 0 ], 1, qq{is_prime( 1576770817 ) => 1} );
    equal( ${ $res }[ 1 ], 0, qq{is_prime( 1576770818 ) => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{prime_factorize( 1234567890 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 6, qq{prime_factorize( 1234567890 )} );
    equal( ${ $res }[ 0 ], 2 );
    equal( ${ $res }[ 1 ], 3 );
    equal( ${ $res }[ 2 ], 3 );
    equal( ${ $res }[ 3 ], 5 );
    equal( ${ $res }[ 4 ], 3607 );
    equal( ${ $res }[ 5 ], 3803 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{prime_factorize( 2 ** 32 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 32, qq{prime_factorize( 2 ** 32 )} );
    equal( ${ $res }[ 0 ], 2 );
    equal( ${ $res }[ 1 ], 2 );
    equal( ${ $res }[ 15 ], 2 );
    equal( ${ $res }[ 30 ], 2 );
    equal( ${ $res }[ 31 ], 2 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{prime_factorize( ( 2 ** 32 ) - 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 5, qq{prime_factorize( ( 2 ** 32 ) - 1 )} );
    equal( ${ $res }[ 0 ], 3 );
    equal( ${ $res }[ 1 ], 5 );
    equal( ${ $res }[ 2 ], 17 );
    equal( ${ $res }[ 3 ], 257 );
    equal( ${ $res }[ 4 ], 65537 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{prime_factorize( 2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 2, qq{prime_factorize( 2 ) => 2} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $os_org = $c->_getOutputSel();
    $c->_setOutputSel( FTC_FSC_OUTPUT_RESULT );

    ## 64bit: 3473826439 [ = 0xCF0E6287 ]
    ## 32bit: 2942933887 [ = -1352033409 ] [ = 0xAF699B7F ]
    $expect = qr/^ Result: \d+ \[ = 0x[\dA-F]{1,8} \]$/;
    if( $UV_bit_width == 32 ){
        $expect = qr/^ Result: \d+(?: \[ = \-\d+ \])? \[ = 0x[\dA-F]{1,8} \]$/;
    }
    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{get_prime( 32 )|0} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{\$UV_bit_width="$UV_bit_width"} );
    t_like( $res, qr/^\d+$/ );
    $t->stdout_like( $expect );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{get_prime( 24 )|0} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    t_like( $res, qr/^\d+$/ );
    $t->stdout_like( qr/^ Result: \d+ \[ = 0x[\dA-F]{1,6} \]$/ );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{get_prime( 16 )|0} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    t_like( $res, qr/^\d+$/ );
    $t->stdout_like( qr/^ Result: \d+ \[ = 0x[\dA-F]{1,6} \]$/ );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{get_prime( 4 )|0} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    t_like( $res, qr/^\d+$/ );
    $t->stdout_like( qr/^ Result: \d+ \[ = 0x[\dA-F]{1,6} \]$/ );
    $t->stderr_is( qq{} );

    $c->_setOutputSel( $os_org );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gcd( 0 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{gcd( 0 ) => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gcd( 138 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 138, qq{gcd( 138 ) => 138} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gcd( 2040, 1920, 1080 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 120, qq{gcd( 2040, 1920, 1080 ) => 120} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{lcm( 1920, 1080 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 17280, qq{lcm( 1920, 1080 ) => 17280} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{lcm( 100, 0, 0 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{lcm( 100, 0, 0 ) => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ncr( 1.0, 2.0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{ncr( 1.0, 2.0 ) => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ncr( 7.0, 2.0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 21, qq{ncr( 7.0, 2.0 ) => 21} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{min( 5 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 5, qq{min( 5 ) => 5} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{max( 5 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 5, qq{max( 5 ) => 5} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{min( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{min( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) => 1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{max( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 9, qq{max( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) => 9} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{min( 5, 4, 3, min( 5, 4, 3, 1, 2, 9, 8, 7, 6 ), 2, 9, 8, 7, 6 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{min( 5, 4, 3, min( 5, 4, 3, 1, 2, 9, 8, 7, 6 ), 2, 9, 8, 7, 6 ) => 1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{max( 5, 4, 3, max( 5, 4, 3, 1, 2, 9, 8, 7, 6 ), 2, 9, 8, 7, 6 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 9, qq{max( 5, 4, 3, max( 5, 4, 3, 1, 2, 9, 8, 7, 6 ), 2, 9, 8, 7, 6 ) => 9} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{shuffle( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 9 );
    ok( !( ( ( ${ $res }[ 0 ] + ${ $res }[ 1 ] ) == 9 ) &&
           ( ( ${ $res }[ 2 ] + ${ $res }[ 3 ] ) == 4 ) &&
           ( ( ${ $res }[ 5 ] + ${ $res }[ 6 ] ) == 17 ) &&
           ( ( ${ $res }[ 7 ] + ${ $res }[ 8 ] ) == 13 ) ) );
    equal( $$res[ 0 ] + $$res[ 1 ] + $$res[ 2 ] + $$res[ 3 ] + $$res[ 4 ] + $$res[ 5 ] + $$res[ 6 ] + $$res[ 7 ] + $$res[ 8 ], 45 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{min( shuffle( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1, qq{min( shuffle( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) ) => 1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{uniq( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 9 );
    equal( ${ $res }[ 0 ], 5 );
    equal( ${ $res }[ 1 ], 4 );
    equal( ${ $res }[ 2 ], 3 );
    equal( ${ $res }[ 3 ], 1 );
    equal( ${ $res }[ 4 ], 2 );
    equal( ${ $res }[ 5 ], 9 );
    equal( ${ $res }[ 6 ], 8 );
    equal( ${ $res }[ 7 ], 7 );
    equal( ${ $res }[ 8 ], 6 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{uniq( 5, 4, 3, 1, 2, 1, 3, 4, 5, 9, 8, 7, 6 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 9 );
    equal( ${ $res }[ 0 ], 5 );
    equal( ${ $res }[ 1 ], 4 );
    equal( ${ $res }[ 2 ], 3 );
    equal( ${ $res }[ 3 ], 1 );
    equal( ${ $res }[ 4 ], 2 );
    equal( ${ $res }[ 5 ], 9 );
    equal( ${ $res }[ 6 ], 8 );
    equal( ${ $res }[ 7 ], 7 );
    equal( ${ $res }[ 8 ], 6 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{max( uniq( 5, 4, 3, 1, 2, 1, 3, 4, 5, 9, 8, 7, 6 ) ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 9, qq{max( uniq( 5, 4, 3, 1, 2, 1, 3, 4, 5, 9, 8, 7, 6 ) ) => 9} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{first( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 5, qq{first( 5, 4, 3, 1, 2, 9, 8, 7, 6 ) => 5} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{slice( 2025, 12, 16, 0, 3 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{年月日} );
    equal( ${ $res }[ 0 ], 2025 );
    equal( ${ $res }[ 1 ], 12 );
    equal( ${ $res }[ 2 ], 16 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{slice( 2025, 12, 16, -1, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 16, qq{slice( 2025, 12, 16, -1, 1 ) => 16} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{sum( 1, 2, 3, 4, 5, 6, 7, 8, 9 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 45, qq{sum( 1, 2, 3, 4, 5, 6, 7, 8, 9 ) => 45} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{sum( 0.1, 2.3, 4.5, 6.7, 8.9 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 22.5, qq{sum( 0.1, 2.3, 4.5, 6.7, 8.9 ) => 22.5} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{prod( linstep( 1, 1, 10 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 3628800, qq{prod( linstep( 1, 1, 10 ) ) => 3628800} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{prod( linstep( 0, 1, 10 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{prod( linstep( 0, 1, 10 ) ) => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{prod( linstep( -1, 2, 6 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -945, qq{prod( linstep( -1, 2, 6 ) ) => -945} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{avg( 1, 2, 3, 4, 5, 6, 7, 8, 9 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 5, qq{avg( 1, 2, 3, 4, 5, 6, 7, 8, 9 ) => 5} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{avg( 0.1, 2.3, 4.5, 6.7, 8.9 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 4.5, qq{avg( 0.1, 2.3, 4.5, 6.7, 8.9 ) => 4.5} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{add_each( 100, 200, -10 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{add_each( 100, 200, -10 )} );
    equal( ${ $res }[ 0 ],  90, qq{100 + -10} );
    equal( ${ $res }[ 1 ], 190, qq{200 + -10} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{mul_each( 210, 297, ( 1 / 25.4 ) * 300 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{mul_each( 210, 297, ( 1 / 25.4 ) * 300 )} );
    equal( ${ $res }[ 0 ], 2480.31496063, qq{210 * ( ( 1 / 25.4 ) * 300 )} );
    equal( ${ $res }[ 1 ], 3507.87401575, qq{297 * ( ( 1 / 25.4 ) * 300 )} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{linspace( 4, 10, 3 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{linspace( 4, 10, 3 )} );
    equal( ${ $res }[ 0 ],  4 );
    equal( ${ $res }[ 1 ],  7 );
    equal( ${ $res }[ 2 ], 10 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{linspace( -10, 10, 5 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 5, qq{linspace( -10, 10, 5 )} );
    equal( ${ $res }[ 0 ], -10 );
    equal( ${ $res }[ 1 ],  -5 );
    equal( ${ $res }[ 2 ],   0 );
    equal( ${ $res }[ 3 ],   5 );
    equal( ${ $res }[ 4 ],  10 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{linspace( 10, -10, 5 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 5, qq{linspace( 10, -10, 5 )} );
    equal( ${ $res }[ 0 ],  10 );
    equal( ${ $res }[ 1 ],   5 );
    equal( ${ $res }[ 2 ],   0 );
    equal( ${ $res }[ 3 ],  -5 );
    equal( ${ $res }[ 4 ], -10 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{linspace( -10, 10, 9 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 9, qq{linspace( -10, 10, 9 )} );
    equal( ${ $res }[ 0 ], -10   );
    equal( ${ $res }[ 1 ],  -7.5 );
    equal( ${ $res }[ 2 ],  -5   );
    equal( ${ $res }[ 3 ],  -2.5 );
    equal( ${ $res }[ 4 ],   0   );
    equal( ${ $res }[ 5 ],   2.5 );
    equal( ${ $res }[ 6 ],   5   );
    equal( ${ $res }[ 7 ],   7.5 );
    equal( ${ $res }[ 8 ],  10   );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{linspace( -10, 10, 9, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 9, qq{linspace( -10, 10, 9, 0 )} );
    equal( ${ $res }[ 0 ], -10 );
    equal( ${ $res }[ 1 ],  -8 );
    equal( ${ $res }[ 2 ],  -5 );
    equal( ${ $res }[ 3 ],  -3 );
    equal( ${ $res }[ 4 ],   0 );
    equal( ${ $res }[ 5 ],   3 );
    equal( ${ $res }[ 6 ],   5 );
    equal( ${ $res }[ 7 ],   8 );
    equal( ${ $res }[ 8 ],  10 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{linspace( 0x64, 0xff, 5 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 5, qq{linspace( 0x64, 0xff, 5 )} );
    equal( ${ $res }[ 0 ], 100 );
    equal( ${ $res }[ 1 ], 138.75 );
    equal( ${ $res }[ 2 ], 177.5  );
    equal( ${ $res }[ 3 ], 216.25 );
    equal( ${ $res }[ 4 ], 255 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{linstep( 4, 10, 3 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{linstep( 4, 10, 3 )} );
    equal( ${ $res }[ 0 ],  4 );
    equal( ${ $res }[ 1 ], 14 );
    equal( ${ $res }[ 2 ], 24 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{linstep( 4, -10, 3 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{linstep( 4, -10, 3 )} );
    equal( ${ $res }[ 0 ],   4 );
    equal( ${ $res }[ 1 ],  -6 );
    equal( ${ $res }[ 2 ], -16 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{linstep( 4, -10, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 4, qq{linstep( 4, -10, 1 ) => 4} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{linstep( -1.1, -1 sqrt( 2 ), 3 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 3, qq{linstep( -1.1, -1 sqrt( 2 ), 3 )} );
    equal( ${ $res }[ 0 ], -1.1 );
    equal( ${ $res }[ 1 ], -2.51421356237 );
    equal( ${ $res }[ 2 ], -3.92842712475 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{mul_growth( 0, 1, 10 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 10, qq{mul_growth( 0, 1, 10 )} );
    equal( ${ $res }[ 0 ], 0 );
    equal( ${ $res }[ 9 ], 0 );
    equal( $c->formula( qq{sum( } . join( ', ', @$res ) . qq{ )} ), 0, qq{全てゼロ} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{mul_growth( -100, 0, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -100, qq{mul_growth( -100, 0, 1 ) => -100} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{mul_growth( 100, 0.5, 2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{mul_growth( 100, 0.5, 2 )} );
    equal( ${ $res }[ 0 ], 100 );
    equal( ${ $res }[ 1 ],  50 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{mul_growth( 4, 2, 5 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 5, qq{mul_growth( 4, 2, 5 )} );
    equal( ${ $res }[ 0 ],  4 );
    equal( ${ $res }[ 1 ],  8 );
    equal( ${ $res }[ 2 ], 16 );
    equal( ${ $res }[ 3 ], 32 );
    equal( ${ $res }[ 4 ], 64 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gen_fibo_seq( 0, 1, 10 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 10, qq{gen_fibo_seq( 0, 1, 10 )} );
    equal( ${ $res }[ 0 ],  0 );
    equal( ${ $res }[ 1 ],  1 );
    equal( ${ $res }[ 2 ],  1 );
    equal( ${ $res }[ 3 ],  2 );
    equal( ${ $res }[ 4 ],  3 );
    equal( ${ $res }[ 5 ],  5 );
    equal( ${ $res }[ 6 ],  8 );
    equal( ${ $res }[ 7 ], 13 );
    equal( ${ $res }[ 8 ], 21 );
    equal( ${ $res }[ 9 ], 34 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gen_fibo_seq( 2, 1, 10 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 10, qq{gen_fibo_seq( 2, 1, 10 )} );
    equal( ${ $res }[ 0 ],  2 );
    equal( ${ $res }[ 1 ],  1 );
    equal( ${ $res }[ 2 ],  3 );
    equal( ${ $res }[ 3 ],  4 );
    equal( ${ $res }[ 4 ],  7 );
    equal( ${ $res }[ 5 ], 11 );
    equal( ${ $res }[ 6 ], 18 );
    equal( ${ $res }[ 7 ], 29 );
    equal( ${ $res }[ 8 ], 47 );
    equal( ${ $res }[ 9 ], 76 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gen_fibo_seq( -2, 5, 10 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 10, qq{gen_fibo_seq( -2, 5, 10 )} );
    equal( ${ $res }[ 0 ],  -2 );
    equal( ${ $res }[ 1 ],   5 );
    equal( ${ $res }[ 2 ],   3 );
    equal( ${ $res }[ 3 ],   8 );
    equal( ${ $res }[ 4 ],  11 );
    equal( ${ $res }[ 5 ],  19 );
    equal( ${ $res }[ 6 ],  30 );
    equal( ${ $res }[ 7 ],  49 );
    equal( ${ $res }[ 8 ],  79 );
    equal( ${ $res }[ 9 ], 128 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gen_fibo_seq( -100, 100, 2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{gen_fibo_seq( -100, 100, 2 )} );
    equal( ${ $res }[ 0 ], -100 );
    equal( ${ $res }[ 1 ],  100 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gen_fibo_seq( -5.4, 3.2, 10 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 10, qq{gen_fibo_seq( -5.4, 3.2, 10 )} );
    equal( ${ $res }[ 0 ], -5.4 );
    equal( ${ $res }[ 1 ],  3.2 );
    equal( ${ $res }[ 2 ], -2.2 );
    equal( ${ $res }[ 3 ],  1   );
    equal( ${ $res }[ 4 ], -1.2 );
    equal( ${ $res }[ 5 ], -0.2 );
    equal( ${ $res }[ 6 ], -1.4 );
    equal( ${ $res }[ 7 ], -1.6 );
    equal( ${ $res }[ 8 ], -3   );
    equal( ${ $res }[ 9 ], -4.6 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{paper_size( 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{paper_size( 0 )} );
    equal( ${ $res }[ 0 ],  841 );
    equal( ${ $res }[ 1 ], 1189 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{paper_size( 4 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{paper_size( 4 )} );
    equal( ${ $res }[ 0 ], 210 );
    equal( ${ $res }[ 1 ], 297 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{paper_size( 19, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{paper_size( 19, 0 )} );
    equal( ${ $res }[ 0 ], 1 );
    equal( ${ $res }[ 1 ], 1 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{paper_size( 0, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{paper_size( 0, 1 )} );
    equal( ${ $res }[ 0 ], 1030 );
    equal( ${ $res }[ 1 ], 1456 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{paper_size( 4, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{paper_size( 4, 1 )} );
    equal( ${ $res }[ 0 ], 257 );
    equal( ${ $res }[ 1 ], 364 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rand(-10)} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    t_like( $res, qr/^\-\d\./ );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rand(0)} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    t_like( $res, qr/^\d\./ );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rand(10)} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    t_like( $res, qr/^\d\./ );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{int( rand( 2 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    t_like( $res, qr/^[01]$/ );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{()=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{() => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{( 1 + 2 + 3, 4 ) =} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 2, qq{( 1 + 2 + 3, 4 )} );
    equal( ${ $res }[ 0 ], 6 );
    equal( ${ $res }[ 1 ], 4 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{1+(2+(3+(4+(5+(6+((7+8*9)))))))=} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 100, qq{1+(2+(3+(4+(5+(6+((7+8*9))))))) => 100} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );



    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{12345678901 + 0.1234} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 12345678901.1, qq{12345678901 + 0.1234 => 12345678901.1} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{123456789012 + 0.1234} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 123456789012, qq{123456789012 + 0.1234 => 123456789012} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{1234567890123 + 0.1234} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1234567890123, qq{1234567890123 + 0.1234 => 1234567890123} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{-0.1234567890123} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, -0.123456789012, qq{-0.1234567890123 => -0.123456789012} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

};

subtest qq{Normal (Ex-Proc Test)} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{echo | ./c} );
    $t->exit_is( 0, qq{echo | ./c} );
    $t->stdout_is( qq{\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    my $expect;

    $t = tests::Tester->run_cmd( qq{./c '2' '~1='} );
    $t->exit_is( 0, qq{./c '2' '~1='} );
    $expect = qq{36893488147419103232 \[ = -1 \] \[ = 0xFFFFFFFFFFFFFFFF \]\n};
    if( $UV_bit_width == 32 ){
        $expect = qq{8589934588 \[ = -1 \] \[ = 0xFFFFFFFF \]\n};
    }
    $t->stdout_is( $expect );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '0xfc & 0x10  ~0x1 | 0x8 =' -v} );
    $t->exit_is( 0, qq{./c '0xfc & 0x10  ~0x1 | 0x8 =' -v} );
    $t->stdout_like( qr/\n    RPN: '252 16 1 ~ \* & 8 \|'\n/ );
    $t->stdout_like( qr/\n Result: 252 \[ = 0xFC \]\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 123,456-59 + '123.456((3-2)*1+1+(1-3/3))='} );
    $t->exit_is( 0, qq{./c 123,456-59 + '123.456((3-2)*1+1+(1-3/3))='} );
    $t->stdout_is( qq{123643.912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'dist_between_points( -50, -50, -50, 50, 50 )='} );
    $t->exit_isnt( 0, qq{./c 'dist_between_points( -50, -50, -50, 50, 50 )='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: dist_between_points: \$argc=5: Invalid number of arguments\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'midpt_between_points( -50, -50, -50, 50, 50 )='} );
    $t->exit_isnt( 0, qq{./c 'midpt_between_points( -50, -50, -50, 50, 50 )='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: midpt_between_points: \$argc=5: Invalid number of arguments\.\n/ );
    undef( $t );


    $t = tests::Tester->run_cmd( qq{./c 'sqrt(power(2, 100)+power(2, 100))='} );
    $t->exit_is( 0, qq{./c 'sqrt(power(2, 100)+power(2, 100))='} );
    $t->stdout_is( qq{1592262918131443.25\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );


    $t = tests::Tester->run_cmd( qq{./c '0.22*10**(-6)='} );
    $t->exit_is( 0, qq{./c '0.22*10**(-6)='} );
    $t->stdout_is( qq{0.00000022\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );


    $t = tests::Tester->run_cmd( qq{./c '１' 'cos(deg2rad(45))'} );
    $t->exit_is( 0, qq{./c '１' 'cos(deg2rad(45))'} );
    $t->stdout_is( qq{0.707106781187\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'dms2rad( $dms_Galapagos_Iss_Lon, -90, -25 )'} );
    $t->exit_isnt( 0, qq{./c 'dms2rad( $dms_Galapagos_Iss_Lon, -90, -25 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: dms2rad: \$arg_counter="5": Not a multiple of 3\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'dms2rad( -90, -25 )'} );
    $t->exit_isnt( 0, qq{./c 'dms2rad( -90, -25 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: "dms2rad": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '1 + ( 2 + ( 3 + dms2rad( -90, -25 ) ) )'} );
    $t->exit_isnt( 0, qq{./c '1 + ( 2 + ( 3 + dms2rad( -90, -25 ) ) )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: dms2rad: \$arg_counter="2": Not a multiple of 3\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'geo_all_km( 10, 10, -10, -10 )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( 10, 10, -10, -10 )'} );
    $t->stdout_is( qq{( 10045.2740731, 309.826898594, 10058.0659261, 316.502246503 )\n}, qq{引数（座標）の正規化} );
    $t->stderr_like( qr/^Coordinates out of range: /, qq{警告メッセージ} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'geo_all_km( 1, 4, 2, -100 )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( 1, 4, 2, -100 )'} );
    $t->stdout_is( qq{( 1341.45302198, 319.995434444, 1346.08951591, 312.190223662 )\n}, qq{引数（座標）の正規化} );
    $t->stderr_like( qr/^Coordinates out of range: /, qq{警告メッセージ} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'geo_all_km( 100, 100, -100, -100 )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( 100, 100, -100, -100 )'} );
    $t->stdout_is( qq{( 9315.0650115, 49.4032576339, 9323.62154307, 43.7610906052 )\n}, qq{引数（座標）の正規化} );
    $t->stderr_like( qr/^Coordinates out of range: /, qq{警告メッセージ} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'geo_all_km( 1, -4, 1, 4 )'} );
    $t->exit_is( 0, qq{./c 'geo_all_km( 1, -4, 1, 4 )'} );
    $t->stdout_is( qq{( 5386.30789906, 45.7429575198, 5930.42524018, 90 )\n}, qq{( P  A B  dec ) = ( 1  0 1  0 )} );
    $t->stderr_like( qr/^Coordinates out of range: /, qq{警告メッセージ} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo '' | ./c 'laptimer( 1 )'} );
    $t->exit_is( 0, qq{echo '' | ./c 'laptimer( 1 )'} );
    $t->stdout_like( qr/^Elaps         Date\-Time\n/ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{printf "\n\n" | ./c 'laptimer( 2 )'} );
    $t->exit_is( 0, qq{printf "\n\n" | ./c 'laptimer( 2 )'} );
    $t->stdout_like( qr/^Lap  Split\-Time    Lap\-Time      Date\-Time\n/ );
    $t->stdout_like( qr/\r2\/2  00:00:00\./ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{printf "\nq\n" | ./c 'laptimer( 10 )'} );
    $t->exit_is( 0, qq{printf "\nq\n" | ./c 'laptimer( 10 )'} );
    $t->stdout_like( qr/^Lap    Split\-Time    Lap\-Time      Date\-Time\n/ );
    $t->stdout_like( qr/\r 2\/10  00:00:00\./ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{printf "\n\n\nq\n" | ./c 'laptimer( 10 )' --test-test-test} );
    $t->exit_is( 0, qq{printf "\n\n\nq\n" | ./c 'laptimer( 10 )' --test-test-test} );
    $t->stdout_like( qr/^Lap    Split\-Time    Lap\-Time      Date\-Time\n/ );
    $t->stdout_like( qr/\r 4\/10  00:00:00\./ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_like( qr/^c: warn: \d+: sysread\(\): /, qq{sysread()のエラー処理部分} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo '' | ./c 'timer( local2epoch( 2025, 1, 1  ) )'} );
    $t->exit_is( 0, qq{echo '' | ./c 'timer( local2epoch( 2025, 1, 1  ) )'} );
    $t->stdout_like( qr/^2025\-01\-01 00:00:00\.000  TARGET\n/ );
    $t->stdout_like( qr/\n\d+\.\d+\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo '' | ./c 'timer( 3 )'} );
    $t->exit_is( 0, qq{echo '' | ./c 'timer( 3 )'} );
    $t->stdout_like( qr/^20\d{2}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}  TARGET\n/ );
    $t->stdout_like( qr/\n\-\d+\.\d+\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'timer( 1 )'} );
    $t->exit_is( 0, qq{./c 'timer( 1 )'} );
    $t->stdout_like( qr/^20\d{2}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}  TARGET\n/ );
    $t->stdout_like( qr/\n\d+\.\d+\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo '' | ./c 'stopwatch()'} );
    $t->exit_is( 0, qq{echo '' | ./c 'stopwatch()'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo '' | ./c 'bpm( 10, stopwatch() )'} );
    $t->exit_is( 0, qq{echo '' | ./c 'bpm( 10, stopwatch() )'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo '' | ./c 'bpm15()'} );
    $t->exit_is( 0, qq{echo '' | ./c 'bpm15()'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo '' | ./c 'bpm30()'} );
    $t->exit_is( 0, qq{echo '' | ./c 'bpm30()'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo '' | ./c 'tachymeter( stopwatch() )'} );
    $t->exit_is( 0, qq{echo '' | ./c 'tachymeter( stopwatch() )'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo '' | ./c 'telemeter( stopwatch() )'} );
    $t->exit_is( 0, qq{echo '' | ./c 'telemeter( stopwatch() )'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n\d+(?:\.\d+)?$/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'log( -123.456 ) ='} );
    $t->exit_isnt( 0, qq{./c 'log( -123.456 ) ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: log\( -123.456 \): Must be a positive number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'log(0)/log(2)='} );
    $t->exit_isnt( 0, qq{./c 'log(0)/log(2)='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: log\( 0 \): Must be a positive number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'log2( -123.456 ) ='} );
    $t->exit_isnt( 0, qq{./c 'log2( -123.456 ) ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: log2\( -123.456 \): Must be a positive number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'log2(0)='} );
    $t->exit_isnt( 0, qq{./c 'log2(0)='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: log2\( 0 \): Must be a positive number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'log10( -123.456 ) ='} );
    $t->exit_isnt( 0, qq{./c 'log10( -123.456 ) ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: log10\( -123.456 \): Must be a positive number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'log10(0)='} );
    $t->exit_isnt( 0, qq{./c 'log10(0)='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: log10\( 0 \): Must be a positive number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c ' ' '2PI10='} );
    $t->exit_is( 0, qq{./c ' ' '2PI10='} );
    $t->stdout_is( qq{62.8318530718\n} );  ## 62.83185307179586476925286766559
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '2PI10=' ' '} );
    $t->exit_is( 0, qq{./c '2PI10=' ' '} );
    $t->stdout_is( qq{62.8318530718\n} );  ## 62.83185307179586476925286766559
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '2PI10=' ' ' -d} );
    $t->exit_is( 0, qq{./c '2PI10=' ' ' -d} );
    $t->stdout_like( qr/\n Result: 62\.8318530718\n$/ );  ## 62.83185307179586476925286766559
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c ')(='} );
    $t->exit_isnt( 0, qq{./c ')(='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: parser: error: "BEGIN", "\)": Wrong combination\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '123' '2(='} );
    $t->exit_isnt( 0, qq{./c '123' '2(='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: parser: error: The position of the "\)" is incorrect\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '123' '2(2='} );
    $t->exit_isnt( 0, qq{./c '123' '2(2='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: parser: error: The position of the "\)" is incorrect\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '5/0='} );
    $t->exit_isnt( 0, qq{./c '5/0='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: "5 \/ 0": Illegal division by zero\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '5%0='} );
    $t->exit_isnt( 0, qq{./c '5%0='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: Division by zero: Illegal modulus operand\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'testfunc(10)='} );
    $t->exit_isnt( 0, qq{./c 'testfunc(10)='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_is( qq{c: parser: error: "testfunc": There is a problem with the calculation formula.\n} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'unknownfunc(10)='} );
    $t->exit_isnt( 0, qq{./c 'unknownfunc(10)='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: lexer: error: "unknownfunc\(\)": unknown function\.\n/ );
    $t->stderr_like( qr/\nc: lexer: info: Supported functions: / );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'rad2deg(atan2(100, 200='} );
    $t->exit_is( 0, qq{./c 'rad2deg(atan2(100, 200='} );
    $t->stdout_is( qq{26.5650511771\n} );
    $t->stderr_like( qr/^c: parser: warn: "atan2\(": "\)" may be incorrect\.\n/ );
    $t->stderr_like( qr/\nc: parser: warn: "rad2deg\(": "\)" may be incorrect\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'rad2deg(atan2(100, 200)='} );
    $t->exit_is( 0, qq{./c 'rad2deg(atan2(100, 200)='} );
    $t->stdout_is( qq{26.5650511771\n} );
    $t->stderr_unlike( qr/^c: parser: warn: "atan2\(": "\)" may be incorrect\.\n/ );
    $t->stderr_like( qr/^c: parser: warn: "rad2deg\(": "\)" may be incorrect\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'math_mod( 120, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'math_mod( 120, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: Division by zero: Illegal modulus operand\.\n/, qq{error message} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'math_mod( -120, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'math_mod( -120, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: Division by zero: Illegal modulus operand\.\n/, qq{error message} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'rounddown( 192.168 ) ='} );
    $t->exit_isnt( 0, qq{./c 'rounddown( 192.168 ) ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: rounddown\(\): \$argc=1: Insufficient arguments\.\n/, qq{Insufficient arguments.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'round( 192.168 ) ='} );
    $t->exit_isnt( 0, qq{./c 'round( 192.168 ) ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: round\(\): \$argc=1: Insufficient arguments\.\n/, qq{Insufficient arguments.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'roundup( 192.168 ) ='} );
    $t->exit_isnt( 0, qq{./c 'roundup( 192.168 ) ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: roundup\(\): \$argc=1: Insufficient arguments\.\n/, qq{Insufficient arguments.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'percentage( 2 )'} );
    $t->exit_isnt( 0, qq{./c 'percentage( 2 )'} );
    $t->stdout_is( qq{} );
    $t->stderr_like( qr/^c: evaluator: error: "percentage": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'percentage()'} );
    $t->exit_isnt( 0, qq{./c 'percentage()'} );
    $t->stdout_is( qq{} );
    $t->stderr_like( qr/^c: evaluator: error: "percentage": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'percentage( 2, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'percentage( 2, 0 )'} );
    $t->stdout_is( qq{} );
    $t->stderr_like( qr/^c: evaluator: error: Illegal division by zero.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'ratio_scaling( 0, 10, 20 )'} );
    $t->exit_isnt( 0, qq{./c 'ratio_scaling( 0, 10, 20 )'} );
    $t->stdout_is( qq{} );
    $t->stderr_like( qr/^c: evaluator: error: Illegal division by zero.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'prime_factorize( -10 )'} );
    $t->exit_isnt( 0, qq{./c 'prime_factorize( -10 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: prime_factorize: \-10: Cannot be less than 2\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'prime_factorize( 2.345 )'} );
    $t->exit_isnt( 0, qq{./c 'prime_factorize( 2.345 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: prime_factorize: 2\.345: Decimals cannot be specified\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'get_prime( 32.1 )'} );
    $t->exit_isnt( 0, qq{./c 'get_prime( 32.1 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: get_prime: 32\.1: Decimals cannot be specified\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'get_prime( 64 )'} );
    $t->exit_isnt( 0, qq{./c 'get_prime( 64 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: get_prime: 64: Cannot specify a value greater than 32\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'get_prime( 3 )'} );
    $t->exit_isnt( 0, qq{./c 'get_prime( 3 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: get_prime: 3: Cannot specify a value less than 4\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'ncr( -1.0, 2.0 )'} );
    $t->exit_isnt( 0, qq{./c 'ncr( -1.0, 2.0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: nCr\( \-1, 2 \): N\[=\-1\] must be a non-negative integer\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'ncr( 1.1, 2.0 )'} );
    $t->exit_isnt( 0, qq{./c 'ncr( 1.1, 2.0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: nCr\( 1\.1, 2 \): N\[=1\.1\] must be a non-negative integer\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'ncr( 1.0, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'ncr( 1.0, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: nCr\( 1, 0 \): R\[=0\] must be a positive integer\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'ncr( 1.0, 2.1 )'} );
    $t->exit_isnt( 0, qq{./c 'ncr( 1.0, 2.1 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: nCr\( 1, 2\.1 \): R\[=2\.1\] must be a positive integer\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'min() ='} );
    $t->exit_isnt( 0, qq{./c 'min() ='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: "min": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'slice( 2025, 12 )'} );
    $t->exit_isnt( 0, qq{./c 'slice( 2025, 12 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: slice: \$argc=2: Not enough arguments\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'slice( 2025, 12, 16, 1.2, 1.3 )'} );
    $t->exit_isnt( 0, qq{./c 'slice( 2025, 12, 16, 1.2, 1.3 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: slice: \$offset=1\.2: \$offset cannot be a decimal number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'slice( 2025, 12, 16, -1.2, 1.3 )'} );
    $t->exit_isnt( 0, qq{./c 'slice( 2025, 12, 16, -1.2, 1.3 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: slice: \$offset=\-1\.2: \$offset cannot be a decimal number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'slice( 2025, 12, 16, 1, 1.3 )'} );
    $t->exit_isnt( 0, qq{./c 'slice( 2025, 12, 16, 1, 1.3 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: slice: \$length=1\.3: \$length cannot be a decimal number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'slice( 2025, 12, 16, 3, 1 )'} );
    $t->exit_isnt( 0, qq{./c 'slice( 2025, 12, 16, 3, 1 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: slice: \$offset=3, \$argc=3: \$offset is large\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'slice( 2025, 12, 16, 0, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'slice( 2025, 12, 16, 0, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: slice: \$length=0: \$length must be greater than 0\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'slice( 2025, 12, 16, 0, 4 )'} );
    $t->exit_is( 0, qq{./c 'slice( 2025, 12, 16, 0, 4 )'} );
    $t->stdout_is( qq{( 2025, 12, 16 )\n} );
    $t->stderr_like( qr/^c: tbl_prvdr: warn: \$length=4: Decrease the value of \$length\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'slice( 2025, 12, 16, -2, 3 )'} );
    $t->exit_is( 0, qq{./c 'slice( 2025, 12, 16, -2, 3 )'} );
    $t->stdout_is( qq{( 12, 16 )\n} );
    $t->stderr_like( qr/^c: tbl_prvdr: warn: \$length=3: Decrease the value of \$length\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'add_each( -10 )'} );
    $t->exit_isnt( 0, qq{./c 'add_each( -10 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: add_each\(\): \$argc=1: Insufficient number of arguments\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'mul_each( ( 1 / 25.4 ) * 300 )'} );
    $t->exit_isnt( 0, qq{./c 'mul_each( ( 1 / 25.4 ) * 300 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: mul_each\(\): \$argc=1: Insufficient number of arguments\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'linspace( -10, 10 )'} );
    $t->exit_isnt( 0, qq{./c 'linspace( -10, 10 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: "linspace": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'linspace( -10, 10, 3, 1, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'linspace( -10, 10, 3, 1, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linspace: \$arg_counter="5": The number of operands is incorrect\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'linspace( -10, 10, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'linspace( -10, 10, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linspace\(\): \$length\[=0\] is less than 2\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'linspace( -10, 10, 1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'linspace( -10, 10, 1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linspace\(\): \$length\[=1\.2\] is less than 2\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'linspace( -10, 10, 2.1 )'} );
    $t->exit_isnt( 0, qq{./c 'linspace( -10, 10, 2.1 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linspace\(\): \$length\[=2\.1\] is a decimal number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'linstep( 4, -10, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'linstep( 4, -10, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linstep\(\): \$length\[=0\] is less than 1\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'linstep( 4, 10, -1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'linstep( 4, 10, -1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linstep\(\): \$length\[=\-1\.2\] is less than 1\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'linstep( 4, 10, 1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'linstep( 4, 10, 1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: linstep\(\): \$length\[=1\.2\] is a decimal number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'mul_growth( 1, 1, -1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'mul_growth( 1, 1, -1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: mul_growth\(\): \$length\[=\-1\.2\] is less than 1\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'mul_growth( 1, 1, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'mul_growth( 1, 1, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: mul_growth\(\): \$length\[=0\] is less than 1\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'mul_growth( 1, 1, 1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'mul_growth( 1, 1, 1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: mul_growth\(\): \$length\[=1\.2\] is a decimal number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'gen_fibo_seq( 2, 1, 0 )'} );
    $t->exit_isnt( 0, qq{./c 'gen_fibo_seq( 2, 1, 0 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: gen_fibo_seq\(\): \$length\[=0\] is less than 2\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'gen_fibo_seq( 2, 1, -1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'gen_fibo_seq( 2, 1, -1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: gen_fibo_seq\(\): \$length\[=\-1\.2\] is less than 2\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'gen_fibo_seq( 2, 1, 2.1 )'} );
    $t->exit_isnt( 0, qq{./c 'gen_fibo_seq( 2, 1, 2.1 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: gen_fibo_seq\(\): \$length\[=2\.1\] is a decimal number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'paper_size( -1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'paper_size( -1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: paper_size\(\): \$size\[=\-1\.2\] is negative\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'paper_size( 1.2 )'} );
    $t->exit_isnt( 0, qq{./c 'paper_size( 1.2 )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: paper_size\(\): \$size\[=1\.2\] is a decimal number\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'paper_size( 20, 0 )'} );
    $t->exit_is( 0, qq{./c 'paper_size( 20, 0 )'} );
    $t->stdout_is( qq{( 0, 1 )\n} );
    $t->stderr_is( qq{paper_size(): A20: The short side reaches 0 mm.\n} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'paper_size( 100, 0 )'} );
    $t->exit_is( 0, qq{./c 'paper_size( 100, 0 )'} );
    $t->stdout_is( qq{( 0, 0 )\n} );
    $t->stderr_is( qq{paper_size(): A20: The short side reaches 0 mm.\npaper_size(): A21: The long side reaches 0 mm.\n} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'paper_size( 100, 1 )'} );
    $t->exit_is( 0, qq{./c 'paper_size( 100, 1 )'} );
    $t->stdout_is( qq{( 0, 0 )\n} );
    $t->stderr_is( qq{paper_size(): B21: The short side reaches 0 mm.\npaper_size(): B22: The long side reaches 0 mm.\n} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'min( rand( 10 ), rand( 10 ), rand( 10 ), rand( 10 ), rand( 10 ) )' -v} );
    $t->exit_is( 0, qq{./c 'min( rand( 10 ), rand( 10 ), rand( 10 ), rand( 10 ), rand( 10 ) )' -v} );
    $t->stdout_like( qr/\n    RPN: '# # 10 rand # 10 rand # 10 rand # 10 rand # 10 rand min'\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '***='} );
    $t->exit_isnt( 0, qq{./c '***='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: "\*\*": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '1+2*3+='} );
    $t->exit_isnt( 0, qq{./c '1+2*3+='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: "\+": Operand missing\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '1_2='} );
    $t->exit_isnt( 0, qq{./c '1_2='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: lexer: error: "_2=": Could not interpret\.\n/ );
    $t->stderr_like( qr/\nc: lexer: info: Supported operators: / );
    $t->stderr_like( qr/\nc: lexer: info: Supported functions: / );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'sqrt(#)='} );
    $t->exit_isnt( 0, qq{./c 'sqrt(#)='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: lexer: error: "#\)=": Could not interpret\.\n/ );
    $t->stderr_like( qr/\nc: lexer: info: Supported operators: / );
    $t->stderr_like( qr/\nc: lexer: info: Supported functions: / );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '123' '+2=' -v} );
    $t->exit_is( 0, qq{./c '123' '+2=' -v} );
    $t->stdout_like( qr/123 \+ 2 = 125\n/ );
    $t->stdout_like( qr/\n Result: 125\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '123' '2=' -v} );
    $t->exit_is( 0, qq{./c '123' '2=' -v} );
    $t->stdout_like( qr/^123 \* 2 = 246\n/ );
    $t->stdout_like( qr/\n Result: 246\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'sqrt(4)=' =r} );
    $t->exit_isnt( 0, qq{./c 'sqrt(4)=' =r} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_is( qq{c: engine: warn: "=r": Ignore. The calculation process has been completed.\n} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'sqrt(power(2, 100)+power(2,100))='} );
    $t->exit_isnt( 0, qq{./c 'sqrt(power(2, 100)+power(2,100))='} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: pow: \$arg_counter="1": The number of operands is incorrect\.\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'sqrt(-1)'} );
    $t->exit_isnt( 0, qq{./c 'sqrt(-1)'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: evaluator: error: Can't take sqrt of \-1\.\n/ );
    undef( $t );

};

subtest qq{Script Structure} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{./c '1+(2+(3+(4+(5+(6+((7+8*9)))))))=' --test-test -d} );
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

    $t = tests::Tester->run_cmd( qq{./c '1+(2+(3+(4+(5+(6+((7+8*9)))))))=' --test-test} );
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

subtest qq{aliases (In-Proc Test)} => sub{
    my $c = FTCalc->new();
    my $t;
    my $res;

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{age_of_moon_i( l2e( 2025, 12, 5, 12 ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for age_of_moon_instant()} );
    equal( $res, 14.705978187, qq{age_of_moon_i( l2e( 2025, 12, 5, 12 ) ) => 14.705978187} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ang_dist( -100, 100, 100, -100 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for vector_angle()} );
    equal( $res, 180, qq{ang_dist( -100, 100, 100, -100 ) => 180} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angle( 100, 100, 0, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for angle_between_points()} );
    equal( $res, -135, qq{angle( 100, 100, 0, 0 ) => -135} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{angular_distance( -100, 100, 100, -100 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for vector_angle()} );
    equal( $res, 180, qq{angular_distance( -100, 100, 100, -100 ) => 180} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{d2d( 0, 24 / SAKUBOU )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for dhms2dhms()} );
    equal( scalar( @{ $res } ), 4, qq{d2d( 0, 24 / SAKUBOU )} );
    equal( ${ $res }[ 0 ], 0 );
    equal( ${ $res }[ 1 ], 0 );
    equal( ${ $res }[ 2 ], 48 );
    equal( ${ $res }[ 3 ], 45.7797882084 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{d2s( 1, 1:23:45 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for dhms2sec()} );
    equal( $res, 91425, qq{d2s( 1, 1:23:45 ) => 91425} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{dist( 100, 100, 0, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for dist_between_points()} );
    equal( $res, 141.421356237, qq{dist( 100, 100, 0, 0 ) => 141.421356237} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{e2g( -14182940 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for epoch2gmt()} );
    equal( scalar( @{ $res } ), 6, qq{アポロ11号が月面に着陸した時: e2g( -14182940 )} );
    equal( ${ $res }[ 0 ], 1969 );
    equal( ${ $res }[ 1 ], 7 );
    equal( ${ $res }[ 2 ], 20 );
    equal( ${ $res }[ 3 ], 20 );
    equal( ${ $res }[ 4 ], 17 );
    equal( ${ $res }[ 5 ], 40 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{e2l( -14182940 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for epoch2local()} );
    equal( scalar( @{ $res } ), 6, qq{アポロ11号が月面に着陸した時: e2l( -14182940 )} );
    equal( ${ $res }[ 0 ], 1969 );
    equal( ${ $res }[ 1 ], 7 );
    equal( ${ $res }[ 2 ], 21 );
    equal( ${ $res }[ 3 ], 5 );
    equal( ${ $res }[ 4 ], 17 );
    equal( ${ $res }[ 5 ], 40 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{g2e( 1969年7月20日 20時17分40秒 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for gmt2epoch()} );
    equal( $res, -14182940, qq{アポロ11号が月面に着陸した時: g2e( 1969年7月20日 20時17分40秒 ) => -14182940} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{g2xyz( deg2rad( $deg_Tokyo_St ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for geo2xyz()} );
    equal( scalar( @{ $res } ), 3, qq{g2xyz( deg2rad( $deg_Tokyo_St ) )} );
    equal( ${ $res }[ 0 ], -3959659.21279 );
    equal( ${ $res }[ 1 ],  3350075.51702 );
    equal( ${ $res }[ 2 ],  3699524.90488 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gazm_rl( deg2rad( $deg_Tokyo_St, $deg_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for geo_rl_azimuth()} );
    equal( $res, 216.733277422, qq{東京駅から昭和基地までの等角航路の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gazm( dms2rad( $dms_Tokyo_St, $dms_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for geo_azimuth()} );
    equal( $res, 206.108012524, qq{東京駅から昭和基地までの方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gd_km_azm( dms2rad( $dms_Tokyo_St, $dms_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for geo_dist_km_and_azimuth()} );
    equal( scalar( @{ $res } ), 2, qq{東京駅から昭和基地まで} );
    equal( ${ $res }[ 0 ], 14056.1311832, qq{大圏航路の距離（km）} );
    equal( ${ $res }[ 1 ], 206.108012524, qq{大圏航路の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gd_km( dms2rad( $dms_Tokyo_St, $dms_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for geo_distance_km()} );
    equal( $res, 14056.1311832, qq{東京駅から昭和基地までの距離（大圏航路）（km）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gd_m_azm( dms2rad( $dms_Tokyo_St, $dms_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for geo_dist_m_and_azimuth()} );
    equal( scalar( @{ $res } ), 2, qq{東京駅から昭和基地まで} );
    equal( ${ $res }[ 0 ], 14056131.1832, qq{大圏航路の距離（m）} );
    equal( ${ $res }[ 1 ], 206.108012524, qq{大圏航路の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gd_m( dms2rad( $dms_Tokyo_St, $dms_Showa_Base ) ) / 1000} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for geo_distance_m()} );
    equal( $res, 14056.1311832, qq{東京駅から昭和基地までの距離（大圏航路）（m->km）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gd_rl_km_azm( deg2rad( $deg_Tokyo_St, $deg_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for geo_rl_dist_km_and_azimuth()} );
    equal( scalar( @{ $res } ), 2, qq{東京駅から昭和基地まで} );
    equal( ${ $res }[ 0 ], 14484.2565649, qq{等角航路の距離（km）} );
    equal( ${ $res }[ 1 ], 216.733277422, qq{等角航路の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gd_rl_km( deg2rad( $deg_Tokyo_St, $deg_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for geo_rl_distance_km()} );
    equal( $res, 14484.2565649, qq{東京駅から昭和基地までの距離（等角航路）（km）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gd_rl_m_azm( deg2rad( $deg_Tokyo_St, $deg_Showa_Base ) )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for geo_rl_dist_m_and_azimuth()} );
    equal( scalar( @{ $res } ), 2, qq{東京駅から昭和基地まで} );
    equal( ${ $res }[ 0 ], 14484256.5649, qq{等角航路の距離（m）} );
    equal( ${ $res }[ 1 ], 216.733277422, qq{等角航路の方角（度）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{gd_rl_m( deg2rad( $deg_Tokyo_St, $deg_Showa_Base ) ) / 1000} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for geo_rl_distance_m()} );
    equal( $res, 14484.2565649, qq{東京駅から昭和基地までの距離（等角航路）（m->km）} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{kgf2n( 6.5 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for kgf2newton()} );
    equal( $res, 63.743225, qq{kgf2n( 6.5 ) => 63.743225} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{l2e( 1969年7月21日 5時17分40秒 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for local2epoch()} );
    equal( $res, -14182940, qq{アポロ11号が月面に着陸した時: l2e( 1969年7月21日 5時17分40秒 ) => -14182940} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{midpt( 100, 100, 0, 0 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for midpt_between_points()} );
    equal( scalar( @{ $res } ), 2, qq{midpt( 100, 100, 0, 0 )} );
    equal( ${ $res }[ 0 ], 50 );
    equal( ${ $res }[ 1 ], 50 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{mmod( 10, -1.2 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for math_mod()} );
    equal( $res, -0.8, qq{mmod( 10, -1.2 ) => -0.8} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{n2kgf( 64 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for newton2kgf()} );
    equal( $res, 6.52618376306, qq{n2kgf( 64 ) => 6.52618376306} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{pct( 2, 3, 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for percentage()} );
    equal( $res, 66.7, qq{pct( 2, 3, 1 ) => 66.7} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{pf( 1234567890 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for prime_factorize()} );
    equal( scalar( @{ $res } ), 6, qq{pf( 1234567890 )} );
    equal( ${ $res }[ 0 ], 2 );
    equal( ${ $res }[ 1 ], 3 );
    equal( ${ $res }[ 2 ], 3 );
    equal( ${ $res }[ 3 ], 5 );
    equal( ${ $res }[ 4 ], 3607 );
    equal( ${ $res }[ 5 ], 3803 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{power( 2, 8 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for pow()} );
    equal( $res, 256, qq{power( 2, 8 ) => 256} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{rs( 3, 10, 20 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for ratio_scaling()} );
    equal( $res, 66.6666666667, qq{rs( 3, 10, 20 ) => 66.6666666667} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{s2d( 86400 + 7200 + 180 + 4 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0, qq{Alias for sec2dhms()} );
    equal( scalar( @{ $res } ), 4, qq{s2d( 86400 + 7200 + 180 + 4 )} );
    equal( ${ $res }[ 0 ], 1 );
    equal( ${ $res }[ 1 ], 2 );
    equal( ${ $res }[ 2 ], 3 );
    equal( ${ $res }[ 3 ], 4 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{va( 100, 100, 100, 100 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 0, qq{va( 100, 100, 100, 100 ) => 0} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );


    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{里→メートル( 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 3927.27272727, qq{里→メートル( 1 ) => 3927.27272727} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{メートル→里( 4000 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.01851851852, qq{メートル→里( 4000 ) => 1.01851851852} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{マイル→メートル( 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1609.344, qq{マイル→メートル( 1 ) => 1609.344} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{メートル→マイル( 2000 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.24274238447, qq{メートル→マイル( 2000 ) => 1.24274238447} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{海里→メートル( 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1852, qq{海里→メートル( 1 ) => 1852} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{メートル→海里( 2000 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.07991360691, qq{メートル→海里( 2000 ) => 1.07991360691} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ポンド→グラム( 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 453.59237, qq{ポンド→グラム( 1 ) => 453.59237} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{グラム→ポンド( 500 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.10231131092, qq{グラム→ポンド( 500 ) => 1.10231131092} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{オンス→グラム( 1 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 28.349523125, qq{オンス→グラム( 1 ) => 28.349523125} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{グラム→オンス( 30 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.05821885849, qq{グラム→オンス( 30 ) => 1.05821885849} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{キログラム重→ニュートン( 2.25 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 22.0649625, qq{キログラム重→ニュートン( 2.25 ) => 22.0649625} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{ニュートン→キログラム重( 17 )} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 1.73351756206, qq{ニュートン→キログラム重( 17 ) => 1.73351756206} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );


    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{s2d(d2s(0,24/SAKUBOU,0,0),3)} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( scalar( @{ $res } ), 4, qq{日時分秒} );
    equal( ${ $res }[ 0 ], 0 );
    equal( ${ $res }[ 1 ], 0 );
    equal( ${ $res }[ 2 ], 48 );
    equal( ${ $res }[ 3 ], 45.78 );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

    $t = tests::Tester->run_blk( sub{
        $res = $c->formula( qq{(90-CHIJIKU)} );
    } );
    ok( !defined( $t->exception ), '例外（die）が発生しないこと' );
    $t->exit_is( 0 );
    equal( $res, 66.564, qq{(90-CHIJIKU) => 66.564} );
    $t->stdout_is( qq{} );
    $t->stderr_is( qq{} );

};

subtest qq{aliases (Ex-Proc Test)} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{printf "\n\n" | ./c 'lt( 2 )'} );
    $t->exit_is( 0, qq{printf "\n\n" | ./c 'lt( 2 )'} );
    $t->stdout_like( qr/^Lap  Split\-Time    Lap\-Time      Date\-Time\n/ );
    $t->stdout_like( qr/\r2\/2  00:00:00\./ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo '' | ./c 'sw()'} );
    $t->exit_is( 0, qq{echo '' | ./c 'sw()'} );
    $t->stdout_like( qr/\nstopwatch\(\) = \d/ );
    $t->stdout_like( qr/\n0\./ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

};

subtest qq{-d, --debug} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{echo | ./c -d} );
    $t->exit_is( 0, qq{echo | ./c -d} );
    $t->stdout_like( qr/^dbg: arg="\-d", \@val=0\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo | ./c --debug} );
    $t->exit_is( 0, qq{echo | ./c --debug} );
    $t->stdout_like( qr/^dbg: arg="\-\-debug", \@val=0\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo | ./c -dv} );
    $t->exit_is( 0, qq{echo | ./c -dv} );
    $t->stdout_like( qr/dbg: arg="\-d", \@val=1\ndbg: arg="\-v", \@val=0\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c -d '-20-3*2(1+sqrt(4))='} );
    $t->exit_is( 0, qq{./c -d '-20-3*2(1+sqrt(4))='} );
    $t->stdout_like( qr/^dbg: arg="\-d", \@val=1\n/ );
    $t->stdout_like( qr/\nRemain RPN: \-20 3 2\n/ );
    $t->stdout_like( qr/\n Result: \-38\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{-v, --verbose} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{./c 'sqrt(2**100)=' -v} );
    $t->exit_is( 0, qq{./c 'sqrt(2**100)=' -v} );
    $t->stdout_like( qr/^2 \*\* 100 = 1\.26765060022823e\+30\n/ );
    $t->stdout_like( qr/\nsqrt\( 1\.26765060022823e\+30 \) = 1\.12589990684262e\+15\n/ );
    $t->stdout_like( qr/\n Result: 1125899906842624 \[ = 1\.12589990684262e\+15 \]\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'sqrt(pow(2, 100)+pow(2, 100))=' --verbose} );
    $t->exit_is( 0, qq{./c 'sqrt(pow(2, 100)+pow(2, 100))=' --verbose} );
    $t->stdout_like( qr/\n Result: 1592262918131443\.25 \[ = 1\.59226291813144e\+15 \]\n/ );  ## 1592262918131443.1411559535896932
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '0.22*10**(-6)=' --verbose} );
    $t->exit_is( 0, qq{./c '0.22*10**(-6)=' --verbose} );
    $t->stdout_like( qr/\n Result: 0.00000022 \[ = 2\.2e\-07 \]\n/ );            ## 0.00000022
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c -v '-20-3*2(1+sqrt(4))='} );
    $t->exit_is( 0, qq{./c -v '-20-3*2(1+sqrt(4))='} );
    $t->stdout_like( qr/^3 \* 2 = 6\n/ );
    $t->stdout_like( qr/\nsqrt\( 4 \) = 2\n/ );
    $t->stdout_like( qr/\n1 \+ 2 = 3\n/ );
    $t->stdout_like( qr/\n6 \* 3 = 18\n/ );
    $t->stdout_like( qr/\n\-20 \- 18 = \-38\n/ );
    $t->stdout_like( qr/\n Result: \-38\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '10*-3*-5+-4/2=' --verbose} );
    $t->exit_is( 0, qq{./c '10*-3*-5+-4/2=' --verbose} );
    $t->stdout_like( qr/^10 \* \-3 = \-30\n/ );
    $t->stdout_like( qr/\n\-30 \* \-5 = 150\n/ );
    $t->stdout_like( qr/\n\-4 \/ 2 = \-2\n/ );
    $t->stdout_like( qr/\n150 \+ \-2 = 148\n/ );
    $t->stdout_like( qr/\n Result: 148\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c --verbose '0x0d*0xff/(-0x5*-0x0d)='} );
    $t->exit_is( 0, qq{./c --verbose '0x0d*0xff/(-0x5*-0x0d)='} );
    $t->stdout_like( qr/^13 \* 255 = 3315\n/ );
    $t->stdout_like( qr/\n\-5 \* \-13 = 65\n/ );
    $t->stdout_like( qr/\n3315 \/ 65 = 51\n/ );
    $t->stdout_like( qr/\n Result: 51 \[ = 0x33 \]\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'linstep( 0.00000022, -1, 2 )' -v} );
    $t->exit_is( 0, qq{./c 'linstep( 0.00000022, -1, 2 )' -v} );
    $t->stdout_like( qr/\n Result: \( 0\.00000022, \-0\.99999978 \) \[ = \( 2\.2e\-07, \-0\.99999978 \) \]\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{-r, --rpn} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{./c '10*-3' '*-5+-4/2=' -r} );
    $t->exit_is( 0, qq{./c '10*-3' '*-5+-4/2=' -r} );
    $t->stdout_is( qq{10 -3 * -5 * -4 2 / +\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '10*-3' '*-5+-4/2=' --rpn} );
    $t->exit_is( 0, qq{./c '10*-3' '*-5+-4/2=' --rpn} );
    $t->stdout_is( qq{10 -3 * -5 * -4 2 / +\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c '10*-3' '*-5+-4/2=' --rpn --verbose} );
    $t->exit_is( 0, qq{./c '10*-3' '*-5+-4/2=' --rpn --verbose} );
    $t->stdout_like( qr/^Remain RPN: 10\n/ );
    $t->stdout_like( qr/\nRemain RPN: 150 \-4 2\n/ );
    $t->stdout_like( qr/\n10 \-3 \* \-5 \* \-4 2 \/ \+\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{--version} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{./c --version} );
    $t->exit_is( 0, qq{./c --version} );
    $t->stdout_like( qr/^Version: \d/ );
    $t->stdout_like( qr/\n   Perl: v\d/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{-h, --help} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{./c -h} );
    $t->exit_is( 0, qq{./c -h} );
    $t->stdout_like( qr/^Usage: c / );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c --help} );
    $t->exit_is( 0, qq{./c --help} );
    $t->stdout_like( qr/^Usage: c / );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c --test-test --help} );
    $t->exit_is( 0, qq{./c --test-test --help} );
    $t->stdout_like( qr/^Usage: c / );
    $t->stdout_like( qr/\n  =     Equals sign. In \*c\* script, it has the meaning of terminating the/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{PATH="./tests:\$PATH" ./c --test-test --help} );
    $t->exit_is( 0, qq{PATH="./tests:\$PATH" ./c --test-test --help} );
    $t->stdout_like( qr/^Usage: c / );
    $t->stdout_like( qr/\n  =     Equals sign. In \*c\* script, it has the meaning of terminating the/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{COLUMNS="70" LINES="30" ./c --help} );
    $t->exit_is( 0, qq{COLUMNS="70" LINES="30" ./c --help} );
    $t->stdout_like( qr/^Usage: c /, qq{Specified character width.} );
    $t->stdout_like( qr/\n  =     Equals sign. In \*c\* script, it has the meaning of terminating\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{env -u COLUMNS -u LINES ./c --help} );
    $t->exit_is( 0, qq{env -u COLUMNS -u LINES ./c --help} );
    $t->stdout_like( qr/^Usage: c / );
    $t->stdout_like( qr/\n  =     Equals sign. In \*c\* script, it has the meaning of terminating the\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );
};

subtest qq{-b, --banner} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{./c -b 's2d( d2s( 0, 24 / 29.53, 0, 0 ), 1 )'} );
    $t->exit_is( 0, qq{./c -b 's2d( d2s( 0, 24 / 29.53, 0, 0 ), 1 )'} );
    $t->stdout_is( qq{( 0, 0, 48, 45.8 )\n} );
    $t->stderr_like( qr/\nC \- The Flat\-Text Calculator \(Perl Script\)\n/ );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c --banner 'paper_size( 4 )'} );
    $t->exit_is( 0, qq{./c --banner 'paper_size( 4 )'} );
    $t->stdout_is( qq{( 210, 297 )\n} );
    $t->stderr_like( qr/\nC \- The Flat\-Text Calculator \(Perl Script\)\n/ );
    undef( $t );
};

subtest qq{-u, --user-defined} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $t->exit_is( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $t->stdout_is( qq{403.822719846\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    `rm -f .c.rc`;

    $t = tests::Tester->run_cmd( qq{./c -u} );
    $t->exit_is( 0, qq{./c -u} );
    $t->stdout_like( qr/^=== User Defined ===\n/ );
    $t->stdout_like( qr/\n====================\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $t->exit_isnt( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: lexer: error: "tokyo_st_coord, osaka_st_coord \)=": Could not interpret\.\n/ );
    undef( $t );

    `gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.failed && mv .c.rc.failed .c.rc`;

    $t = tests::Tester->run_cmd( qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $t->exit_isnt( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/c: lexer: error: \.\/\.c\.rc: Failed to load user rc file: / );
    undef( $t );

    `gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.duplicate && mv .c.rc.duplicate .c.rc`;

    $t = tests::Tester->run_cmd( qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )' -v} );
    $t->exit_is( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )' -v} );
    $t->stdout_like( qr/\n Result: 403\.822719846\n/ );
    $t->stderr_is( qq{c: lexer: warn: "osaka_st_coord": "deg2rad( 34.70248, 135.49595 )" -> "deg2rad( 34.70248, 135.49595 )": Overwrites the existing definition.\n} );
    undef( $t );

    `gzip -dc tests/c.rc.tar.gz | tar xf - .c.rc.deploy && mv .c.rc.deploy .c.rc`;

    $t = tests::Tester->run_cmd( qq{./c --user-defined} );
    $t->exit_is( 0, qq{./c --user-defined} );
    $t->stdout_like( qr/^=== User Defined ===\n/ );
    $t->stdout_like( qr/\n====================\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )' -v} );
    $t->exit_is( 0, qq{./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )' -v} );
    $t->stdout_like( qr/\n Result: 403\.822719846\n/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

};

subtest qq{STDIN} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{echo '１２３，４５６－５９ ＋ １２３．４５６＊２＝' | ./c} );
    $t->exit_is( 0, qq{echo '１２３，４５６－５９ ＋ １２３．４５６＊２＝' | ./c} );
    $t->stdout_is( qq{123643.912\n} );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo '123 2(=' | ./c} );
    $t->exit_isnt( 0, qq{echo '123 2(=' | ./c} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/^c: parser: error: The position of the "\)" is incorrect\.\n/ );
    undef( $t );
};

done_testing();
