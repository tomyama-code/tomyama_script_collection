#!/usr/bin/env perl
use strict;
use warnings;

use lib qx/tcs_bin_path.pl/;
use FTCalc;

my $bVerbosDisplay = 1;

# 初期化
my $c = FTCalc->new();
$c->_setVerbos( $bVerbosDisplay );

my $res = '';

# 数式を動的に組み立てて実行
my( $day, $h, $m, $s ) =
    $c->formula( qq{
        dhms2dhms(
            0, 24 / SAKUBOU, 0, 0
        )
    } );
$s = $c->formula( qq{round( $s, 3 )} );

# 結果の利用
print( qq{Calculated result: $day days $h hours $m minutes $s seconds.\n} );

my( $y, $d ) = $c->formula( qq{age( l2e( 2026-05-01 ) )} );
print( qq{Age: $y years, $d days old\n} );

## エラーになる式を実行
#$res = $c->formula( qq{round( pi )} );
##if( defined( $res ) ){
#print( qq{\$res="$res"\n} );
##}

# 複雑な書式を返す式を実行
#   $res="( 0, 127.5, 255 ) [ = ( 0x0, 127.5, 0xFF ) ]"
$res = $c->formula( qq{linspace( 0|0, 255, 3 )} );
# 無加工のリザルトが返される（必要であれば呼び出し元で加工する）
print( qq{\$res="$res"\n} );

# 終了してからもう一度起動してみる
undef( $c );
printf( qq{re-generate-c-1\n} );
$c = FTCalc->new( '--banner' );
$c->_setVerbos( $bVerbosDisplay );

# 明示的に消さずに上書きで起動してみる
printf( qq{re-generate-c-2\n} );
$c = FTCalc->new( '--banner' ); # re-generate-c-1 はここで消える
$c->_setVerbos( $bVerbosDisplay );
$c->formula( qq{1+3} );

{
    printf( qq{re-generate-c-3 (\$c2)\n} );
    my $c2 = FTCalc->new( '--banner' );
    $c2->_setVerbos( $bVerbosDisplay );
    $c2->formula( qq{２ ＰＩ １０} );
}   # re-generate-c-3 はここで消える

# 終了
undef( $c );    # re-generate-c-2 はここで消える

printf( qq{bye!\n} );
exit( 0 );
