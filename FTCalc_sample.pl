#!/usr/bin/env perl
use strict;                         # first released with perl 5
use warnings;                       # first released with perl v5.6.0
use utf8;                           # first released with perl v5.6.0

binmode( STDOUT, ':utf8' );
binmode( STDERR, ':utf8' );

use lib qx/.\/tsc_bin_path.pl/;
use FTCalc;

my $bVerbosDisplay = 1;

sub cmt( $ )
{
    my( $comment ) = @_;
    print( qq{$comment\n} );
}

cmt( q{# 初期化} );
my $c = FTCalc->new();
$c->_setVerbos( $bVerbosDisplay );

my $res = '';

cmt( q{# 数式を動的に組み立てて実行} );
my( $day, $h, $m, $s ) =
    $c->formula( qq{
        dhms2dhms(
            0, 24 / SAKUBOU, 0, 0
        )
    } );
$s = $c->formula( qq{round( $s, 3 )} );

cmt( q{# 結果の利用} );
print( qq{Calculated result: $day days $h hours $m minutes $s seconds.\n} );

my( $y, $d ) = $c->formula( qq{age( l2e( 2026-05-01 ) )} );
print( qq{Age: $y years, $d days old\n} );

#cmt( q{# エラーになる式を実行} );
#$res = $c->formula( qq{round( pi )} );
##if( defined( $res ) ){
#print( qq{\$res="$res"\n} );
##}

cmt( q{# 複雑な書式を返す式を実行} );
#   $res="( 0, 127.5, 255 ) [ = ( 0x0, 127.5, 0xFF ) ]"
$res = $c->formula( qq{linspace( 0|0, 255, 3 )} );
cmt( q{# リファレンスが返される} );
print( qq{\$res="$res"\n} );
printf( qq{\@\$res=( %s )\n}, join( ', ', @$res ) );
cmt( q{# 必要であれば呼び出し元で加工する} );
my( $first, $second, $third ) = @$res;
print( qq{\$first=$first, \$second=$second, \$third=$third\n} );

cmt( q{# 終了してからもう一度起動してみる} );
undef( $c );
cmt( q{# ここでインスタンスが消滅} );
printf( qq{re-generate-c-1\n} );
$c = FTCalc->new( '--banner' );
$c->_setVerbos( $bVerbosDisplay );

cmt( q{# 明示的に消さずに上書きで起動してみる} );
printf( qq{re-generate-c-2\n} );
$c = FTCalc->new( '--banner' );
cmt( q{# re-generate-c-1 はここで消える} );
$c->_setVerbos( $bVerbosDisplay );
$c->formula( qq{1+3} );

{
    printf( qq{re-generate-c-3 (\$c2)\n} );
    my $c2 = FTCalc->new();
    $c2->_setVerbos( $bVerbosDisplay );
    $c2->formula( qq{２ ＰＩ １０} );
}
cmt( q{# re-generate-c-3 はここで消える} );

cmt( q{# 終了} );
undef( $c );
cmt( q{# re-generate-c-2 はここで消える} );

printf( qq{bye!\n} );
exit( 0 );
