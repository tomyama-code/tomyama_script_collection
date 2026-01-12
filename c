#!/usr/bin/perl -w
################################################################################
## C -- The Flat Text Calculator
##
## << Doctrine of the Flat-Text Faith >>
##   - Blessed are the plain, for they shall be grepped.
##   - No markup shall obscure the meaning.
##   - Let every formula be readable, editable, and eternal.
##   - A tool that cannot be piped is not worthy of use.
##   - In text we trust.
##   - Emojis are evil.
##     (They pretend to be text, but they are pictures in disguise.)
##
## - The "c" script displays the result of the given expression.
##
## - Version: 1
## - $Revision: 4.119 $
##
## - Script Structure
##   - main
##     - FormulaEngine
##       - FormulaLexer
##       - FormulaParser
##         - FormulaStack
##       - FormulaEvaluator
##     - [   Base Package ] OutputFunc
##     - [ shared package ] CAppConfig, FormulaToken, TableProvider
##
## - Author: 2025-2026, tomyama
## - Intended primarily for personal use, but BSD license permits redistribution.
##
## BSD 2-Clause License:
## Copyright (c) 2025-2026, tomyama
## All rights reserved.
################################################################################

## Revision: 1.1
package OutputFunc;
use strict;
use warnings 'all';

# OutputFunc コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{APPCONFIG} = shift( @_ );
    $self->{LABEL} = shift( @_ );
    $self->Reset();
#    $self->dPrint( qq{OutputFunc: label="$label": instance is generated\n} );
    return $self;               # 無名ハッシュ参照を返す
}

sub Reset()
{
    my $self = shift( @_ );
}

sub SetLabel()
{
    my $self = shift( @_ );
    $self->{LABEL} = shift( @_ );
}

##########
## 書式表示
sub PrintHelp( $ )
{
    my $self = shift( @_ );

    my $msg = $self->GetHelpMsg();

#    if( $_[0] ){
#        print STDERR ( $msg );
#    }else{
        print STDOUT ( $msg );
#    }

    return 0;
}

sub GetHelpMsg()
{
    my $self = shift( @_ );

    my $ver = &GetVersion();

    my $trm_columns = ( $self->GetTermSize() )[ 0 ];
    #print( qq{$trm_columns\n} );

    my $ops = join( ' ', &TableProvider::GetOperatorsList() );
    my $fns = &ArrayFitToDeviceWidth( $trm_columns, 4, &TableProvider::GetFunctionsList() );

    my $ops_help = qq{<OPERATORS>\n};
    for my $op( &TableProvider::GetOperatorsList() ){
        $ops_help .= &FmtHelp( $trm_columns, $op );
    }

    my $fns_help = qq{<FUNCTIONS>\n};
    for my $fn( &TableProvider::GetFunctionsList() ){
        $fns_help .= &FmtHelp( $trm_columns, $fn );
    }

    my $msg = "Usage: " .
        qq{$self->{APPCONFIG}->{APPNAME} [<OPTIONS...>] [<EXPRESSIONS...>]\n} .
        qq{\n} .
        qq{  - The c script displays the result of the given expression.\n} .
        qq{  - Version: $ver}.qq{\n} .
        qq{\n} .
        qq{<EXPRESSIONS>: Specify the expression.\n} .
        qq{\n} .
        qq{  <OPERANDS>:\n} .
        qq{    Decimal:  0, -1, 100 ...\n} .
        qq{    Hexadecimal: 0xf, -0x1, 0x0064 ...\n} .
        qq{    Constant: PI (=3.14159265358979)\n} .
        qq{              NOW (=CURRENT-TIME)\n} .
        qq{              User-defined-file:\n} .
        qq{                ".c.rc" should be placed in the same directory\n} .
        qq{                as "c script" or in "\$HOME".\n} .
        qq{\n} .
        qq{  <OPERATORS>:\n} .
        qq{    $ops\n} .
        qq{\n} .
        qq{  <FUNCTIONS>:\n} .
        qq{$fns\n} .
        qq{\n} .
        qq{<OPTIONS>:\n} .
        qq{  -v, --verbose:\n} .
        qq{    The intermediate steps of the calculation will also be displayed.\n} .
        qq{  -r, --rpn:\n} .
        qq{    The expression will be displayed in Reverse Polish Notation,\n} .
        qq{    but the calculation result will not be shown.\n} .
        qq{  -u, --user-defined:\n} .
        qq{    Outputs a list of user-defined values ​​defined in ".c.rc".\n} .
        qq{  --version: Print the version of this script and Perl and exit.\n} .
        qq{  -h, --help: Display this help and exit.\n} .
        qq{\n} .
        qq{$ops_help} .
        qq{\n} .
        qq{$fns_help} .
        qq{\n} .
        qq{Try "perldoc $self->{APPCONFIG}->{APPNAME}" for more information.\n};

    return $msg;
}

## Revision: 1.2
sub PrintVersion()
{
    my $ver = &GetVersion();
    my $v = qq{Version: $ver\n} .
            qq{   Perl: $^V\n};
    print( $v );
}
sub GetVersion()
{
    my $rev = &GetRevision();

    my $major = 1;
    my( $minor, $revision ) = split( /\./, $rev );
    my $version = sprintf( '%d.%02d.%03d', $major, $minor, $revision );

    return $version;
}
sub GetRevision()
{
    my $rev = q{$Revision: 4.119 $};
    $rev =~ s!^\$[R]evision: (\d+\.\d+) \$$!$1!o;
    return $rev;
}

# 端末幅を取得するための Term::ReadKey は非コアモジュールで、
# インストール時に C コンパイラが必要となる環境もある。
# ビルド要件を増やしたくない場合にこのサブルーチンを使用するという前提。
## Revision: 1.4
sub GetTermSize()
{
    my $self = shift( @_ );

    my( $width, $height ) = ( undef, undef );

    # Try stty
    if( $self->{APPCONFIG}->GetBIsStdoutTty() ){
        #my( $trm_columns, $trm_lines,
        #    $trm_width, $trm_height ) = &Term::ReadKey::GetTerminalSize();
        # ビルド要件を増やさない為に使用しない。

        my $stty_out = `stty size 2>/dev/null`;
        if( $stty_out =~ m/^\s*(\d+)\s+(\d+)/ ){
            $height = $1;
            $width  = $2;
            return ( $width, $height );
        }
    }

    # COLUMNS/LINES 環境変数は多くのシェルが設定するが、
    # export されていない場合もあるため // (defined-or) でフォールバック。
    # ▼ 代表的な歴史的/実用的な幅
    #   72 : GNU 系コマンド／メール折り返しの伝統
    #   76 : perldoc が使用
    #   78 : 80 の“2字控え”として昔使われた妥協値
    #   80 : 端末標準幅。多くの CLI のデフォルト。最も一般的。
    # DEC VT100 の画面サイズは 80x24
    # 今回は汎用性と説明のしやすさを優先し、80 を採用する。
    $width  = $ENV{COLUMNS} // 80;  # Fall back to environment
    $height = $ENV{LINES}   // 24;  # 24 は歴史的・実用的に最も無難な値

    return ( $width, $height );
}

sub FmtHelp( $ )
{
    my $trm_columns = shift( @_ );
    my $ope = shift( @_ );
    my $indent_len = 8;

    my $fmt_text = '';
    my $line = '';

    ##1234567890
    ##  1234567
    ##  ceil  ceil( N ). Returning the smallest integer value greater than or equal
    ##        to the given numerical argument. [POSIX]
    ##  $ope  $help
    my $ope_len = length( $ope );
    my $padding_len = $indent_len - ( 2 + $ope_len );
    if( $padding_len > 0 ){
        $line = "  $ope" . ' ' x $padding_len;
    }else{
        $fmt_text = "  $ope" . "\n";
        $line = ' ' x $indent_len;
    }

    my $help = &TableProvider::GetHelp( $ope );
    if( !defined( $help ) ){
        $help = '';
    }

    my @help_tokens = split( / +/, $help );
    for my $token( @help_tokens ){
        my $text_len = length( $line );
        my $token_len = length( $token );
        if( ( $text_len + 1 + $token_len ) > $trm_columns ){
            $fmt_text .= $line . "\n";
            $line = ' ' x $indent_len . $token;
        }else{
            my $sep = " ";
            $sep = '' if( $line =~ m/ $/o );
            $line .= $sep . $token;
        }
    }
    $fmt_text .= $line;
    $fmt_text =~ s/ *$//o;
    $fmt_text .= "\n";

    return $fmt_text;
}

sub ArrayFitToDeviceWidth( $$ )
{
    my $trm_columns = shift( @_ );
    my $indent_len = shift( @_ );
    my @items = @_;

    my $item_len = scalar( @items );

    my $fmt_text = '';
    my $line = ' ' x $indent_len;
    for my $item( @items ){
        my $text_len = length( $line );
        my $item_len = length( $item );
        if( ( $text_len + 2 + $item_len + 1 ) > $trm_columns ){
            $fmt_text .= $line . ",\n";
            $line = ' ' x $indent_len . $item;
        }else{
            my $sep = ", ";
            $sep = '' if( $line =~ m/^ +$/o );
            $line .= $sep . $item;
        }
    }
    $fmt_text .= $line;
    $fmt_text =~ s/, *$//o;

    return $fmt_text;
}

sub dPrint( @ )
{
    my $self = shift( @_ );
    if( $self->{APPCONFIG}->GetDebug() ){
        print( $self->{LABEL} . ': ' );
        print( @_ );
    }
}

sub dPrintf( @ )
{
    my $self = shift( @_ );
    if( $self->{APPCONFIG}->GetDebug() ){
        print( $self->{LABEL} . ': ' );
        printf( @_ );
    }
}

sub Die()
{
    my $self = shift( @_ );
    die( $self->GenErrMsg( @_ ) );
}

#sub errPrint()
#{
#    my $self = shift( @_ );
#    warn( $self->GenErrMsg( @_ ) );
#}

sub GenErrMsg()
{
    my $self = shift( @_ );
    return $self->GenMsg( 'error', @_ );
}

sub warnPrint()
{
    my $self = shift( @_ );
    warn( $self->GenMsg( 'warn', @_ ) );
}

sub GenMsg()
{
    my $self = shift( @_ );
    my $level = shift( @_ );
    my $msg = qq{$self->{APPCONFIG}->{APPNAME}: $self->{LABEL}: $level: } .
        join( ' ', @_ );
    return $msg;
}


package FormulaToken;
use strict;
use warnings 'all';
use Class::Struct;

use constant {
    BIT_OPERAND  => 0x01,
    BIT_OPERATOR => 0x02,
    BIT_FUNCTION => 0x04,
    BIT_UNKNOWN  => 0x08,
    BIT_HEX      => 0x10,
};

struct FormulaToken =>{
    id    => '$',
    flags => '$',
    data  => '$',
};

sub IsOperator()
{
    my $self = shift( @_ );
    return $self->flags & BIT_OPERATOR;
}

sub IsFunction()
{
    my $self = shift( @_ );
    return $self->flags & BIT_FUNCTION;
}

sub IsOperand()
{
    my $self = shift( @_ );
    return $self->flags & BIT_OPERAND;
}

sub IsHex()
{
    my $self = shift( @_ );
    return $self->flags & BIT_HEX;
}

sub GetTokenSymbol( $ )
{
    my $self = shift( @_ );
    my $token_data = $self->data;
    if( $self->IsOperand() ){
        $token_data = 'OPERAND';
    }
    return $token_data;
}

sub Copy( $ )
{
    my $self = shift( @_ );
    my $value = shift( @_ );
    my $copy_token = FormulaToken->new( id=>$self->id, flags=>$self->flags, data=>$value );
    return $copy_token;
}

sub NewOperand( $;$ )
{
    my $value = shift( @_ );
    my $bHex = 0;
    $bHex = shift( @_ ) if( defined( $_[ 0 ] ) );

    my $flags = BIT_OPERAND;
    $flags |= BIT_HEX if( $bHex );

    return FormulaToken->new( id=>-1, flags=>$flags, data=>$value );
}

sub NewOperator( $;$ )
{
    my $operator = shift( @_ );
    my $bFunction = 0;
    $bFunction = shift( @_ ) if( defined( $_[ 0 ] ) );

    my $flags = BIT_OPERATOR;
    $flags |= BIT_FUNCTION if( $bFunction );

    return FormulaToken->new( id=>-1, flags=>$flags, data=>$operator );
}


package TableProvider;
use strict;
use warnings 'all';
use POSIX qw/hypot floor ceil/;
use Math::BigInt;
use Math::Trig; ## pi, rad2deg(), deg2rad()
use List::Util; ## min(), max(), shuffle(), uniq, sum()
use Time::Local;    # timelocal(), timegm()
use Time::HiRes;

use constant {
    O_INDX => 0,
    O_TYPE => 1,
    O_ARGC => 2,
    O_HELP => 3,
    O_SUBR => 4,
};

use constant {
    T_OPERATOR => 0x01,
    T_FUNCTION => 0x02,
    T_SENTINEL => 0x04,
    T_OTHER    => 0x08,
    T_UNKNOWN  => 0x10,
};

use constant {
    VA => -2,
};

use constant{
    E_RIGH => 0,
    E_LEFT => 1,
    E_REMV => 2,
    E_FUNC => 3,
    E_IGNR => 4,
    E_UNKN => 5,
};
use constant E_ACT => qw(
    E_RIGH E_LEFT E_REMV E_FUNC E_IGNR E_UNKN
);

## 単位換算係数 Unit Conversion Factor
## 長さ
use constant UCFACTOR_RI            => 3927.2727272727; # 3,927.27 meters
use constant UCFACTOR_MILE          => 1609.344; # 1,609.34 meters
use constant UCFACTOR_NAUTICAL_MILE => 1852; # 1,852 meters, 1海里は、緯度の 1 分の距離
    # 緯度1分の定義は「子午線の曲率」に基づくため、厳密には場所によって以下の通り変化します：
    # - 赤道付近: 約 1843 m（地球のカーブが急なため、1分あたりの距離は短い）
    # - 極地付近: 約 1862 m（地球のカーブが緩やかなため、1分あたりの距離は長い）
    # $ c 'geo_distance_m( dms2rad( 0, 0, 0 ), 0, dms2rad( 0, 1, 0 ), 0 )'
    # 1853.25132890615
    # $ c 'geo_distance_m( dms2rad( 0, 1, 0 ), 0, dms2rad( 0, 2, 0 ), 0 )'
    # 1853.25132890615
    # $ c 'geo_distance_m( dms2rad( 44, 59, 0 ), 0, dms2rad( 45, 0, 0 ), 0 )'
    # 1853.25132890627
    # $ c 'geo_distance_m( dms2rad( 89, 58, 0 ), 0, dms2rad( 89, 59, 0 ), 0 )'
    # 1853.25132890697
    # $ c 'geo_distance_m( dms2rad( 89, 59, 0 ), 0, dms2rad( 90, 0, 0 ), 0 )'
    # 1853.25132890556

## 重さ
use constant UCFACTOR_POUND => 453.59237; # 453.59 grams
use constant UCFACTOR_OUNCE => 28.349523125; # 28.35 grams

## GRS80 楕円体パラメータ
use constant GRS80_EQUATORIAL_RADIUS_M => 6378137;  # a赤道半径（a, 長半径, meters）
use constant GRS80_POLAR_RADIUS_M => 6356752.3142;  # 極半径（b, 短半径, meters）
#use constant GRS80_FLATNESS_OF_THE_EARTH => 0.00335281068118232;    ## f, 1/298.257222101
use constant GRS80_E_SQ => 0.00669438002290079;     # 離心率の二乗 (e^2 = 2f - f^2)

# TableProvider コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $TableProvider::CAppConfig = shift( @_ );
    if( !defined( $TableProvider::opf ) ){
        $TableProvider::opf = OutputFunc->new( $TableProvider::CAppConfig, 'tbl_prvdr' );
    }
    $self->Reset();
    if( $TableProvider::CAppConfig->GetBTest() ){
        my $opeIdx = &GetOperatorsInfo( '_', O_INDX );
        $TableProvider::opf->dPrint( qq{test: \$opeIdx="$opeIdx"\n} );
        my $bSentinel = &IsSentinel( '_' );
        $TableProvider::opf->dPrint( qq{test: \$bSentinel="$bSentinel"\n} );
        $self->Reset();
    }
    return $self;               # 無名ハッシュ参照を返す
}

sub Reset()
{
    my $self = shift( @_ );
}

## このTableProviderはインスタンス経由ではメソッドを使わせない方針
#sub opf()
#{
#    my $self = shift( @_ );
#    return $self->{OPF};
#}

sub GetPriorityOrderBetweenTokens( $$ )
{
    my $last = $_[ 0 ];
    my $curr = $_[ 1 ];
#    print( qq{bef: \$last="$last", \$curr="$curr"\n} );

    my @token_precedence_table = (
        # '+'     '-'     '*'     '/'     '%'     '**'    '|'     '&'     '^'     '<<'    '>>'    '~'     'fn('   '('     ','     ')'     '='     OPERAND END
        [ E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  0 '+'
        [ E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  1 '-'
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  2 '*'
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  3 '/'
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  4 '%'
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  5 '**'
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_RIGH, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  6 '|'
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  7 '&'
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_RIGH, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  8 '^'
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  9 '<<'
        [ E_RIGH, E_RIGH, E_LEFT, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ## 10 '>>'
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ## 11 '~'
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_IGNR, E_FUNC, E_LEFT, E_RIGH, E_UNKN ], ## 12 'fn('
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_IGNR, E_REMV, E_LEFT, E_RIGH, E_UNKN ], ## 13 '('
        [ E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN ], ## 14 ','
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_UNKN, E_UNKN, E_IGNR, E_LEFT, E_LEFT, E_UNKN, E_LEFT ], ## 15 ')'
        [ E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN ], ## 16 '='
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_UNKN, E_UNKN, E_LEFT, E_LEFT, E_LEFT, E_UNKN, E_LEFT ], ## 17 OPERAND
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_UNKN, E_UNKN, E_REMV, E_RIGH, E_REMV ], ## 18 BEGIN
    );

    my $numLast = &TableProvider::GetTokenTblIdx( $last );
    my $numCurr = &TableProvider::GetTokenTblIdx( $curr );
    my $retval = $token_precedence_table[ $numLast ]->[ $numCurr ];
    $TableProvider::opf->dPrint( qq{GetPriorityOrderBetweenTokens(): [[ "$last" : "$curr" ]] -> } . ( E_ACT )[ $retval ] . "\n" );
    return $retval;
}

use constant {
    H_PLUS => qq{Addition. "1 + 2" -> 3.},
    H_MINU => qq{Subtraction. "3 - 2" -> 1.},
    H_MULT => qq{Multiplication. "1 * 2" -> 2.},
    H_DIVI => qq{Division. "1 / 2" -> 0.5.},
    H_MODU => qq{Modulo arithmetic. "5 % 3" -> 2.},
    H_EXPO => qq{Exponentiation. "2 ** 3" -> 8. Similarly, "pow( 2, 3 )".},
    H_BWOR => qq{Bitwise OR. "0x2 | 0x4" -> "6 [ = 0x6 ]".},
    H_BWAN => qq{Bitwise AND. "0x6 & 0x4" -> "4 [ = 0x4 ]".},
    H_BWEO => qq{Bitwise Exclusive OR. "0x6 ^ 0x4" -> "2 [ = 0x2 ]".},
    H_SHTL => qq{Bitwise left shift. "0x6 << 1" -> "12 [ = 0xC ]".},
    H_SHTR => qq{Bitwise right shift. "0x6 >> 1" -> "3 [ = 0x3 ]".},
    H_BWIV => qq{Bitwise Inversion. "~0" -> 0xFFFFFFFFFFFFFFFFFF.},
    H_BBEG => qq{A symbol that controls the priority of calculations.},
    H_COMA => qq{The separator that separates function arguments.},
    H_BEND => qq{A symbol that controls the priority of calculations.},
    H_EQUA => qq{Equals sign. In *c* script, it has the meaning of terminating the calculation formula, but it is not necessary. "1 + 2 =". Similarly, "1 + 2".},
    H_ABS_ => qq{abs( N1 [,.. ] ). Returns the absolute value of its argument. [Perl Native]},
    H_INT_ => qq{int( N1 [,.. ] ). Returns the integer portion of N. [Perl Native]},
    H_FLOR => qq{floor( N1 [,.. ] ). Returning the largest integer value less than or equal to the numerical argument. [POSIX]},
    H_CEIL => qq{ceil( N1 [,.. ] ). Returning the smallest integer value greater than or equal to the given numerical argument. [POSIX]},
    H_RODD => qq{rounddown( NUMBER1 [,..], DECIMAL_PLACES ). Returns the value of NUMBER1 truncated to DECIMAL_PLACES.},
    H_ROUD => qq{round( NUMBER1 [,..], DECIMAL_PLACES ). Returns the value of NUMBER1 rounded to DECIMAL_PLACES.},
    H_RODU => qq{roundup( NUMBER1 [,..], DECIMAL_PLACES ). Returns the value of NUMBER1 rounded up to DECIMAL_PLACES.},
    H_PCTG => qq{percentage( NUMERATOR, DENOMINATOR [, DECIMAL_PLACES ] ). Returns the percentage, rounding the number if DECIMAL_PLACES is specified. alias: pct().},
    H_RASC => qq{ratio_scaling( A, B, C [, DECIMAL_PLACES ] ). When A:B, return the value of X in A:B=C:X. Rounding the number if DECIMAL_PLACES is specified. alias: rs().},
    H_PRIM => qq{is_prime( NUM1 [,.. ] ). Prime number test. Returns 1 if NUM is prime, otherwise returns 0.},
    H_PRFR => qq{prime_factorize( N ). Do prime factorization. N is an integer greater than or equal to 2. alias: pf().},
    H_GPRM => qq{get_prime( BIT_WIDTH ). Returns a random prime number within the range of BIT_WIDTH, where BIT_WIDTH is an integer between 4 and 32, inclusive.},
    H_GCD_ => qq{gcd( NUMBER1,.. ). Returns the greatest common divisor (GCD), which is the largest positive integer that divides each of the operands. [Math::BigInt::bgcd()]},
    H_LCM_ => qq{lcm( NUMBER1,.. ). Returns the least common multiple (LCM). [Math::BigInt::blcm()]},
    H_NCHR => qq{nCr( N, R ). N Choose R. A combination of R items selected from N items. N is a non-negative integer. R is a positive integer.},
    H_MIN_ => qq{min( NUMBER1,.. ). Returns the entry in the list with the lowest numerical value. [List::Util]},
    H_MAX_ => qq{max( NUMBER1,.. ). Returns the entry in the list with the highest numerical value. [List::Util]},
    H_SHFL => qq{shuffle( NUMBER1,.. ). Returns the values of the input in a random order. [List::Util]},
    H_FRST => qq{first( NUMBER1,.. ). Returns the head of the set. Same as slice( NUMBER1,.. , 0, 1 ).},
    H_SPLC => qq{slice( NUMBER1,.., OFFSET, LENGTH ). Extracts elements specified by OFFSET and LENGTH from a set.},
    H_UNIQ => qq{uniq( NUMBER1,.. ). Filters a list of values to remove subsequent duplicates, as judged by a DWIM-ish string equality or "undef" test. Preserves the order of unique elements, and retains the first value of any duplicate set. [List::Util]},
    H_SUM_ => qq{sum( NUMBER1,.. ). Returns the numerical sum of all the elements in the list. [List::Util]},
    H_PROD => qq{prod( NUMBER1,.. ). Returns the product of each value.},
    H_AVRG => qq{avg( NUMBER1,.. ). Returns the average value of all elements in a list.},
    H_ADEC => qq{add_each( NUMBER1,.. , DELTA ). Add each number.},
    H_MLEC => qq{mul_each( NUMBER1,.. , FACTOR ). Multiply each number.},
    H_LNSP => qq{linspace( START, END, LENGTH [, DECIMAL_PLACES] ). Generates a list of evenly spaced numbers from START to END. Returns a sequence of numbers of size LENGTH. LENGTH is an integer greater than or equal to 2. Rounding the number if DECIMAL_PLACES is specified.},
    H_LNST => qq{linstep( START, DELTA, LENGTH ). Generates a list of LENGTH numbers that increase from START by DELTA. Returns the sequence of numbers starting at START and of size LENGTH. LENGTH is an integer greater than or equal to 1.},
    H_MLGT => qq{mul_growth( START, FACTOR, LENGTH ). Starting from START, we multiply the value by FACTOR and add it to the sequence. Returns the sequence of numbers starting at START and of size LENGTH. LENGTH is an integer greater than or equal to 1.},
    H_GFIS => qq{gen_fibo_seq( A, B, LENGTH ). Generates the Generalized Fibonacci Sequence. Returns the sequence of numbers starting at A, B and of size LENGTH. LENGTH is an integer greater than or equal to 2.},
    H_PASZ => qq{paper_size( SIZE [, TYPE ] ). Returns the following information in this order: length of short side, length of long side (in mm). SIZE is a non-negative integer. If TYPE is omitted or 0 is specified, it will be A size. If TYPE is specified as 1, it will be B size ( Japan's unique standards ).},
    H_RAND => qq{rand( N ).  Returns a random fractional number greater than or equal to 0 and less than the value of N. [Perl Native]},
    H_POEX => qq{exp( N1 [,.. ] ). Returns e (the natural logarithm base) to the power of N. [Perl Native]},
    H_EXP2 => qq{exp2( N1 [,.. ] ). Returns the base 2 raised to the power N.},
    H_EP10 => qq{exp10( N1 [,.. ] ). Returns the base 10 raised to the power N.},
    H_LOGA => qq{log( N1 [,.. ] ). Returns the natural logarithm (base e) of N. [Perl Native]},
    H_LOG2 => qq{log2( N1 [,.. ] ). Returns the common logarithm to the base 2.},
    H_LG10 => qq{log10( N1 [,.. ] ). Returns the common logarithm to the base 10.},
    H_SQRT => qq{sqrt( N1 [,.. ] ). Return the positive square root of N. Works only for non-negative operands. [Perl Native]},
    H_POWE => qq{pow( A, B ). Exponentiation. "pow( 2, 3 )" -> 8. Similarly, "2 ** 3". [Perl Native]},
    H_PWIV => qq{pow_inv( A, B ). Returns the power of A to which B is raised.},
    H_R2DG => qq{rad2deg( <RADIANS> [, <RADIANS>..] ) -> ( <DEGREES> [, <DEGREES>..] ). [Math::Trig]},
    H_D2RD => qq{deg2rad( <DEGREES> [, <DEGREES>..] ) -> ( <RADIANS> [, <RADIANS>..] ). [Math::Trig]},
    H_DM2R => qq{dms2rad( <DEG>, <MIN>, <SEC> [, <DEG>, <MIN>, <SEC> ..] ) -> ( <RADIANS> [, <RADIANS>..] ).},
    H_DEGM => qq{dms2deg( <DEG>, <MIN>, <SEC> [, <DEG>, <MIN>, <SEC> ..] ) -> ( <DEGREES> [, <DEGREES>..] ).},
    H_D2DM => qq{deg2dms( <DEGREES> [, <DEGREES>..] ) -> ( <DEG>, <MIN>, <SEC> [, <DEG>, <MIN>, <SEC> ..] ).},
    H_DMDM => qq{dms2dms( <DEG>, <MIN>, <SEC> [, <DEG>, <MIN>, <SEC> ..] ) -> ( <DEG>, <MIN>, <SEC> [, <DEG>, <MIN>, <SEC> ..] ).},
    H_SINE => qq{sin( <RADIANS> ). Returns the sine of <RADIANS>. [Perl Native]},
    H_COSI => qq{cos( <RADIANS> ). Returns the cosine of <RADIANS>. [Perl Native]},
    H_TANG => qq{tan( <RADIANS> ). Returns the tangent of <RADIANS>. [Math::Trig]},
    H_ASIN => qq{asin( N ). The arcus (also known as the inverse) functions of the sine. [Math::Trig]},
    H_ACOS => qq{acos( N ). The arcus (also known as the inverse) functions of the cosine. [Math::Trig]},
    H_ATAN => qq{atan( N ). The arcus (also known as the inverse) functions of the tangent. [Math::Trig]},
    H_ATN2 => qq{atan2( Y, X ). The principal value of the arc tangent of Y / X. [Math::Trig]},
    H_HYPT => qq{hypot( X, Y ). Equivalent to "sqrt( X * X + Y * Y )" except more stable on very large or very small arguments. [POSIX]},
    H_SLPD => qq{angle_deg( X, Y [, IS_AZIMUTH ] ). Returns the straight line distance from (0,0) to (X,Y). Returns the standard mathematical angle (0 degrees = east, counterclockwise). If IS_AZIMUTH is set to true, returns the angle (0 degrees = north, clockwise).},
    H_DIST => qq{dist_between_points( X1, Y1, X2, Y2 ) or dist_between_points( X1, Y1, Z1, X2, Y2, Z2 ). Returns the straight-line distance from (X1,Y1) to (X2,Y2) or from (X1,Y1,Z1) to (X2,Y2,Z2). alias: dist().},
    H_MIDP => qq{midpt_between_points( X1, Y1, X2, Y2 ) or midpt_between_points( X1, Y1, Z1, X2, Y2, Z2 ). Returns the coordinates of the midpoint between (X1,Y1) and (X2,Y2), or (X1,Y1,Z1) and (X2,Y2,Z2). alias: midpt().},
    H_ANGL => qq{angle_between_points( X1, Y1, X2, Y2 [, IS_AZIMUTH ] ) or angle_between_points( X1, Y1, Z1, X2, Y2, Z2 [, IS_AZIMUTH ] ). Returns the angle from (X1,Y1) to (X2,Y2) or the horizontal and vertical angles from (X1,Y1,Z1) to (X2,Y2,Z2). Angles are in degrees. Returns the standard mathematical angle (0 degrees = East, counter-clockwise). If IS_AZIMUTH is set to true, the horizontal angle is returned (0 degrees = north, clockwise). alias: angle().},
    H_GERA => qq{geo_radius( LAT ). Given a latitude (in radians), returns the distance from the center of the Earth to its surface (in meters).},
    H_LATC => qq{radius_of_lat( LAT ). Given a latitude (in radians), returns the radius of that parallel (in meters).},
    H_GDIS => qq{geo_distance( A_LAT, A_LON, B_LAT, B_LON ). Calculates and returns the distance (in meters) from A to B. Latitude and longitude must be specified in radians. Same as geo_distance_m().},
    H_GDIM => qq{geo_distance_m( A_LAT, A_LON, B_LAT, B_LON ). Calculates and returns the distance (in meters) from A to B. Latitude and longitude must be specified in radians. Same as geo_distance(). alias: gd_m().},
    H_GDKM => qq{geo_distance_km( A_LAT, A_LON, B_LAT, B_LON ). Calculates and returns the distance (in kilometers) from A to B. Latitude and longitude must be specified in radians. Same as geo_distance_m() / 1000. alias: gd_km().},
    H_GDEG => qq{geo_azimuth( A_LAT, A_LON, B_LAT, B_LON ). Returns the geographic azimuth (bearing) in degrees from A to B. Note: 0 degrees is North, 90 degrees is East (clockwise). Input: Latitude/Longitude in radians. alias: gazm().},
    H_DD_M => qq{geo_dist_m_and_azimuth( A_LAT, A_LON, B_LAT, B_LON ). Returns the distance (in meters) and bearing (in degrees) from A to B. Latitude and longitude must be specified in radians. North is 0 degrees. alias: gd_m_azm().},
    H_DDKM => qq{geo_dist_km_and_azimuth( A_LAT, A_LON, B_LAT, B_LON ). Returns the distance (in kilometers) and bearing (in degrees) from A to B. Latitude and longitude must be specified in radians. North is 0 degrees. alias: gd_km_azm().},
    H_LEAP => qq{is_leap( YEAR1 [,.. ] ). Leap year test: Returns 1 if YEAR is a leap year, 0 otherwise.},
    H_AOMN => qq{age_of_moon( Y, m, d ). Simple calculation of the age of the moon. Maximum deviation of about 2 days.},
    H_L2EP => qq{local2epoch( Y, m, d [, H, M, S ] ). Returns the local time in seconds since the epoch. alias: l2e().},
    H_G2EP => qq{gmt2epoch( Y, m, d [, H, M, S ] ). Returns the GMT time in seconds since the epoch. alias: g2e().},
    H_EP2L => qq{epoch2local( EPOCH ). Returns the local time. ( Y, m, d, H, M, S ). alias: e2l().},
    H_EP2G => qq{epoch2gmt( EPOCH ). Returns the GMT time. ( Y, m, d, H, M, S ). e2g().},
    H_SHMS => qq{sec2dhms( SECOND ) --Convert-to--> ( D, H, M, S ).},
    H_HMSS => qq{dhms2sec( D [, H, M, S ] ) --Convert-to--> ( SECOND ).},
    H_RI2M => qq{ri2meter( RI ) --Convert-to--> METER. alias: 里→メートル(), 里２メートル().},
    H_M2RI => qq{meter2ri( METER ) --Convert-to--> RI. alias: メートル→里(), メートル２里().},
    H_MI2M => qq{mile2meter( MILE ) --Convert-to--> METER. alias: マイル→メートル(), マイル２メートル().},
    H_M2MI => qq{meter2mile( METER ) --Convert-to--> MILE. alias: メートル→マイル(), メートル２マイル().},
    H_NM2M => qq{nautical_mile2meter( NAUTICAL_MILE ) --Convert-to--> METER. alias: 海里→メートル(), 海里２メートル().},
    H_M2NM => qq{meter2nautical_mile( METER ) --Convert-to--> NAUTICAL_MILE. alias: メートル→海里(), メートル２海里().},
    H_LB2G => qq{pound2gram( POUND ) --Convert-to--> GRAM. alias: ポンド→グラム(), ポンド２グラム().},
    H_G2LB => qq{gram2pound( GRAM ) --Convert-to--> POUND. alias: グラム→ポンド(), グラム２ポンド().},
    H_OZ2G => qq{ounce2gram( OUNCE ) -->Convert-to--> GRAM. alias: オンス→グラム(), オンス２グラム().},
    H_G2OZ => qq{gram2ounce( GRAM ) -->Convert-to--> OUNCE. alias: グラム→オンス(), グラム２オンス().},
    H_LPTM => qq{laptimer( LAPS ). Each time you press Enter, the split time is measured and the time taken to measure LAPS is returned. If LAPS is set to a negative value, the split time is not output. alias: lt().},
    H_TIMR => qq{timer( SECOND ). If you specify a value less than 31536000 (365 days x 86400 seconds) for SECOND, the countdown will begin and end when it reaches zero. If you specify a value greater than this, it will be recognized as an epoch second, and the countdown or countup will begin with that date and time as zero. In this case, the countup will continue without stopping at zero. In either mode, press Enter to end.},
    H_STWC => qq{stopwatch(). Measures the time until the Enter key is pressed. The measured time is displayed on the screen. alias: sw().},
    H_BPMR => qq{bpm( COUNT, SECOND ). Specify the number of beats as COUNT and the elapsed time as SECOND to calculate the BPM.},
    H_BPM1 => qq{bpm15(). Once you have confirmed 15 beats, press the Enter key. The BPM will be calculated from the elapsed time. The measured time is displayed on the screen.},
    H_BPM3 => qq{bpm30(). Once you have confirmed 30 beats, press the Enter key. The BPM will be calculated from the elapsed time. The measured time is displayed on the screen.},
    H_TACH => qq{tachymeter( SECOND ). Returns the number of units of work that can be completed per hour, where SECOND is the number of seconds required to complete one unit of work. Same as ratio_scaling( SECOND, 1, 3600 ).},
    H_TLMR => qq{telemeter( SECOND ). Measures distance using the difference in the speed of light and sound. Returns the distance equivalent to SECOND in meters. Same as telemeter_m().},
    H_TM_M => qq{telemeter_m( SECOND ). Measures distance using the difference in the speed of light and sound. Returns the distance equivalent to SECOND in meters. Same as telemeter().},
    H_TMKM => qq{telemeter_km( SECOND ). Measures distance using the difference in the speed of light and sound. Returns the distance equivalent to SECOND in kilometers. Same as telemeter_m() / 1000.},
};

%TableProvider::operators = (
    '+'                      => [    0, T_OPERATOR,     2, H_PLUS, sub{ $_[ 0 ] + $_[ 1 ] } ],
    '-'                      => [    1, T_OPERATOR,     2, H_MINU, sub{ $_[ 0 ] - $_[ 1 ] } ],
    '*'                      => [    2, T_OPERATOR,     2, H_MULT, sub{ $_[ 0 ] * $_[ 1 ] } ],
    '/'                      => [    3, T_OPERATOR,     2, H_DIVI, sub{ &_C_DIV( $_[ 0 ], $_[ 1 ] ) } ],
    '%'                      => [    4, T_OPERATOR,     2, H_MODU, sub{ &_C_MOD( $_[ 0 ], $_[ 1 ] ) } ],
    '**'                     => [    5, T_OPERATOR,     2, H_EXPO, sub{ $_[ 0 ] ** $_[ 1 ] } ],
    '|'                      => [    6, T_OPERATOR,     2, H_BWOR, sub{ $_[ 0 ] | $_[ 1 ] } ],
    '&'                      => [    7, T_OPERATOR,     2, H_BWAN, sub{ $_[ 0 ] & $_[ 1 ] } ],
    '^'                      => [    8, T_OPERATOR,     2, H_BWEO, sub{ $_[ 0 ] ^ $_[ 1 ] } ],
    '<<'                     => [    9, T_OPERATOR,     2, H_SHTL, sub{ $_[ 0 ] << $_[ 1 ] } ],
    '>>'                     => [   10, T_OPERATOR,     2, H_SHTR, sub{ $_[ 0 ] >> $_[ 1 ] } ],
    '~'                      => [   11, T_OPERATOR,     1, H_BWIV, sub{ ~( $_[ 0 ] ) } ],
    'fn('                    => [   12, T_OTHER,       -1, undef  ],
    '('                      => [   13, T_OPERATOR,     2, H_BBEG ],
    ','                      => [   14, T_OPERATOR,    -1, H_COMA ],
    ')'                      => [   15, T_OPERATOR,     2, H_BEND ],
    '='                      => [   16, T_OPERATOR,     1, H_EQUA ],
    'OPERAND'                => [   17, T_OTHER,        0, undef  ],
    'BEGIN'                  => [   18, T_OTHER,        0, undef  ],
    '#'                      => [   19, T_SENTINEL,    -1, undef  ],
    'testfunc'               => [   20, T_OTHER,        1, undef  ],
    'abs'                    => [ 1010, T_FUNCTION,    VA, H_ABS_, sub{ &_C_ABS( @_ ) } ],
    'int'                    => [ 1020, T_FUNCTION,    VA, H_INT_, sub{ &_C_INT( @_ ) } ],
    'floor'                  => [ 1030, T_FUNCTION,    VA, H_FLOR, sub{ &_C_FLOOR( @_ ) } ],
    'ceil'                   => [ 1040, T_FUNCTION,    VA, H_CEIL, sub{ &_C_CEIL( @_ ) } ],
    'rounddown'              => [ 1050, T_FUNCTION,    VA, H_RODD, sub{ &rounddown( @_ ) } ],
    'round'                  => [ 1060, T_FUNCTION,    VA, H_ROUD, sub{ &round( @_ ) } ],
    'roundup'                => [ 1070, T_FUNCTION,    VA, H_RODU, sub{ &roundup( @_ ) } ],
    'percentage'             => [ 1080, T_FUNCTION, '2-3', H_PCTG, sub{ &percentage( @_ ) } ],
    'ratio_scaling'          => [ 1090, T_FUNCTION, '3-4', H_RASC, sub{ &ratio_scaling( @_ ) } ],
    'is_prime'               => [ 1100, T_FUNCTION,    VA, H_PRIM, sub{ &is_prime( @_ ) } ],
    'prime_factorize'        => [ 1110, T_FUNCTION,     1, H_PRFR, sub{ &prime_factorize( $_[ 0 ] ) } ],
    'get_prime'              => [ 1120, T_FUNCTION,     1, H_GPRM, sub{ &get_prime_num( $_[ 0 ] ) } ],
    'gcd'                    => [ 1130, T_FUNCTION,    VA, H_GCD_, sub{ &Math::BigInt::bgcd( @_ ) } ],
    'lcm'                    => [ 1140, T_FUNCTION,    VA, H_LCM_, sub{ &Math::BigInt::blcm( @_ ) } ],
    'ncr'                    => [ 1150, T_FUNCTION,     2, H_NCHR, sub{ &nCr( $_[ 0 ], $_[ 1 ] ) } ],
    'min'                    => [ 1160, T_FUNCTION,    VA, H_MIN_, sub{ &List::Util::min( @_ ) } ],
    'max'                    => [ 1170, T_FUNCTION,    VA, H_MAX_, sub{ &List::Util::max( @_ ) } ],
    'shuffle'                => [ 1180, T_FUNCTION,    VA, H_SHFL, sub{ &List::Util::shuffle( @_ ) } ],
    'first'                  => [ 1190, T_FUNCTION,    VA, H_FRST, sub{ &_C_FIRST( @_ ) } ],
    'slice'                  => [ 1200, T_FUNCTION,    VA, H_SPLC, sub{ &_C_SLICE( @_ ) } ],
    'uniq'                   => [ 1210, T_FUNCTION,    VA, H_UNIQ, sub{ &List::Util::uniq( @_ ) } ],
    'sum'                    => [ 1220, T_FUNCTION,    VA, H_SUM_, sub{ &List::Util::sum( @_ ) } ],
    'prod'                   => [ 1230, T_FUNCTION,    VA, H_PROD, sub{ &prod( @_ ) } ],
    'avg'                    => [ 1240, T_FUNCTION,    VA, H_AVRG, sub{ &_C_AVG( @_ ) } ],
    'add_each'               => [ 1250, T_FUNCTION,    VA, H_ADEC, sub{ &add_each( @_ ) } ],
    'mul_each'               => [ 1260, T_FUNCTION,    VA, H_MLEC, sub{ &mul_each( @_ ) } ],
    'linspace'               => [ 1270, T_FUNCTION, '3-4', H_LNSP, sub{ &linspace( @_ ) } ],
    'linstep'                => [ 1280, T_FUNCTION,     3, H_LNST, sub{ &linstep( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) } ],
    'mul_growth'             => [ 1290, T_FUNCTION,     3, H_MLGT, sub{ &mul_growth( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) } ],
    'gen_fibo_seq'           => [ 1300, T_FUNCTION,     3, H_GFIS, sub{ &gen_fibo_seq( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) } ],
    'paper_size'             => [ 1310, T_FUNCTION, '1-2', H_PASZ, sub{ &paper_size( @_ ) } ],
    'rand'                   => [ 1320, T_FUNCTION,     1, H_RAND, sub{ rand( $_[ 0 ] ) } ],
    'exp'                    => [ 1330, T_FUNCTION,    VA, H_POEX, sub{ &_C_EXP( @_ ) } ],
    'exp2'                   => [ 1340, T_FUNCTION,    VA, H_EXP2, sub{ &_C_EXP2( @_ ) } ],
    'exp10'                  => [ 1350, T_FUNCTION,    VA, H_EP10, sub{ &_C_EXP10( @_ ) } ],
    'log'                    => [ 1360, T_FUNCTION,    VA, H_LOGA, sub{ &_C_LOG( @_ ) } ],
    'log2'                   => [ 1370, T_FUNCTION,    VA, H_LOG2, sub{ &_C_LOG2( @_ ) } ],
    'log10'                  => [ 1380, T_FUNCTION,    VA, H_LG10, sub{ &_C_LOG10( @_ ) } ],
    'sqrt'                   => [ 1390, T_FUNCTION,    VA, H_SQRT, sub{ &_C_SQRT( @_ ) } ],
    'pow'                    => [ 1400, T_FUNCTION,     2, H_POWE, sub{ $_[ 0 ] ** $_[ 1 ] } ],
    'pow_inv'                => [ 1410, T_FUNCTION,     2, H_PWIV, sub{ &pow_inv( $_[ 0 ], $_[ 1 ] ) } ],
    'rad2deg'                => [ 1420, T_FUNCTION,    VA, H_R2DG, sub{ &RAD2DEG( @_ ) } ],
    'deg2rad'                => [ 1430, T_FUNCTION,    VA, H_D2RD, sub{ &DEG2RAD( @_ ) } ],
    'dms2rad'                => [ 1440, T_FUNCTION,  '3M', H_DM2R, sub{ &DMS2RAD( @_ ) } ],
    'dms2deg'                => [ 1450, T_FUNCTION,  '3M', H_DEGM, sub{ &DMS2DEG( @_ ) } ],
    'deg2dms'                => [ 1460, T_FUNCTION,    VA, H_D2DM, sub{ &DEG2DMS( @_ ) } ],
    'dms2dms'                => [ 1470, T_FUNCTION,  '3M', H_DMDM, sub{ &DMS2DMS( @_ ) } ],
    'sin'                    => [ 1480, T_FUNCTION,     1, H_SINE, sub{ sin( $_[ 0 ] ) } ],
    'cos'                    => [ 1490, T_FUNCTION,     1, H_COSI, sub{ cos( $_[ 0 ] ) } ],
    'tan'                    => [ 1500, T_FUNCTION,     1, H_TANG, sub{ &Math::Trig::tan( $_[ 0 ] ) } ],
    'asin'                   => [ 1510, T_FUNCTION,     1, H_ASIN, sub{ &Math::Trig::asin( $_[ 0 ] ) } ],
    'acos'                   => [ 1520, T_FUNCTION,     1, H_ACOS, sub{ &Math::Trig::acos( $_[ 0 ] ) } ],
    'atan'                   => [ 1530, T_FUNCTION,     1, H_ATAN, sub{ &Math::Trig::atan( $_[ 0 ] ) } ],
    'atan2'                  => [ 1540, T_FUNCTION,     2, H_ATN2, sub{ &Math::Trig::atan2( $_[ 0 ], $_[ 1 ] ) } ],
    'hypot'                  => [ 1550, T_FUNCTION,     2, H_HYPT, sub{ &POSIX::hypot( $_[ 0 ], $_[ 1 ] ) } ],
    'angle_deg'              => [ 1560, T_FUNCTION, '2-3', H_SLPD, sub{ &angle_deg( @_ ) } ],
    'dist_between_points'    => [ 1570, T_FUNCTION, '4-6', H_DIST, sub{ &dist_between_points( @_ ) } ],
    'midpt_between_points'   => [ 1580, T_FUNCTION, '4-6', H_MIDP, sub{ &midpt_between_points( @_ ) } ],
    'angle_between_points'   => [ 1590, T_FUNCTION, '4-7', H_ANGL, sub{ &angle_between_points( @_ ) } ],
    'geo_radius'             => [ 1600, T_FUNCTION,     1, H_GERA, sub{ &geocentric_radius( $_[ 0 ] ) } ],
    'radius_of_lat'          => [ 1610, T_FUNCTION,     1, H_LATC, sub{ &radius_of_latitude_circle( $_[ 0 ] ) } ],
    'geo_distance'           => [ 1620, T_FUNCTION,     4, H_GDIS, sub{ &geo_distance_m( $_[ 0 ], $_[ 1 ], $_[ 2 ], $_[ 3 ] ) } ],
    'geo_distance_m'         => [ 1630, T_FUNCTION,     4, H_GDIM, sub{ &geo_distance_m( $_[ 0 ], $_[ 1 ], $_[ 2 ], $_[ 3 ] ) } ],
    'geo_distance_km'        => [ 1640, T_FUNCTION,     4, H_GDKM, sub{ &geo_distance_km( $_[ 0 ], $_[ 1 ], $_[ 2 ], $_[ 3 ] ) } ],
    'geo_azimuth'            => [ 1650, T_FUNCTION,     4, H_GDEG, sub{ &geo_azimuth( $_[ 0 ], $_[ 1 ], $_[ 2 ], $_[ 3 ] ) } ],
    'geo_dist_m_and_azimuth' => [ 1660, T_FUNCTION,     4, H_DD_M, sub{ &geo_dist_m_and_azimuth( $_[ 0 ], $_[ 1 ], $_[ 2 ], $_[ 3 ] ) } ],
    'geo_dist_km_and_azimuth'=> [ 1670, T_FUNCTION,     4, H_DDKM, sub{ &geo_dist_km_and_azimuth( $_[ 0 ], $_[ 1 ], $_[ 2 ], $_[ 3 ] ) } ],
    'is_leap'                => [ 1680, T_FUNCTION,    VA, H_LEAP, sub{ &is_leap( @_ ) } ],
    'age_of_moon'            => [ 1690, T_FUNCTION,     3, H_AOMN, sub{ &age_of_moon( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) } ],
    'local2epoch'            => [ 1700, T_FUNCTION, '3-6', H_L2EP, sub{ &local2epoch( @_ ) } ],
    'gmt2epoch'              => [ 1710, T_FUNCTION, '3-6', H_G2EP, sub{ &gmt2epoch( @_ ) } ],
    'epoch2local'            => [ 1720, T_FUNCTION,     1, H_EP2L, sub{ &epoch2local( $_[ 0 ] ) } ],
    'epoch2gmt'              => [ 1730, T_FUNCTION,     1, H_EP2G, sub{ &epoch2gmt( $_[ 0 ] ) } ],
    'sec2dhms'               => [ 1740, T_FUNCTION,     1, H_SHMS, sub{ &sec2dhms( $_[ 0 ] ) } ],
    'dhms2sec'               => [ 1750, T_FUNCTION, '1-4', H_HMSS, sub{ &dhms2sec( @_ ) } ],
    'ri2meter'               => [ 1760, T_FUNCTION,     1, H_RI2M, sub{ &ri2meter( $_[ 0 ] ) } ],
    'meter2ri'               => [ 1770, T_FUNCTION,     1, H_M2RI, sub{ &meter2ri( $_[ 0 ] ) } ],
    'mile2meter'             => [ 1780, T_FUNCTION,     1, H_MI2M, sub{ &mile2meter( $_[ 0 ] ) } ],
    'meter2mile'             => [ 1790, T_FUNCTION,     1, H_M2MI, sub{ &meter2mile( $_[ 0 ] ) } ],
    'nautical_mile2meter'    => [ 1800, T_FUNCTION,     1, H_NM2M, sub{ &nautical_mile2meter( $_[ 0 ] ) } ],
    'meter2nautical_mile'    => [ 1810, T_FUNCTION,     1, H_M2NM, sub{ &meter2nautical_mile( $_[ 0 ] ) } ],
    'pound2gram'             => [ 1820, T_FUNCTION,     1, H_LB2G, sub{ &pound2gram( $_[ 0 ] ) } ],
    'gram2pound'             => [ 1830, T_FUNCTION,     1, H_G2LB, sub{ &gram2pound( $_[ 0 ] ) } ],
    'ounce2gram'             => [ 1840, T_FUNCTION,     1, H_OZ2G, sub{ &ounce2gram( $_[ 0 ] ) } ],
    'gram2ounce'             => [ 1850, T_FUNCTION,     1, H_G2OZ, sub{ &gram2ounce( $_[ 0 ] ) } ],
    'laptimer'               => [ 1860, T_FUNCTION,     1, H_LPTM, sub{ &laptimer( $_[ 0 ] ) } ],
    'timer'                  => [ 1870, T_FUNCTION,     1, H_TIMR, sub{ &timer( $_[ 0 ] ) } ],
    'stopwatch'              => [ 1880, T_FUNCTION,     0, H_STWC, sub{ &stopwatch() } ],
    'bpm'                    => [ 1890, T_FUNCTION,     2, H_BPMR, sub{ &bpm( $_[ 0 ], $_[ 1 ] ) } ],
    'bpm15'                  => [ 1900, T_FUNCTION,     0, H_BPM1, sub{ &bpm15() } ],
    'bpm30'                  => [ 1910, T_FUNCTION,     0, H_BPM3, sub{ &bpm30() } ],
    'tachymeter'             => [ 1920, T_FUNCTION,     1, H_TACH, sub{ &tachymeter( $_[ 0 ] ) } ],
    'telemeter'              => [ 1930, T_FUNCTION,     1, H_TLMR, sub{ &telemeter( $_[ 0 ] ) } ],
    'telemeter_m'            => [ 1940, T_FUNCTION,     1, H_TM_M, sub{ &telemeter_m( $_[ 0 ] ) } ],
    'telemeter_km'           => [ 1950, T_FUNCTION,     1, H_TMKM, sub{ &telemeter_km( $_[ 0 ] ) } ],
);

sub IsOperatorExists( $ )
{
    my $operator = $_[ 0 ];
    return &IsDefinitionExists( $operator, T_OPERATOR );
}

sub IsFunctionExists( $ )
{
    my $operator = $_[ 0 ];
    return &IsDefinitionExists( $operator, T_FUNCTION );
}

sub IsDefinitionExists( $ )
{
    my $operator = $_[ 0 ];
    my $type = $_[ 1 ];
    my $ret_val = 0;
    if( defined( $TableProvider::operators{ $operator } ) ){
        my $ope_type = $TableProvider::operators{ $operator }[ O_TYPE ];
        if( $ope_type & ( $type | T_OTHER ) ){
            $ret_val = 1;
        }
    }
    return $ret_val;
}

sub GetOperatorsInfo( $$ )
{
    my $operator = $_[ 0 ];
    my $column = $_[ 1 ];

    my $ret_val = undef;

    if( &IsDefinitionExists( $operator, ( T_OPERATOR | T_FUNCTION | T_SENTINEL ) ) ){
        if( defined( $TableProvider::operators{ $operator }[ $column ] ) ){
            $ret_val = $TableProvider::operators{ $operator }[ $column ];
        }
    }

    return $ret_val;
}

sub GetAllOperatorsList()
{
    my @array = sort{
        $TableProvider::operators{ $a }[ O_INDX ] <=> $TableProvider::operators{ $b }[ O_INDX ]
        }keys( %TableProvider::operators );
    return @array;
}

sub FilterOperatorsList( $ )
{
    my $filter = shift( @_ );
    my @array = ();
    for my $f( &GetAllOperatorsList() ){
        if( $TableProvider::operators{ $f }[ O_TYPE ] & $filter ){
            push( @array, $f );
        }
    }
    return @array;
}

sub GetOperatorsList()
{
    return &FilterOperatorsList( T_OPERATOR );
}

sub GetFunctionsList()
{
    return &FilterOperatorsList( T_FUNCTION );
}

sub GetTokenTblIdx( $ )
{
    my $ope = $_[ 0 ];

    ## ここでは関数名は共通名'fn('として扱う
    $ope = 'fn(' if( $ope =~ m/^.+\($/o );

    my $ret_val = &GetOperatorsInfo( $ope, O_INDX );

    return $ret_val;
}

sub GetArgc( $ )
{
    my $ope = $_[ 0 ];

    my $ret_val = &GetOperatorsInfo( $ope, O_ARGC );

    return $ret_val;
}

sub GetHelp( $ )
{
    my $ope = $_[ 0 ];

    my $ret_val = &GetOperatorsInfo( $ope, O_HELP );

    return $ret_val;
}

sub GetSubroutine( $ )
{
    my $ope = $_[ 0 ];

    my $ret_val = &GetOperatorsInfo( $ope, O_SUBR );

    return $ret_val;
}

sub IsSentinel( $ )
{
    my $ope = $_[ 0 ];

    my $bSentinel = 0;
    my $ope_type = &GetOperatorsInfo( $ope, O_TYPE );
    if( defined( $ope_type ) && $ope_type == T_SENTINEL ){
        $bSentinel = 1;
    }

    return $bSentinel;
}

sub _C_DIV( $$ )
{
    if( $_[1] == 0 ){
        die( qq{"$_[0] / $_[1]": Illegal division by zero.\n} );
    }
    return $_[ 0 ] / $_[ 1 ];
}

sub _C_MOD( $$ )
{
    if( $_[1] == 0 ){
        return $_[ 0 ];
    }elsif( -1 < $_[ 1 ] && $_[ 1 ] < 1 ){
        die( qq{"$_[0] \% $_[1]": Illegal modulus operand.\n} );
    }
    return $_[ 0 ] % $_[ 1 ];
}

sub _C_ABS( @ )
{
    my @ret_vals = ();
    for my $arg( @_ ){
        push( @ret_vals, abs( $arg ) );
    }
    return @ret_vals;
}

sub _C_INT( @ )
{
    my @ret_vals = ();
    for my $arg( @_ ){
        push( @ret_vals, int( $arg ) );
    }
    return @ret_vals;
}

sub _C_FLOOR( @ )
{
    my @ret_vals = ();
    for my $arg( @_ ){
        push( @ret_vals, &POSIX::floor( $arg ) );
    }
    return @ret_vals;
}

sub _C_CEIL( @ )
{
    my @ret_vals = ();
    for my $arg( @_ ){
        push( @ret_vals, &POSIX::ceil( $arg ) );
    }
    return @ret_vals;
}

sub rounddown( @ )
{
    my $argc = scalar( @_ );
    if( $argc < 2 ){
        die( qq{rounddown(): \$argc=$argc: Insufficient arguments.\n} );
    }
    return &round_rf( @_, 0 );
}

sub round( @ )
{
    my $argc = scalar( @_ );
    if( $argc < 2 ){
        die( qq{round(): \$argc=$argc: Insufficient arguments.\n} );
    }
    return &round_rf( @_, 0.5 );
}

sub roundup( @ )
{
    my $argc = scalar( @_ );
    if( $argc < 2 ){
        die( qq{roundup(): \$argc=$argc: Insufficient arguments.\n} );
    }
    return &round_rf( @_, 1 );
}

sub round_rf( @ )
{
    my $rounding_factor = pop( @_ );
    my $digit = pop( @_ );

    my @ret_vals = ();
    for my $value( @_ ){
        my $carry_factor = 10 ** $digit;
        my $rd_factor = $rounding_factor;
        $rd_factor *= -1 if( $value < 0 );
        my $carried_num = $value * $carry_factor + $rd_factor;
        my $integer = int( $carried_num );
        $integer -= $rd_factor if( $rounding_factor == 1 && $carried_num == $integer );
        #print( qq{\$value=$value, \$rd_factor=$rd_factor, \$carried_num=$carried_num, \$integer=$integer\n} );
        push( @ret_vals, $integer / $carry_factor );
    }

    return @ret_vals;
}

sub percentage( $$;$ )
{
    my $numerator = shift( @_ );
    my $denominator = shift( @_ );
    my $decimal_places = undef;
    $decimal_places = shift( @_ ) if( defined( $_[ 0 ] ) );
    my $ret_value = $numerator * 100 / $denominator;
    if( defined( $decimal_places ) ){
        $ret_value = ( &round( $ret_value, $decimal_places ) )[ 0 ];
    }
    return $ret_value;
}

sub ratio_scaling( $$$;$ )
{
    my $number_of_observations = shift( @_ );
    my $observation_unit = shift( @_ );
    my $number_of_targets = shift( @_ );
    my $decimal_places = shift( @_ );
    my $forecast_quantity = ( $number_of_targets *
        $observation_unit / $number_of_observations );
    if( defined( $decimal_places ) ){
        $forecast_quantity = ( &round( $forecast_quantity, $decimal_places ) )[ 0 ];
    }
    return $forecast_quantity;
}

sub is_prime_num( $ )
{
    my $targ_num = shift( @_ );

    ## 2未満の数は素数ではない
    return 0 if( $targ_num < 2 );
    ## 2は素数
    return 1 if( $targ_num == 2 );
    ## 2以外の偶数は素数ではない
    return 0 if( !( $targ_num & 0x1 ) );
#    return 0 if( ( $targ_num & 0x1 ) ^ 0x1 );

    ## 3から$targ_numの平方根まで奇数で割ってみる
    for( my $i=3; $i * $i <= $targ_num; $i += 2 ){
        ## 割り切れたら素数ではない
        return 0 if( $targ_num % $i == 0 );
    }
    ## 割り切れる数がなければ素数
    return 1;
}

sub is_prime( @ )
{
    my @ret_vals = ();
    for my $num( @_ ){
        push( @ret_vals, &is_prime_num( $num ) );
    }
    return @ret_vals;
}

sub prime_factorize( $ )
{
    my $targ_num = shift( @_ );
    if( $targ_num < 2 ){
        die( qq{prime_factorize: $targ_num: Cannot be less than 2.\n} );
    }
    if( $targ_num != int( $targ_num ) ){
        die( qq{prime_factorize: $targ_num: Decimals cannot be specified.\n} );
    }

    my @factors = ();

    ## 2で割れるだけ割る
    while( $targ_num % 2 == 0 ){
        push( @factors, 2 );
        $targ_num /= 2;
    }

    ## 3から$targ_numの平方根まで奇数で割っていく
    for( my $i=3; $i * $i <= $targ_num; $i += 2 ){
        while( $targ_num % $i == 0 ){
            push( @factors, $i );
            $targ_num /= $i;
        }
    }

    ## 残った数が1でない場合は素数
    if( $targ_num > 1 ){
        push( @factors, $targ_num );
    }

    return @factors;
}

sub get_prime_num( $ )
{
    my $bit_width = shift( @_ );
    if( $bit_width != int( $bit_width ) ){
        die( qq{get_prime: $bit_width: Decimals cannot be specified.\n} );
    }
    if( $bit_width < 4 ){
        die( qq{get_prime: $bit_width: Cannot specify a value less than 4.\n} );
    }
    if( $bit_width > 32 ){
        die( qq{get_prime: $bit_width: Cannot specify a value greater than 32.\n} );
    }

#    my $max = ( 1 << $bit_width );
    my $max = ( 2 ** $bit_width );  ## 32bit環境でオーバーフローさせない
    #printf( qq{\$max="$max" [ 0x%08X ]\n}, $max );
    while( 1 ){
        my $random = int( rand( $max ) );
        ## 偶数なら素数ではないので奇数にする
        $random |= 0x1;
        my $end = ( $random | 0x3 );
        #printf( qq{0x%08X - 0x%08X\n}, $random, $end );
        for( my $num=$random; $num<=$end; $num+=2 ){
            return $num if( &is_prime_num( $num ) );
        }
    }
}

sub nCr( $$ )
{
    my( $n, $r ) = @_;
    if( ( $n < 0 ) || ( $n != int( $n ) ) ){
        die( qq{nCr( $n, $r ): N[=$n] must be a non-negative integer.\n} );
    }
    if( ( $r <= 0 ) || ( $r != int( $r ) ) ){
        die( qq{nCr( $n, $r ): R[=$r] must be a positive integer.\n} );
    }
    my @numerator_array = &linstep( $n, -1, $r );
    my @denominator_array = &linstep( $r, -1, $r );
    my $numerator = &prod( @numerator_array );
    my $denominator = &prod( @denominator_array );
    my $res = $numerator / $denominator;
    return $res;
}

sub _C_FIRST( @ )
{
    return $_[ 0 ];
}

sub _C_SLICE( @ )
{
    my @argv = @_;
    my $argc = scalar( @argv );
    if( $argc <= 3 ){
        die( qq{slice: \$argc=$argc: Not enough arguments.\n} );
    }
    my $length = pop( @argv );
    my $offset = pop( @argv );
    $argc = scalar( @argv );
    #print( qq{\$argc=$argc, \$offset=$offset, \$length=$length\n} );
    if( $offset != int( $offset ) ){
        die( qq{slice: \$offset=$offset: \$offset cannot be a decimal number.\n} );
    }
    if( $length != int( $length ) ){
        die( qq{slice: \$length=$length: \$length cannot be a decimal number.\n} );
    }
    if( $offset < 0 ){
        $offset = $argc + $offset;
        #print( qq{\$offset=$offset\n} );
    }
    if( ( $offset + 1 ) > $argc ){
        die( qq{slice: \$offset=$offset, \$argc=$argc: \$offset is large.\n} );
    }
    if( $length <= 0 ){
        die( qq{slice: \$length=$length: \$length must be greater than 0.\n} );
    }
    if( $length > ( $argc - $offset ) ){
        $TableProvider::opf->warnPrint( qq{\$length=$length: Decrease the value of \$length.\n} );
        $length = $argc - $offset;
    }
    #print( qq{\$argc=$argc, \$offset=$offset, \$length=$length\n} );

    my @ret_vals = splice( @argv, $offset, $length );

    return @ret_vals;
}

sub prod( @ )
{
    my $product = 1;
    for my $arg( @_ ){
        $product *= $arg;
    }
    return $product;
}

sub _C_AVG( @ )
{
    my $total = List::Util::sum( @_ );
    my $len = scalar( @_ );
    return $total / $len;
}

sub add_each( @ )
{
    my $argc = scalar( @_ );
    if( $argc < 2 ){
        die( qq{add_each(): \$argc=$argc: Insufficient number of arguments.\n} );
    }
    my $delta = pop( @_ );
    my @ret_vals = ();
    for my $operand( @_ ){
        push( @ret_vals, $operand + $delta );
    }
    return @ret_vals;
}

sub mul_each( @ )
{
    my $argc = scalar( @_ );
    if( $argc < 2 ){
        die( qq{mul_each(): \$argc=$argc: Insufficient number of arguments.\n} );
    }
    my $factor = pop( @_ );
    my @ret_vals = ();
    for my $operand( @_ ){
        push( @ret_vals, $operand * $factor );
    }
    return @ret_vals;
}

# 機能: 初期値、終了値、数列サイズに基づき、等間隔の数値リストを生成する
# 引数: $start (初期値), $end (終了値), $length (数列サイズ),
#       $bRound (省略可: 真値なら整数に丸める, デフォルトは丸めない)
sub linspace( $$$;$ )
{
    my( $start, $end, $length, $decimal_places ) = @_;
    if( $length < 2 ){
        die( qq{linspace(): \$length[=$length] is less than 2.\n} );
    }
    if( $length != int( $length ) ){
        die( qq{linspace(): \$length[=$length] is a decimal number.\n} );
    }

    my $interval = ( $end - $start ) / ( $length - 1 );
    my $value = $start;
    my @ret_vals = ( $value );
    my $counter = $length - 2;
    my $idx = 1;
    while( $counter-- ){
        $value = $start + ( $interval * $idx++ );

        # 第4引数 $decimal_places の桁で丸める
        if( defined( $decimal_places ) ){
            $value = ( &round( $value, $decimal_places ) )[ 0 ];
        }

        push( @ret_vals, $value );
    }
    push( @ret_vals, $end );

    return @ret_vals;
}

# 機能: 開始値、ステップ幅、繰り返し回数に基づき、等間隔の数値リストを生成する。
sub linstep( $$$ )
{
    my( $start, $step, $length ) = @_;
    if( $length < 1 ){
        die( qq{linstep(): \$length[=$length] is less than 1.\n} );
    }
    if( $length != int( $length ) ){
        die( qq{linstep(): \$length[=$length] is a decimal number.\n} );
    }

    my $value = $start;
    my @ret_vals = ( $value );
    my $counter = $length - 1;
    while( $counter-- ){
        $value += $step;
        push( @ret_vals, $value );
    }

    return @ret_vals;
}

sub mul_growth( $$$ )
{
    my( $start, $factor, $length ) = @_;
    if( $length < 1 ){
        die( qq{mul_growth(): \$length[=$length] is less than 1.\n} );
    }
    if( $length != int( $length ) ){
        die( qq{mul_growth(): \$length[=$length] is a decimal number.\n} );
    }

    my @ret_vals = ( $start );
    my $counter = $length - 1;
    while( $counter-- ){
        unshift( @ret_vals, $ret_vals[ 0 ] * $factor );
    }

    return reverse( @ret_vals );
}

## gen_fibo_seq()
##
##  「一般化フィボナッチ数列（Generalized Fibonacci Sequence）」を生成する。
##  $length は2以上の整数。
##  $a と $b から始まり、サイズが $length の配列を返します。
##
## フィボナッチ数列 [ Fibonacci sequence ]
## 最初の2つの数字（通常は1と1、または0と1）から始まり、
## それ以降の数字は直前の2つの数字の和になるという数列。
## 数が増えるにつれて、隣り合う項の比が黄金比 1.618 に限りなく近づきます。
sub gen_fibo_seq( $$$ )
{
    my( $a, $b, $length ) = @_;
    if( $length < 2 ){
        die( qq{gen_fibo_seq(): \$length[=$length] is less than 2.\n} );
    }
    if( $length != int( $length ) ){
        die( qq{gen_fibo_seq(): \$length[=$length] is a decimal number.\n} );
    }

    my @ret_vals = ( $b, $a );
    my $counter = $length - 2;
    while( $counter-- ){
        unshift( @ret_vals, $ret_vals[ 0 ] + $ret_vals[ 1 ] );
    }

    return reverse( @ret_vals );
}

## paper_size()
##
## paper_size( SIZE [, TYPE ] ).
## Returns the following information in this order:
## length of short side, length of long side (in mm).
## SIZE is a positive integer.
## If TYPE is omitted or 0 is specified, it will be A size.
## If TYPE is specified, it will be B size ( Japan's unique standards ).
##
sub paper_size( $$ )
{
    my( $size, $type ) = @_;
    if( $size < 0 ){
        die( qq{paper_size(): \$size[=$size] is negative.\n} );
    }
    if( $size != int( $size ) ){
        die( qq{paper_size(): \$size[=$size] is a decimal number.\n} );
    }

    my $paper_type = 'A';
    my $long_side  = 1189;
    my $short_side =  841;
    ## B判の場合
    if( defined( $type ) && $type == 1 ){
        $paper_type = 'B';
        ## B判はA判の面積の1.5倍という思想。計算で出すなら以下のようになる。
        ## $long_side  = &POSIX::floor( $long_side * sqrt( 1.5 ) );
        ## $short_side = &POSIX::floor( $short_side * sqrt( 1.5 ) );
        $long_side  = 1456;
        $short_side = 1030;
    }

    my $counter = $size;
    my $bWarnLongSide = 1;
    my $bWarnShortSide = 1;
    while( $counter-- ){
        my $paper_size = $paper_type . ( $size - $counter );
        my $short_side_next = &POSIX::floor( $long_side / 2 );
        $long_side = $short_side;
        if( $long_side == 0 && $bWarnLongSide ){
            $bWarnLongSide = 0;
            warn( qq{paper_size(): $paper_size: The long side reaches 0 mm.\n} );
        }
        $short_side = $short_side_next;
        if( $short_side == 0 && $bWarnShortSide ){
            $bWarnShortSide = 0;
            warn( qq{paper_size(): $paper_size: The short side reaches 0 mm.\n} );
        }
    }

    my @ret_vals = ( $short_side, $long_side );
    return @ret_vals;
}

sub _C_EXP( @ )
{
    my @ret_vals = ();
    for my $arg( @_ ){
        push( @ret_vals, exp( $arg ) );
    }
    return @ret_vals;
}

sub _C_EXP2( @ )
{
    my @ret_vals = ();
    for my $arg( @_ ){
        #my $val = exp( $arg * log( 2 ) );
        my $val = 2 ** $arg;
        push( @ret_vals, $val );
    }
    return @ret_vals;
}

sub _C_EXP10( @ )
{
    my @ret_vals = ();
    for my $arg( @_ ){
        #my $val = exp( $arg * log( 10 ) );
        my $val = 10 ** $arg;
        push( @ret_vals, $val );
    }
    return @ret_vals;
}

sub _C_LOG( @ )
{
    my @ret_vals = ();
    for my $arg( @_ ){
        if( $arg <= 0 ){
            die( qq{log( $arg ): Must be a positive number.\n} );
        }
        push( @ret_vals, log( $arg ) );
    }
    return @ret_vals;
}

sub _C_LOG2( @ )
{
    my @ret_vals = ();
    for my $arg( @_ ){
        if( $arg <= 0 ){
            die( qq{log2( $arg ): Must be a positive number.\n} );
        }
        push( @ret_vals, log( $arg ) / log( 2 ) );
    }
    return @ret_vals;
}

sub _C_LOG10( @ )
{
    my @ret_vals = ();
    for my $arg( @_ ){
        if( $arg <= 0 ){
            die( qq{log10( $arg ): Must be a positive number.\n} );
        }
        push( @ret_vals, log( $arg ) / log( 10 ) );
    }
    return @ret_vals;
}

sub _C_SQRT( @ )
{
    my @ret_vals = ();
    for my $arg( @_ ){
        push( @ret_vals, sqrt( $arg ) );
    }
    return @ret_vals;
}

sub pow_inv( $$ )
{
    my( $n, $x ) = @_;
    my $y = log( $n ) / log( $x );
    my $rounded = int( $y + 0.5 );  # 四捨五入
    return ( $x ** $rounded == $n ) ? $rounded : $y;
}

sub RAD2DEG( @ )
{
    my @deg_array = ();
    for my $rad( @_ ){
        #print( qq{\$rad="$rad"\n} );
        my $deg = &Math::Trig::rad2deg( $rad );
        push( @deg_array, $deg );
    }
    return $deg_array[ 0 ] if( scalar( @deg_array ) == 1 );
    return @deg_array;
}

sub DEG2RAD( @ )
{
    my @rad_array = ();
    for my $deg( @_ ){
        #print( qq{\$deg="$deg"\n} );
        my $rad = &Math::Trig::deg2rad( $deg );
        push( @rad_array, $rad );
    }
    return $rad_array[ 0 ] if( scalar( @rad_array ) == 1 );
    return @rad_array;
}

sub DMS2RAD( $$$ )
{
    my @rad_array = ();
    while( defined( $_[ 0 ] ) ){
        my $degrees = shift( @_ );
        my $min = shift( @_ );
        my $sec = shift( @_ );
        my $rad = &Math::Trig::deg2rad( &DMS2DEG( $degrees, $min, $sec ) );
        push( @rad_array, $rad );
    }
    return $rad_array[ 0 ] if( scalar( @rad_array ) == 1 );
    return @rad_array;
}

sub DMS2DEG( $$$ )
{
    my @deg_array = ();
    while( defined( $_[ 0 ] ) ){
        my $degrees = shift( @_ );
        my $min = shift( @_ );
        my $sec = shift( @_ );
        my $deg = $degrees + ( $min / 60 ) + ( $sec / 3600 );
        push( @deg_array, $deg );
    }
    return $deg_array[ 0 ] if( scalar( @deg_array ) == 1 );
    return @deg_array;
}

sub DEG2DMS( $ )
{
    my @dms_array = ();
    while( defined( $_[ 0 ] ) ){
        my $deg = shift( @_ );
        my $d = int( $deg );
        $d = '-0' if( $d == 0 && $deg < 0 );
        my $m_raw = ( $deg - $d ) * 60;
        my $m = int( $m_raw );
        my $s = ( $m_raw - $m ) * 60;
        push( @dms_array, $d, $m, $s );
    }
    return @dms_array;
}

sub DMS2DMS( $$$ )
{
    my @dms_array = ();
    while( defined( $_[ 0 ] ) ){
        my $degrees = shift( @_ );
        my $min = shift( @_ );
        my $sec = shift( @_ );
        my $d = int( $degrees );
        $d = '-0' if( $d == 0 && $degrees < 0 );
        my $m_raw = ( ( $degrees - $d ) * 60 ) + $min;
        my $m = int( $m_raw );
        my $s = ( ( $m_raw - $m ) * 60 ) + $sec;
        push( @dms_array, $d, $m, $s );
    }
    return @dms_array;
}

sub angle_deg( $$;$ )
{
    my( $x, $y, $is_azimuth ) = @_;
    if( !defined( $is_azimuth ) ){
        $is_azimuth = 0;
    }
    my $degree = ( &angle_between_points( 0, 0, $x, $y, $is_azimuth ) )[ 0 ];
    return $degree;
}

sub dist_between_points( $$$$;$$ )
{
    my $argc = scalar( @_ );
    my $b3d = 0;
    if( $argc == 5 ){
        die( qq{dist_between_points: \$argc=$argc: Invalid number of arguments.\n} );
    }elsif( $argc == 6 ){
        $b3d = 1;
    }

    my $ret_val = 0;
    if( $b3d ){
        my( $p1x, $p1y, $p1z, $p2x, $p2y, $p2z ) = @_;
        $ret_val = sqrt( ( ( $p2x - $p1x ) ** 2 ) +
                         ( ( $p2y - $p1y ) ** 2 ) +
                         ( ( $p2z - $p1z ) ** 2 ) );
    }else{
        my( $p1x, $p1y, $p2x, $p2y ) = @_;
        $ret_val = sqrt( ( ( $p2x - $p1x ) ** 2 ) +
                         ( ( $p2y - $p1y ) ** 2 ) );
    }

    return $ret_val;
}

sub midpt_between_points( $$$$;$$ )
{
    my $argc = scalar( @_ );
    my $b3d = 0;
    if( $argc == 5 ){
        die( qq{midpt_between_points: \$argc=$argc: Invalid number of arguments.\n} );
    }elsif( $argc == 6 ){
        $b3d = 1;
    }

    my @ret_val = ();
    if( $b3d ){
        my( $p1x, $p1y, $p1z, $p2x, $p2y, $p2z ) = @_;
        my $px1c2 = $p1x + ( ( $p2x - $p1x ) / 2 );
        my $py1c2 = $p1y + ( ( $p2y - $p1y ) / 2 );
        my $pz1c2 = $p1z + ( ( $p2z - $p1z ) / 2 );
        @ret_val = ( $px1c2, $py1c2, $pz1c2 );
    }else{
        my( $p1x, $p1y, $p2x, $p2y ) = @_;
        my $px1c2 = $p1x + ( ( $p2x - $p1x ) / 2 );
        my $py1c2 = $p1y + ( ( $p2y - $p1y ) / 2 );
        @ret_val = ( $px1c2, $py1c2 );
    }

    return @ret_val;
}

#引数4個: angle_between_points( X1, Y1, X2, Y2 ) => BEARING [ East is 0 degrees, CCW ]
#引数5個: angle_between_points( X1, Y1, X2, Y2, IS_AZIMUTH ) => IS_AZIMUTHに従った角度]
#引数6個: angle_between_points( X1, Y1, Z1, X2, Y2, Z2 ) => ( AZIMUTH, ELEVATION ) [ East is 0 degrees, CCW ]
#引数7個: angle_between_points( X1, Y1, Z1, X2, Y2, Z2, IS_AZIMUTH ) => ( AZIMUTH, ELEVATION ) [ East is 0 degrees, CCW ]
sub angle_between_points( $$$$;$$$ )
{
    my $argc = scalar( @_ );
    my $b3d = 0;
    if( $argc == 6 || $argc == 7 ){
        $b3d = 1;
    }

    my( $p1x, $p1y, $p1z, $p2x, $p2y, $p2z, $is_azimuth ) = ();
    my $elevation = undef;
    my @ret_val = ();
    if( $b3d ){
        ( $p1x, $p1y, $p1z, $p2x, $p2y, $p2z, $is_azimuth ) = @_;
        my $hypotenuse_x_y = &dist_between_points( $p1x, $p1y, $p2x, $p2y );
        $elevation = rad2deg( atan2( $p2z - $p1z, $hypotenuse_x_y ) );
        unshift( @ret_val, $elevation );
    }else{
        ( $p1x, $p1y, $p2x, $p2y, $is_azimuth ) = @_;
    }

    my $bearing = rad2deg( atan2( $p2y - $p1y, $p2x - $p1x ) );
    if( defined( $is_azimuth ) ){
        if( $is_azimuth ){
            $bearing = 90 - $bearing;
        }
    }

    unshift( @ret_val, $bearing );

    return @ret_val;
}

# === 地球の中心から地表までの動径を計算する関数 ===
# 引数: 緯度（ラジアン）
# 戻り値: 動径 (メートル)
sub geocentric_radius( $ )
{
    my $latitude_rad = shift( @_ );

    my $sin_lat = sin( $latitude_rad );
    my $cos_lat = cos( $latitude_rad );

    # 正確な動径Rを求める公式
    my $numerator = ( GRS80_EQUATORIAL_RADIUS_M ** 2 * $cos_lat ) ** 2 + ( GRS80_POLAR_RADIUS_M ** 2 * $sin_lat ) ** 2;
    my $denominator = (GRS80_EQUATORIAL_RADIUS_M * $cos_lat ) ** 2 + ( GRS80_POLAR_RADIUS_M * $sin_lat ) ** 2;
    my $R = sqrt( $numerator / $denominator );

    return $R;
}

# === 任意の緯度における緯線の半径を計算する関数 ===
# 引数: 緯度（ラジアン）
# 戻り値: 緯線の半径 (メートル)
sub radius_of_latitude_circle( $ )
{
    my $latitude_rad = shift( @_ );

    my $sin_lat = sin( $latitude_rad );
    my $cos_lat = cos( $latitude_rad );

    # これは、動径 R とは異なり、極軸からの距離 r = x座標 に相当します。
    # GRS80楕円体における緯円の半径を求めるには、媒介変数表示から導出される式が必要です。
    # ここでは、簡略化のため、動径Rにcos(lat)を掛けるのではなく、正確な楕円体のx座標を求めます。
    # 楕円体の媒介変数表示 x = a * cos(phi) / sqrt(1 + e^2 * sin^2(phi) / cos^2(phi)) ... は複雑です。
    # 緯円の半径は、その地点の卯酉線曲率半径Nとcos(phi)の積 N * cos(phi) で求めるのが標準的です。

    # 卯酉線曲率半径 N を計算
    my $W = sqrt( 1 - GRS80_E_SQ * $sin_lat ** 2 );
    my $N = GRS80_EQUATORIAL_RADIUS_M / $W;

    my $r = $N * $cos_lat;

    return $r;
}

## 地球上の2地点間の距離をメートル単位で計算する (ハバーサイン公式)
## 引数はすべてラジアン単位で受け取る
## 引数: Point A 緯度（ラジアン）
## 引数: Point A 経度（ラジアン）
## 引数: Point B 緯度（ラジアン）
## 引数: Point B 経度（ラジアン）
## 戻り値: 2地点間の距離 (メートル)
##
## --- 距離計算に関するメモ ---
## 1. ハバーサイン公式 (本実装):
##    地球を球体と仮定。計算が高速で一般的。
##    半径に IUGG推奨の平均半径 (6371008.7714m) を使用することで、
##    誤差を最小（最大0.5%程度）に抑えている。
##
## 2. ヒュベニ (Hubeny) の公式:
##    地球を楕円体として計算。日本近海など数〜数百kmの距離で非常に高精度。
##    緯度によって1分の長さが変わる性質を考慮できる。
##
## 3. ヴィンセンティ (Vincenty) 法:
##    楕円体上での最短距離を求める反復計算式。
##    数千km以上の長距離でもミリ単位の精度が出るが、計算負荷が高い。
## ----------------------------
sub geo_distance_m( $$$$ )
{
    my $latA_rad = shift( @_ ); # 引数1: 緯度A (ラジアン)
    my $lonA_rad = shift( @_ ); # 引数2: 経度A (ラジアン)
    my $latB_rad = shift( @_ ); # 引数3: 緯度B (ラジアン)
    my $lonB_rad = shift( @_ ); # 引数4: 経度B (ラジアン)

    # 緯度と経度の差分
    my $dlon = $lonB_rad - $lonA_rad;
    my $dlat = $latB_rad - $latA_rad;

    # ハバーサイン公式の計算
    my $a = ( sin( $dlat / 2 ) * sin( $dlat / 2 ) ) +
            ( cos( $latA_rad ) * cos( $latB_rad ) *
              sin( $dlon / 2 ) * sin( $dlon / 2 ) );
    my $distance = 2 * atan2( sqrt( $a ), sqrt( 1 - $a ) );

    # 地球の半径 (メートル)
    my $earth_radius_m = 6371008.7714; # 平均半径 (メートル)
#    my $earth_radius_m = GRS80_EQUATORIAL_RADIUS_M; # 赤道半径（長半径）

    my $distance_m = $earth_radius_m * $distance;

    return $distance_m;
}

sub geo_distance_km( $$$$ )
{
    return &geo_distance_m( @_ ) / 1000;
}

sub geo_azimuth( $$$$ )
{
    my $latA_rad = shift( @_ ); # 引数1: 緯度A (ラジアン)
    my $lonA_rad = shift( @_ ); # 引数2: 経度A (ラジアン)
    my $latB_rad = shift( @_ ); # 引数3: 緯度B (ラジアン)
    my $lonB_rad = shift( @_ ); # 引数4: 経度B (ラジアン)

    my $delta_x = $lonB_rad - $lonA_rad;
    my $rad = atan2( cos( $latA_rad ) * tan( $latB_rad ) -
        sin( $latA_rad ) * cos( $delta_x ),
        sin( $delta_x ) );
    my $deg = rad2deg( $rad );
    my $ret_deg = 90 - $deg;

    return $ret_deg;
}

sub geo_dist_m_and_azimuth( $$$$ )
{
    my $latA_rad = shift( @_ ); # 引数1: 緯度A (ラジアン)
    my $lonA_rad = shift( @_ ); # 引数2: 経度A (ラジアン)
    my $latB_rad = shift( @_ ); # 引数3: 緯度B (ラジアン)
    my $lonB_rad = shift( @_ ); # 引数4: 経度B (ラジアン)

    my $dist = &geo_distance_m( $latA_rad, $lonA_rad, $latB_rad, $lonB_rad );
    my $deg  = &geo_azimuth( $latA_rad, $lonA_rad, $latB_rad, $lonB_rad );

    return ( $dist, $deg );
}

sub geo_dist_km_and_azimuth( $$$$ )
{
    my $latA_rad = shift( @_ ); # 引数1: 緯度A (ラジアン)
    my $lonA_rad = shift( @_ ); # 引数2: 経度A (ラジアン)
    my $latB_rad = shift( @_ ); # 引数3: 緯度B (ラジアン)
    my $lonB_rad = shift( @_ ); # 引数4: 経度B (ラジアン)

    my $dist = &geo_distance_km( $latA_rad, $lonA_rad, $latB_rad, $lonB_rad );
    my $deg  = &geo_azimuth( $latA_rad, $lonA_rad, $latB_rad, $lonB_rad );

    return ( $dist, $deg );
}

## Revision: 1.1
sub is_leap_year( $ )
{
    my $year = shift( @_ );
    my $retBool = ( ( ( $year % 4 == 0 ) &&
                      ( ( $year % 100 != 0 ) ||
                        ( $year % 400 == 0 ) )
                    ) ? 1 : 0 );
    return $retBool;
}

sub is_leap( @ )
{
    my @ret_vals = ();
    for my $year( @_ ){
        push( @ret_vals, &is_leap_year( $year ) );
    }
    return @ret_vals;
}

## Revision: 1.1
sub age_of_moon( $$$ )
{
    my $y = shift( @_ );
    my $m = shift( @_ );
    my $d = shift( @_ );
    my @c = ( 0, 2, 0, 2, 2, 4, 5, 6, 7, 8, 9, 10 );
    #printf ("DATE: %04d/%02d/%02d\n", $y, $m, $d) ;

    my $age = ( ( ( $y - 11 ) % 19 ) * 11 + $c[ $m - 1 ] + $d ) % 30;

    return $age ;
}

sub local2epoch( $$$;$$$ )
{
    my( $year, $month, $mday, $hour, $minute, $sec ) = @_;
#    $year -= 1900; # 4桁の西暦を解釈できる。4桁で渡すべき。
    $month -= 1;
    $hour = 0 if( !defined( $hour ) );
    $minute = 0 if( !defined( $minute ) );
    $sec = 0 if( !defined( $sec ) );
    my $epoch = Time::Local::timelocal( $sec, $minute, $hour, $mday, $month, $year );
    return $epoch;
}

sub gmt2epoch( $$$;$$$ )
{
    my( $year, $month, $mday, $hour, $minute, $sec ) = @_;
#    $year -= 1900; # 4桁の西暦を解釈できる。4桁で渡すべき。
    $month -= 1;
    $hour = 0 if( !defined( $hour ) );
    $minute = 0 if( !defined( $minute ) );
    $sec = 0 if( !defined( $sec ) );
    my $epoch = Time::Local::timegm( $sec, $minute, $hour, $mday, $month, $year );
    return $epoch;
}

sub epoch2local( $ )
{
    my $epoch = shift( @_ );
    my( $sec, $minute, $hour, $mday, $month, $year ) = localtime( $epoch );
    $year += 1900; # localtime/gmtimeは1900年からのオフセット。エポック秒のゼロは1970年。ANSI Cと同じ。
    $month += 1;
    return ( $year, $month, $mday, $hour, $minute, $sec );
}

sub epoch2gmt( $ )
{
    my $epoch = shift( @_ );
    my( $sec, $minute, $hour, $mday, $month, $year ) = gmtime( $epoch );
    $year += 1900; # localtime/gmtimeは1900年からのオフセット。エポック秒のゼロは1970年。ANSI Cと同じ。
    $month += 1;
    return ( $year, $month, $mday, $hour, $minute, $sec );
}

sub sec2dhms( $ )
{
    my $duration = shift( @_ );
    #print( qq{\$duration="$duration"\n} );

    my $bNeg = ( $duration < 0 ? 1 : 0 );
    my $duration_abs = abs( $duration );

    my $sec = $duration_abs % 60;
    my $remain = int( $duration_abs / 60 );
    my $minute = $remain % 60;
    $remain = int( $remain / 60 );
    my $hour = $remain % 24;
    my $days = int( $remain / 24 );

    if( $bNeg ){
        $sec *= -1;
        $minute *= -1;
        $hour *= -1;
        $days *= -1;
    }

    return ( $days, $hour, $minute, $sec );
}

sub dhms2sec( $;$$$ )
{
    my( $days, $hour, $minute, $sec ) = @_;
    $hour = 0 if( !defined( $hour ) );
    $minute = 0 if( !defined( $minute ) );
    $sec = 0 if( !defined( $sec ) );

    my $duration_sec = 0;
    $duration_sec += 86400 * $days;
    $duration_sec +=  3600 * $hour;
    $duration_sec +=    60 * $minute;
    $duration_sec +=         $sec;

    return $duration_sec;
}

## 長さ変換: 里→メートル[m]
sub ri2meter( $ )
{
    my $ri = shift( @_ );
    my $meter = $ri * UCFACTOR_RI;
    return $meter;
}

## 長さ変換: メートル[m]→里
sub meter2ri( $ )
{
    my $meter = shift( @_ );
    my $ri = $meter / UCFACTOR_RI;
    return $ri;
}

## 長さ変換: マイル[mi]→メートル[m]
sub mile2meter( $ )
{
    my $mile = shift( @_ );
    my $meter = $mile * UCFACTOR_MILE;
    return $meter;
}

## 長さ変換: メートル[m]→マイル[mi]
sub meter2mile( $ )
{
    my $meter = shift( @_ );
    my $mile = $meter / UCFACTOR_MILE;
    return $mile;
}

## 長さ変換: 海里→メートル[m]
sub nautical_mile2meter( $ )
{
    my $nautical_mile = shift( @_ );
    my $meter = $nautical_mile * UCFACTOR_NAUTICAL_MILE;
    return $meter;
}

## 長さ変換: メートル[m]→海里
sub meter2nautical_mile( $ )
{
    my $meter = shift( @_ );
    my $nautical_mile = $meter / UCFACTOR_NAUTICAL_MILE;
    return $nautical_mile;
}

## 重さ変換: ポンド[lb]→グラム[g]
sub pound2gram( $ )
{
    my $pound = shift( @_ );
    my $gram = $pound * UCFACTOR_POUND;
    return $gram;
}

## 重さ変換: グラム[g]→ポンド[lb]
sub gram2pound( $ )
{
    my $gram = shift( @_ );
    my $pound = $gram / UCFACTOR_POUND;
    return $pound;
}

## 重さ変換: オンス[oz]→グラム[g]
sub ounce2gram( $ )
{
    my $ounce = shift( @_ );
    my $gram = $ounce * UCFACTOR_OUNCE;
    return $gram;
}

## 重さ変換: グラム[g]→オンス[oz]
sub gram2ounce( $ )
{
    my $gram = shift( @_ );
    my $ounce = $gram / UCFACTOR_OUNCE;
    return $ounce;
}

sub msec2hms( $ )
{
    my $duration = shift( @_ );
    #print( qq{\$duration="$duration"\n} );

    my $sec = $duration % 60;
    $sec += $duration - int( $duration );
    #print( qq{\$sec="$sec"\n} );
    my $remain = int( $duration / 60 );
    my $minute = $remain % 60;
    $remain = int( $remain / 60 );
    my $hour = $remain % 24;

    return ( $hour, $minute, $sec );
}

sub waitEnter( $;$ )
{
    my $zero_time = shift( @_ );
    my $b_continue_after_zero = 1;
    if( defined( $_[ 0 ] ) ){
        $b_continue_after_zero = shift( @_ );
    }

    #print( qq{\$zero_time="$zero_time"\n} );

    # 標準出力をオートフラッシュ（バッファリング無効）
    my $autoflash_backup = $|;  # Probably 0
    $| = 1;

    #print( "タイマー開始。Enterキーで終了します...\n" );

    my $bBelCheck = -1;
    my $line = '';
    while( 1 ){
        my $bel = '';
        # 1. タイマーの計算と表示
        my $lap     = &Time::HiRes::time();
        my $elapsed = $lap - $zero_time;
        if( $elapsed >= 0 ){
            #print( qq{\$elapsed="$elapsed"\n} );
            if( $bBelCheck == 1 ){
                $bBelCheck = 0;
                $bel = "\a";
            }
            if( $b_continue_after_zero == 0 ){
                print( "$bel" );
                last;
            }
        }else{
            if( $bBelCheck == -1 ){
                $bBelCheck = 1;
            }
        }
        $elapsed = abs( $elapsed );
        my $days    = int( $elapsed / 86400 );
        my $hours   = int( ( $elapsed % 86400 ) / 3600 );
        my $mins    = int( ( $elapsed % 3600 ) / 60 );
        my $secs    = int( $elapsed % 60 );
        my $msecs   = int( ( $elapsed - int( $elapsed ) ) * 1000 );

        # \r で行頭に戻って上書き
        if( $days ){
            printf( "$bel\r%3d %02d:%02d:%02d.%03d ",
                $days, $hours, $mins, $secs, $msecs );
        }else{
            printf( "$bel\r%02d:%02d:%02d.%03d ",
                $hours, $mins, $secs, $msecs );
        }
        ## 次の出力にも"\r"を入れておくこと

        # 2. 標準入力の監視 (select を使用)
        # vec(ビットベクトル)を作成して STDIN(ファイル記述子0)をセット
        my $rin = '';
        vec( $rin, fileno( STDIN ), 1 ) = 1;

        # select(読込待ちベクトル, 書込待ち, 例外待ち, タイムアウト秒)
        # 0.05秒だけ入力を待ち、無ければ次に進む
        my $nfound = select( my $rout = $rin, undef, undef, 0.05 );
        if( $nfound > 0 ){
            # 入力があった場合、内容を確認
            $line = <STDIN>;
            $line =~ s/\r?\n$//o;
            #print( qq{Enterが押されました。終了します。"$line"\n} );
            last;
        }
    }

    # 標準出力のオートフラッシュ設定を元に戻しておく
    $| = $autoflash_backup;
    return $line;
}

sub laptimer( $ )
{
    my $cycle = shift( @_ );
    my $b_rich_print = 1;
    $b_rich_print = 0 if( $cycle < 0 );
    $cycle = int( abs( $cycle ) );
    my $remain = $cycle;
    my $beg = &Time::HiRes::time();
    #print( qq{\$beg=$beg\n} );
    my $lap_last = $beg;
    my $spl_time = 0;
    my $cycle_w = length( $cycle );
    my $lap_w = ( $cycle_w * 2 ) + 1;
    if( $cycle && $b_rich_print ){
        if( $cycle == 1 ){
            print( qq{Elaps         Date-Time\n} );
            print( qq{------------  -------------------\n} );
        }else{
            printf( qq{%-${lap_w}s  Split-Time    Lap-Time      Date-Time\n}, 'Lap' );
            print( '-' x $lap_w . qq{  ------------  ------------  -------------------\n} );
        }
    }
    my $lap_old = $beg;
    while( $remain-- != 0 ){
        my $seq = $cycle - $remain;
        #print( qq{\$remain=$remain\n} );
        #print( qq{\$line="$line"\n} );
        my $line = &waitEnter( $lap_old );
        if( $line ne '' ){
            $remain = 0;
        }
        my $lap = &Time::HiRes::time();
        $lap_old = $lap;
        $spl_time = $lap - $beg;
        my $lap_time = $lap - $lap_last;
        $lap_last = $lap;
        my( $sec, $minute, $hour, $mday, $month, $year ) = localtime( int( $lap ) );
        $year += 1900;
        $month += 1;
        my @st = &msec2hms( $spl_time );
        my @lt = &msec2hms( $lap_time );
        if( $b_rich_print ){
            if( $cycle == 1 ){
                printf( qq{\r%02d:%02d:%06.3f  } .
                        qq{%04d-%02d-%02d %02d:%02d:%02d\n},
                    $st[ 0 ], $st[ 1 ], $st[ 2 ],
                    $year, $month, $mday, $hour, $minute, $sec );
            }else{
                printf( qq{\r%${cycle_w}d/%${cycle_w}d  %02d:%02d:%06.3f  %02d:%02d:%06.3f  } .
                        qq{%04d-%02d-%02d %02d:%02d:%02d\n},
                    $seq, $cycle,
                    $st[ 0 ], $st[ 1 ], $st[ 2 ],
                    $lt[ 0 ], $lt[ 1 ], $lt[ 2 ],
                    $year, $month, $mday, $hour, $minute, $sec );
            }
        }else{
            printf( qq{\r%04d-%02d-%02d %02d:%02d:%02d\n},
                $year, $month, $mday, $hour, $minute, $sec );
        }
    }

    return $spl_time;
}

sub timer( $ )
{
    my $target = shift( @_ );
    my $zero_time = $target;

    my $b_continue_after_zero = 1;
    # 31536000=86400*365
    if( $target < 31536000 ){           # 1971-01-01 00:00:00 より前なら
        my $start_time = &Time::HiRes::time();
        $zero_time = $start_time + $target; # エポックにする
        $b_continue_after_zero = 0;         # ゼロに到達したら終了
    }
    my( $sec, $minute, $hour, $mday, $month, $year ) = localtime( $zero_time );
    $year += 1900;
    $month += 1;
    my $msec = ( $zero_time - int( $zero_time ) ) * 1000;;
    printf( qq{%04d-%02d-%02d %02d:%02d:%02d.%03d  TARGET\n},
        $year, $month, $mday, $hour, $minute, $sec, $msec );

    &waitEnter( $zero_time, $b_continue_after_zero );

    my $end_time = &Time::HiRes::time();
    ( $sec, $minute, $hour, $mday, $month, $year ) = localtime( $end_time );
    $year += 1900;
    $month += 1;
    $msec = ( $end_time - int( $end_time ) ) * 1000;
    printf( qq{\r%04d-%02d-%02d %02d:%02d:%02d.%03d\n},
        $year, $month, $mday, $hour, $minute, $sec, $msec );
    my $elaps = $end_time - $zero_time;
    return $elaps;
}

sub stopwatch()
{
    my $t = &laptimer( -1 );
    print( qq{stopwatch() = $t sec.\n} );
    return $t;
}

sub bpm( $$ )
{
    my $count = shift( @_ );
    my $sec = shift( @_ );
    return ( $count * 60 ) / $sec;
}

sub bpm15()
{
    my $t = &stopwatch();
    return &bpm( 15, $t );
}

sub bpm30()
{
    my $t = &stopwatch();
    return &bpm( 30, $t );
}

sub tachymeter( $ )
{
    my $sec = shift( @_ );
    return 3600 / $sec;
}

sub telemeter( $ )
{
    my $sec = shift( @_ );
    ## 音の伝播速度は、標準大気中の音速 1225km/h から、 340m/秒 と考える。
    ## 光の速度は無視した。(光速 ＝ 299792458 m/s ≒ 30万キロメートル毎秒)
    return $sec * 340;
}

sub telemeter_m( $ )
{
    my $sec = shift( @_ );
    return &telemeter( $sec );
}

sub telemeter_km( $ )
{
    my $sec = shift( @_ );
    return &telemeter( $sec ) / 1000;
}


package FormulaParser;
use strict;
use warnings 'all';
use base qq{OutputFunc};
use utf8;
use Encode;

# FormulaParser コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{HELPER} = shift( @_ );
    $self->{APPCONFIG} = shift( @_ );
    $self->{STACK} = FormulaStack->new( $self->{APPCONFIG} );
    $self->SetLabel( 'parser' );
#    $self->Reset();
#    $self->dPrint( qq{$self->{APPCONFIG}->{APPNAME}: FormulaParser: create\n} );
    return $self;               # 無名ハッシュ参照を返す
}

sub Reset()
{
    my $self = shift( @_ );
    $self->Stack->Reset();
    my $el_r = FormulaToken::NewOperator( "BEGIN" );
    $self->Stack->Push( $el_r );
}

sub Stack()
{
    my $self = shift( @_ );
    return $self->{STACK};
}

sub FormulaNormalization( @ )
{
    my $self = shift( @_ );

    my @exprs = ();
    for my $expr( @_ ){
        $expr = $self->FormulaNormalizationOneLine( $expr );
        push( @exprs, $expr );
    }
    my $formula_raw = join( ' ', @exprs );
#    if( ( !( $formula_raw =~ m!=\s*$!o ) ) && ( $formula_raw ne '' ) ){
    if( ( !( $formula_raw =~ m!=!o ) ) && ( $formula_raw ne '' ) ){
        $formula_raw = $formula_raw . '=';
    }

    $self->dPrint( qq{FormulaNormalization(): "$formula_raw"\n} );
    return $formula_raw;
}

sub FormulaNormalizationOneLine( $ )
{
    my $self = shift( @_ );
    my $expr = $_[ 0 ];

    my $expr_org = $expr;

    ##########
    ## コーディングが面倒になるので全角文字はこの区間内に留める事。
    $expr = &str2p( $expr );
    $expr =~ tr!Ａ-Ｚａ-ｚ０-９，、．＋＊・･／＾（）＝　”゛“’′!a-za-z0-9,,.+***/^()= """''!;
    ## tr///で使えなかった → －
    $expr =~ s!－!-!go;
    $expr =~ s!√!sqrt!go;
    $expr =~ s!π!pi!go;
    $expr =~ s!(?:北緯|東経)(\d+)°(\d+)'(\d+(?:\.\d+)?)"!dms2rad( $1, $2, $3 )!go;
    $expr =~ s!(?:南緯|西経)(\d+)°(\d+)'(\d+(?:\.\d+)?)"!dms2rad( -$1, -$2, -$3 )!go;
    $expr =~ s!(?:北緯|東経)(\d+)°(\d+(?:\.\d+)?)'!dms2rad( $1, $2, 0 )!go;
    $expr =~ s!(?:南緯|西経)(\d+)°(\d+(?:\.\d+)?)'!dms2rad( -$1, -$2, 0 )!go;
    $expr =~ s!(?:北緯|東経)(\d+(?:\.\d+)?)[度°]!deg2rad( $1 )!go;
    $expr =~ s!(?:南緯|西経)(\d+(?:\.\d+)?)[度°]!deg2rad( -$1 )!go;
    ## ex.) 35°12'34"N 139°40'56"E
    $expr =~ s!(\d+)°(\d+)'(\d+(?:\.\d+)?)"[NE]!dms2rad( $1, $2, $3 )!go;
    $expr =~ s!(\d+)°(\d+)'(\d+(?:\.\d+)?)"[SW]!dms2rad( -$1, -$2, -$3 )!go;
    $expr =~ s!(\d+)°(\d+(?:\.\d+)?)'[NE]!dms2rad( $1, $2, 0 )!go;
    $expr =~ s!(\d+)°(\d+(?:\.\d+)?)'[SW]!dms2rad( -$1, -$2, 0 )!go;
    $expr =~ s!(\d+(?:\.\d+)?)°[NE]!deg2rad( $1 )!go;
    $expr =~ s!(\d+(?:\.\d+)?)°[SW]!deg2rad( -$1 )!go;
    $expr =~ s!→!2!go;
    $expr =~ s!メートル!meter!go;
    $expr =~ s!マイル!mile!go;
    $expr =~ s!海里!nautical_mile!go;
    $expr =~ s!里!ri!go;
    $expr =~ s!グラム!gram!go;
    $expr =~ s!ポンド!pound!go;
    $expr =~ s!オンス!ounce!go;
    $expr = &p2str( $expr );
    ##########

    $expr =~ s!^\s+!!o;
    $expr =~ s!\s+$!!o;
    $expr = lc( $expr );                # 小文字に

    $expr =~ s!([a-z]+)\s*\(!$1(!go;    # アルファベットと括弧（始）の間の空白は無視
#    $expr =~ tr!x!*!;                   # コメントアウト。16進数を使う事を優先
#    $expr =~ s!(\d),(\d{3})!$1$2!go;    # 桁区切りカンマの除去
    $expr =~ s/(?<=\d),(?=\d{3}\b)//go; # 桁区切りカンマの除去
    $expr =~ s!power!pow!go;
    ## alias
    ## (?<!..): 否定的後読み
    ## (?!..) : 否定的先読み
    $expr =~ s/(?<![a-z])now(?![a-z])/time/go;
    $expr =~ s!pct\(!percentage(!go;
    $expr =~ s!rs\(!ratio_scaling(!go;
    $expr =~ s!pf\(!prime_factorize(!go;
    $expr =~ s!dist\(!dist_between_points(!go;
    $expr =~ s!midpt\(!midpt_between_points(!go;
    $expr =~ s!angle\(!angle_between_points(!go;
    $expr =~ s!gd_m\(!geo_distance_m(!go;
    $expr =~ s!gd_km\(!geo_distance_km(!go;
    $expr =~ s!gazm\(!geo_azimuth(!go;
    $expr =~ s!gd_m_azm\(!geo_dist_m_and_azimuth(!go;
    $expr =~ s!gd_km_azm\(!geo_dist_km_and_azimuth(!go;
    $expr =~ s!lt\(!laptimer(!go;
    $expr =~ s!sw\(!stopwatch(!go;
    $expr =~ s!l2e\(!local2epoch(!go;
    $expr =~ s!g2e\(!gmt2epoch(!go;
    $expr =~ s!e2l\(!epoch2local(!go;
    $expr =~ s!e2g\(!epoch2gmt(!go;

    $self->dPrint( qq{FormulaNormalizationOneLine(): "$expr_org" -> "$expr"\n} );
    return $expr;
}

## 経路決定
sub RouteDetermination()
{
    my $self = shift( @_ );
    my $curr_token = $_[ 0 ];
    my $ref_parser_output = $_[ 1 ];

    @$ref_parser_output = ();

    my $bFormulaFin = 0;

    my $el_L = $self->Stack->GetNewer();
    my $tokenL = $el_L->GetTokenSymbol();
    my $tokenR = $curr_token->GetTokenSymbol();
    my $act = &TableProvider::GetPriorityOrderBetweenTokens( $tokenL, $tokenR );

    if( $curr_token->IsOperand() ){         ## オペランドなら出力
        $self->Queuing( $ref_parser_output, $curr_token, $act );
    }

    while( $act == TableProvider::E_LEFT ){
        my $stack_out = $self->Stack->Pop();
        $self->Queuing( $ref_parser_output, $stack_out, $act );
        $el_L = $self->Stack->GetNewer();
        $tokenL = $el_L->GetTokenSymbol();
        $act = &TableProvider::GetPriorityOrderBetweenTokens( $tokenL, $tokenR );
    }

    if( $act == TableProvider::E_RIGH ){
        if( $curr_token->IsOperator() ){        ## オペレータならスタックに退避。
            $self->Stack->Push( $curr_token );  ## オペランドは常にEvaluator行きなので除外。
            if( $curr_token->IsFunction() ){
                my $sentinel = FormulaToken::NewOperator( '#' );
#                printf( qq{P: 0x%X, "%s"\n}, $sentinel->flags, $sentinel->data );
                $self->Queuing( $ref_parser_output, $sentinel, $act );
            }
        }
    }elsif( $act == TableProvider::E_REMV ){
        $self->Stack->Pop();
        $self->dPrintf( qq{delete "%s" xxx "%s"\n}, $tokenL, $tokenR );
        if( $tokenL eq 'BEGIN' ){
            $bFormulaFin = 1;
            $self->dPrint( qq{Check the end of the calculation formula.\n} );
        }
    }elsif( $act == TableProvider::E_FUNC ){
        my $stack_out = $self->Stack->Pop();
        $self->dPrintf( qq{queing "%s", delete "%s"\n}, $tokenL, $tokenR );
        $self->Queuing( $ref_parser_output, $stack_out, $act );
    }elsif( $act == TableProvider::E_IGNR ){
    }else{
        my $msg = qq{"$tokenL", "$tokenR": Wrong combination.\n};
        $msg .= $self->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
        $msg .= $self->GenMsg( 'info', $self->{HELPER}->GetHere( $curr_token->id ) . "\n" );
        $self->Die( $msg );
    }

    return $bFormulaFin;
}

sub Queuing( \@$$ )
{
    my $self = shift( @_ );
    my $ref_array = shift( @_ );
    my $item = shift( @_ );
    my $act = shift( @_ );

    my $newitem = $item;
    #printf( qq{\$item->id="%d", data="%s"\n}, $item->id, $item->data );
    ## Evaluatorに送る前にやる事
    ## 関数名から括弧「(」を外す
    my $simple_name = '';
    my $bFunc = 0;
    if( $item->IsOperator() ){
        $simple_name = $item->data;
        if( $simple_name =~ s/^([a-z0-9_]+)\($/$1/o ){
            $newitem = $item->Copy( $simple_name );
            $bFunc = 1;
        }

        if( !defined( &TableProvider::GetSubroutine( $simple_name ) ) &&
            !( &TableProvider::IsSentinel( $simple_name ) ) ){
            my $msg = '';
            if( $simple_name eq '(' ){
                $msg = qq{The position of the ")" is incorrect.\n};
                $msg .= $self->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
                $msg .= $self->GenMsg( 'info', $self->{HELPER}->GetHere( $item->id ) . "\n" );
            }else{
                $msg = qq{"$simple_name": There is a problem with the calculation formula.\n};
            }
            $self->Die( qq{$msg} );
        }
    }

    if( $bFunc && $act != TableProvider::E_FUNC ){
        my $msg = qq{"$simple_name(": ")" may be incorrect.\n};
        $msg .= $self->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
        $msg .= $self->GenMsg( 'info', $self->{HELPER}->GetHere( $item->id ) . "\n" );
        $self->warnPrint( $msg );
    }

    $self->dPrintf( qq{Queuing: 0x%04X, "%s"\n}, $newitem->flags, $newitem->data );
    push( @$ref_array, $newitem );
}

use constant STR_CHAR_CODE => 'utf8';
## UTF-8 → Perl内部文字列
## Revision: 1.1
sub str2p
{
    my $argc = scalar( @_ );
#    if( $argc == 1 ){
        return decode( STR_CHAR_CODE, $_[ 0 ] );
#    }else{
#        my @a = ();
#        for my $arg( @_ ){
#            push( @a, decode( STR_CHAR_CODE, $arg ) );
#        }
#        return @a;
#    }
}
## Perl内部文字列 → UTF-8
## Revision: 1.1
sub p2str
{
    my $argc = scalar( @_ );
#    if( $argc == 1 ){
        return encode( STR_CHAR_CODE, $_[ 0 ] );
#    }else{
#        my @a = ();
#        for my $arg( @_ ){
#            push( @a, encode( STR_CHAR_CODE, $arg ) );
#        }
#        return @a;
#    }
}


package FormulaLexer;
use strict;
use warnings 'all';
use base qq{OutputFunc};
use Math::Trig qw/pi/;

#use constant SHIFT_REG_LEN => 2;

# FormulaLexer コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{APPCONFIG} = shift( @_ );
    $self->SetLabel( 'lexer' );
    $self->LoadUserRcFiles( \%{ $self->{CONSTANTS} } );
    if( $self->{APPCONFIG}->GetBPrintUserDefined() ){
        $self->PrintUserDefined();
        exit( 0 );
    }
#    $self->Reset();
#    $self->dPrint( qq{$self->{APPCONFIG}->{APPNAME}: FormulaLexer: create\n} );
    return $self;               # 無名ハッシュ参照を返す
}

sub Reset()
{
    my $self = shift( @_ );
    @{ $self->{TOKENS} } = ();
}

sub LoadUserRcFiles( $\$ )
{
    my $self = shift( @_ );
    my $ref_user_const = shift( @_ );

    my $rcFileName = ".c.rc";
    for my $dir( $self->{APPCONFIG}->{APPPATH},
                 $ENV{HOME} ){
        my $cfile = "$dir/$rcFileName";
        if( ! -f $cfile ){
            next;
        }
        $self->LoadUserRc( $cfile, $ref_user_const );
    }

    return 0;
}

sub LoadUserRc( $\$ )
{
    my $self = shift( @_ );
    my $rc_file = shift( @_ );
    my $ref_user_const = shift( @_ );

    my %UCONST = do $rc_file;
    if( $@ ){
        $self->Die( "$rc_file: Failed to load user rc file: " . $@ );
#    }elsif( $! ){
#        $self->warnPrint( "$rc_file: Failed to access user rc file: " . $! );
#        return -1;
    }

    for my $KEY( sort( keys( %UCONST ) ) ){
        my $k = lc( $KEY );
        if( $self->{APPCONFIG}->GetBVerboseOutput() ){
            if( exists( $$ref_user_const{$k} ) ){
                $self->warnPrint( qq{"$KEY": "$$ref_user_const{$k}" -> "$UCONST{$KEY}": Overwrites the existing definition.\n} );
            }
        }
        $$ref_user_const{$k} = $UCONST{$KEY};
    }

    $self->dPrintf( qq{$rc_file: constant definitions=%d\n},
        scalar( %{ $ref_user_const } ) );

    return 0;
}

sub GetConstants()
{
    my $self = shift( @_ );
    my @kvs = ();
    for my $key( sort( keys( %{ $self->{CONSTANTS} } ) ) ){
        my $kv = sprintf( '%s = "%s"', uc( $key ), ${ $self->{CONSTANTS} }{ $key } );
        push( @kvs, $kv );
    }
    return @kvs;
}

sub PrintUserDefined()
{
    my $self = shift( @_ );
    print( "=== User Defined ===\n" );
    print( join( "\n", $self->GetConstants() ) . "\n" );
    print( "====================\n" );
    return;
}

sub IsTokenUserConstant( \$\$ )
{
    my $ref_str = shift( @_ );
    my $ref_user_const = shift( @_ );
    my $bRet = 0;
    if( $$ref_str =~ m!^([a-z_][a-z0-9_]+)(?=[^a-z])!o ){
        my $key = $1;
        #print( qq{\$\$ref_str="$$ref_str", \$key="$key"\n} );
        if( exists( $$ref_user_const{$key} ) ){
            my $len = length( $key );
            $$ref_str = $$ref_user_const{$key} . substr( $$ref_str, $len );
            $bRet = 1;
        }
    }
    return $bRet;
}

sub IsTokenOperator( \$\$ )
{
    my $ref_str = shift( @_ );
    my $ref_ope = shift( @_ );
    my $operator = '';
    if( $$ref_str =~ m!^([\S]{2})!o ){
        $operator = $1;
        if( &TableProvider::IsOperatorExists( $operator ) ){
            $$ref_str = substr( $$ref_str, 2 );
            $$ref_ope = $operator;
            return 1;
        }
    }
    $$ref_str =~ m!^([\S])!o;
    $operator = $1;
    if( &TableProvider::IsOperatorExists( $operator ) ){
        $$ref_str = substr( $$ref_str, 1 );
        $$ref_ope = $operator;
        return 1;
    }
    return 0;
}

## 式を分解してトークンを返す
sub GetToken( \$ )
{
    my $self = shift( @_ );
    my $ref_expr = shift( @_ );

    my $ret_obj = undef;

#    $opf->dPrint( qq{\$\$ref_expr="$$ref_expr"\n} );

    $$ref_expr =~ s!^\s+!!o;
    if( $$ref_expr ne '' ){
        my $operator = '';
        my $operand = 0;

        if( &IsTokenUserConstant( $ref_expr, \%{ $self->{CONSTANTS} } ) ){
            # nothing to do.
        ## オペランド
        }elsif( ( $$ref_expr =~ s!^([\-\+])(0x[\da-f]+)!!o ) ||
            ( $$ref_expr =~ s!^([\-\+])(\d+\.?\d*)!!o ) ){
            $operator = $1;
            my $operand_raw = $2;
            $operand = $operand_raw;
            my $el_d = undef;
            my $bHex = 0;
            if( $operand =~ m!^0x!o ){
                $operand = hex( $operand );
                $bHex = 1;
            }
            $el_d = &FormulaToken::NewOperand( "$operator$operand", $bHex );

            ## オペレータとオペランドの間にスペースを付加して式を組み立てなおす
            if( $self->IsNeedInsert( $operator, $el_d, " $operand_raw $$ref_expr", $ref_expr ) ){
                return $ret_obj;
            }
            $self->unshift( $el_d );
            $ret_obj = $el_d;

        }elsif( ( $$ref_expr =~ s!^(0x[\da-f]+)!!o ) ||
                ( $$ref_expr =~ s!^(\d+\.?\d*)!!o ) ){
            $operand = $1;
            my $el_d = undef;
            my $bHex = 0;
            if( $operand =~ m!^0x!o ){
                $operand = hex( $operand );
                $bHex = 1;
            }
            $el_d = &FormulaToken::NewOperand( $operand, $bHex );
            ## 必要であれば暗黙の乗算子を挿入
            if( $self->IsNeedInsert( '*', $el_d, " $operand $$ref_expr", $ref_expr ) ){
                return $ret_obj;
            }
            $self->unshift( $el_d );
            $ret_obj = $el_d;

        }elsif( $$ref_expr =~ s!^(pi|time)(?=[^a-z])!!o ){
            $operand = eval( $1 );
            my $el_d = &FormulaToken::NewOperand( $operand );
            ## 必要であれば暗黙の乗算子を挿入
            if( $self->IsNeedInsert( '*', $el_d, " $operand $$ref_expr", $ref_expr ) ){
                return $ret_obj;
            }
            $self->unshift( $el_d );
            $ret_obj = $el_d;

        ## オペレータ
        }elsif( $$ref_expr =~ s!^(([a-z0-9_]*)\()!!o ){
            $operator = $1;
            my $funcname = $2;
            my $bFunction = 0;
            if( $operator ne '(' ){
                if( ! &TableProvider::IsFunctionExists( $funcname ) ){
                    my $fns = join( ', ', &TableProvider::GetFunctionsList() );
                    my $info = $self->GenMsg( 'info', qq{Supported functions: $fns\n} );
                    $self->Die( qq{"$funcname()": unknown function.\n$info} );
                }
                $bFunction = 1;
            }

            my $el_r = &FormulaToken::NewOperator( $operator, $bFunction );
            ## 必要であれば暗黙の乗算子を挿入
            if( $self->IsNeedInsert( '*', $el_r, "$operator$$ref_expr", $ref_expr ) ){
                return $ret_obj;
            }
            $self->unshift( $el_r );
            $ret_obj = $el_r;

        ## 先頭の半角スペースは除去されていて文字数ゼロでもない状態
        }elsif( &IsTokenOperator( $ref_expr, \$operator ) ){
            my $el_r = &FormulaToken::NewOperator( $operator );
            ## 必要であれば暗黙の乗算子を挿入
            if( $self->IsNeedInsert( '*', $el_r, "$operator$$ref_expr", $ref_expr ) ){
                return $ret_obj;
            }
            $self->unshift( $el_r );
            $ret_obj = $el_r;

        }else{
            my $ops = join( ' ', &TableProvider::GetOperatorsList() );
            my $fns = join( ', ', &TableProvider::GetFunctionsList() );
            my $info = $self->GenMsg( 'info', qq{Supported operators: "$ops"\n} );
            $info .= $self->GenMsg( 'info', qq{Supported functions: $fns\n} );
            $info .= $self->GenMsg( 'info', qq{User Defined:\n} );
            for my $ud( $self->GetConstants() ){
                $info .= $self->GenMsg( 'info', $ud . "\n" );
            }
            $self->Die( qq{"$$ref_expr": Could not interpret.\n$info} );
        }
    }

    if( $self->{APPCONFIG}->GetDebug() ){
        my $token_data = 'undef';
        if( defined( $ret_obj ) ){
            $token_data = $ret_obj->data;
        }
        $self->dPrint( qq{GetToken="$token_data", remain="$$ref_expr"\n} );
    }
    return $ret_obj;
}

sub IsNeedInsert( $$$\$ )
{
    my $self = shift( @_ );
    my $operator = $_[ 0 ];
    my $curr_token = $_[ 1 ];
    my $expr_value = $_[ 2 ];
    my $ref_expr = $_[ 3 ];

    ## 入力前なので、添え字は「0（先頭）」
    my $last_token = $self->{TOKENS}[ 0 ];

    my $last_tkndata = 'undef';
    $last_tkndata = $last_token->data if( defined( $last_token ) );

    my $curr_tkndata = $curr_token->data;
    ## ここでは関数名は単なる括弧（始）'('として扱う
    $curr_tkndata = '(' if( $curr_tkndata =~ m/\($/o );

#    &dPrintf( qq{last="$last_tkndata", curr="$curr_tkndata"\n} );
    my $bInsert = 0;

    if( ( defined( $last_token ) ) &&
        ( ( ( $last_token->IsOperand() ) &&
            ( ( $curr_token->IsOperand() ) || ( $curr_tkndata eq '(' ) || ( $curr_tkndata eq '~' ) ) ) ||
          ( ( $last_token->IsOperator() ) &&
            ( ( ( $last_tkndata eq ')' ) && ( $curr_tkndata eq '(' ) ) ||
              ( ( $last_tkndata eq ')' ) && ( $curr_token->IsOperand() ) ) )
          )
        )
    ){
        $$ref_expr = "$operator$expr_value";
        $self->dPrint( qq{IsNeedInsert(): \$operator="$operator", \$\$ref_expr="$$ref_expr"\n} );
        $bInsert = 1;
    }

    return $bInsert;
}

sub unshift( $$ )
{
    my $self = shift( @_ );
    my $item = shift( @_ );

    my $id = scalar( @{ $self->{TOKENS} } );
    #print( qq{\$id="$id"\n} );
    $item->id( $id );

    unshift( @{ $self->{TOKENS} }, $item );

    return;
}

sub GetFormula()
{
    my $self = shift( @_ );
    my @exprs = ();
    for my $token( reverse( @{ $self->{TOKENS} } ) ){
        push( @exprs, $token->data );
    }
    my $expr = join( ' ', @exprs );
    $expr =~ s/\s+,/,/go;
    return $expr;
}

sub GetHere()
{
    my $self = shift( @_ );
    my $id = shift( @_ );
    my @strs = ();
    for my $token( reverse( @{ $self->{TOKENS} } ) ){
        my $data = sprintf( '%s', $token->data );
        my $len = length( $data );
        $len = 0 if( $data eq ',' );
        my $c = ' ';
        my $bLast = 0;
        if( $token->id == $id ){
            $c = '^';
            $bLast = 1;
        }
        my $s = $c x $len;
        push( @strs, $s );
        if( $bLast ){
            last;
        }
    }
    my $str = join( ' ', @strs ) . ' HERE';
    return $str;
}


package FormulaStack;
use strict;
use warnings 'all';
use base qq{OutputFunc};

# FormulaStack コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{APPCONFIG} = shift( @_ );
    $self->SetLabel( 'stack' );
#    $self->Reset();
#    $self->dPrint( qq{$self->{APPCONFIG}->{APPNAME}: FormulaStack: create\n} );
    if( $self->{APPCONFIG}->GetBTest() ){
        $self->Reset();
        $self->Pop();
        $self->GetNewer();
        $self->Reset();
    }
    return $self;               # 無名ハッシュ参照を返す
}

sub Reset()
{
    my $self = shift( @_ );
    @{ $self->{TOKENS} } = ();
}

## 名前はPush()だが実際にはunshift()を使っている
sub Push( $ )
{
    my $self = shift( @_ );
    my $item = shift( @_ );

    unshift( @{ $self->{TOKENS} }, $item );

    $self->dPrintf( qq{Push(): [%d] %s\n},
        scalar( @{ $self->{TOKENS} } ),
        $self->GetItems() );
    return;
}

## 名前はPop()だが実際にはshift()を使っている
sub Pop()
{
    my $self = shift( @_ );
    my $item = shift( @_ );

    my $ret_item = undef;

    if( scalar( @{ $self->{TOKENS} } ) ){
        $ret_item = shift( @{ $self->{TOKENS} } );

        $self->dPrintf( qq{Pop(): [%d] %s -> "%s"\n},
            scalar( @{ $self->{TOKENS} } ),
            $self->GetItems(), $ret_item->data );
    }else{
        $self->dPrint( qq{Pop(): enmpy!\n} );
    }

    return $ret_item;
}

sub GetItems()
{
    my $self = shift( @_ );
    my @stk = ();
    for my $t( reverse( @{ $self->{TOKENS} } ) ){
        push( @stk, qq{"}.$t->data.qq{"} );
    }
    return join( ' ', @stk );
}

sub GetNewer()
{
    my $self = shift( @_ );
    my $item = shift( @_ );

    my $ret_item = undef;

    if( scalar( @{ $self->{TOKENS} } ) ){
        $ret_item = ${ $self->{TOKENS} }[ 0 ];
    }else{
        $self->dPrint( qq{GetNewer(): enmpy!\n} );
    }

    return $ret_item;
}


package FormulaEvaluator;
use strict;
use warnings 'all';
use base qq{OutputFunc};

use constant {
    BIT_DISP_HEX => 0x1,
};

# FormulaEvaluator コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{HELPER} = shift( @_ );
    $self->{APPCONFIG} = shift( @_ );
    $self->SetLabel( 'evaluator' );
#    $self->Reset();
#    $self->dPrint( qq{$self->{APPCONFIG}->{APPNAME}: FormulaEvaluator: create\n} );
    if( $self->{APPCONFIG}->GetBTest() ){
        $self->Reset();
        my $el_r = FormulaToken::NewOperator( '*' );
        unshift( @{ $self->{RPN} }, $el_r );
        unshift( @{ $self->{RPN} }, $el_r );
        unshift( @{ $self->{TOKENS} }, $el_r );
        unshift( @{ $self->{TOKENS} }, $el_r );
        $self->ResultPrint();   # "There may be an error in the calculation formula"
        $@ = '';
        eval{
            $self->Input( $el_r );
        };
        print STDERR ( $@ );
        $self->dPrintf( qq{scalar( \@{ \$self->{RPN} } ) = %d\n}, scalar( @{ $self->{RPN} } ) );
        $self->dPrintf( qq{scalar( \@{ \$self->{TOKENS} } ) = %d\n}, scalar( @{ $self->{TOKENS} } ) );
        my $usage = $self->GetUsage( 'none-operator' );
        $self->dPrintf( qq{GetUsage() test: \$usage="$usage"\n} );
        $self->Reset();
    }
    return $self;               # 無名ハッシュ参照を返す
}

sub Reset()
{
    my $self = shift( @_ );
    @{ $self->{RPN} } = ();     # 逐次計算しないで全てのトークンを残す配列
    @{ $self->{TOKENS} } = ();  # 逐次計算して不要なトークンは残さない配列
    $self->{FLAGS} = 0x0;
    $self->RegisterClear();
}

sub RegisterClear()
{
    my $self = shift( @_ );
    $self->{FORMULA} = '';      # 最後に計算した時の式
    $self->{REGISTER} = 0;      # 最後に計算した時の計算結果
}

# 評価機に入力→必要に応じて計算を実行する
sub Inputs( @ )
{
    my $self = shift( @_ );
    my @tokens = @_;
    my $tokens_len = scalar( @{ $self->{TOKENS} } );
    for my $token( @tokens ){
        $tokens_len = $self->Input( $token );
    }
    return $tokens_len;
}
use constant {
    C_OPENUM => 0,
    C_FNCNUM => 1,
    C_FNCRAN => 2,
    C_FNCVAR => 3,
    C_FNCMLT => 4,
};
use constant C_CASES => qw(
    C_OPENUM C_FNCNUM C_FNCRAN C_FNCVAR C_FNCMLT
);
sub Input( $ )
{
    my $self = shift( @_ );
    my $token = $_[ 0 ];

    unshift( @{ $self->{RPN} }, $token );

    my @tokens = ( $token );
    my $op = '';
    if( $token->IsOperand() ){
        $self->{REGISTER} = $token->data;
        if( $token->IsHex() ){
            $self->{FLAGS} |= BIT_DISP_HEX;
        }
    }elsif( &TableProvider::IsSentinel( $token->data ) ){
        ## through...
    }else{
        $op = $token->data;
        my $bFunction = $token->IsFunction();
        $self->dPrint( qq{Input(): \$op="$op"\n} );
        if( ( $op eq '|' ) || ( $op eq '&' ) || ( $op eq '^' ) || ( $op eq '<<' ) || ( $op eq '>>' ) || ( $op eq '~' ) ){
            $self->{FLAGS} |= BIT_DISP_HEX;
        }
        my $subr = &TableProvider::GetSubroutine( $op );
        ## GetSubroutine() で undef になるオペレーターは
        ## Parser もしくは この手前で（例えばsentinel）フィルター済み
        my $argc = &TableProvider::GetArgc( $op );
        my $tokens_len = scalar( @{ $self->{TOKENS} } );
        ## check
        my $case = -1;
        my $need_argc = -1;
        my $argc_min = -1;
        my $argc_max = -1;
        my $check_len = -1;
        if( $argc =~ m/^(\d+)M$/o ){
            $case = C_FNCMLT;
            $need_argc = TableProvider::VA;
            $argc_min = $1;
            $argc_max = $tokens_len - 1;
            $check_len = $tokens_len;
        }elsif( $argc =~ m/^(\d+)\-(\d+)$/o ){
            $case = C_FNCRAN;
            $need_argc = TableProvider::VA;
            $argc_min = $1;
            $argc_max = $2;
            $check_len = $argc_max + 1;
        }elsif( $argc == TableProvider::VA ){
            $case = C_FNCVAR;
            $need_argc = TableProvider::VA;
            $argc_min = 1;
            $argc_max = $tokens_len - 1;
            $check_len = $tokens_len;
        }elsif( $bFunction ){
            $case = C_FNCNUM;
            $need_argc = $argc;
            $argc_min = $argc;
            $argc_max = $argc;
            $check_len = $argc_max + 1;
        }else{
            $case = C_OPENUM;
            $need_argc = $argc;
            $argc_min = $argc;
            $argc_max = $argc;
            $check_len = $argc_max;
        }
        my $b_tokens_len_check = 0;
        my $token_len_chk = $argc_min + 1;
        $token_len_chk = $argc_min if( $case == C_OPENUM );
        $b_tokens_len_check = 1 if( $tokens_len < $token_len_chk );
#        printf( qq{\$case="%s", \$tokens_len="$tokens_len", \$need_argc="$need_argc", \$argc_min="$argc_min", \$argc_max="$argc_max", \$check_len="$check_len", \$b_tokens_len_check="$b_tokens_len_check"\n},
#            ( C_CASES )[ $case ] );
        if( $b_tokens_len_check ){
            my $msg = qq{"$op": Operand missing.\n};
            $msg .= $self->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
            $msg .= $self->GenMsg( 'info', $self->{HELPER}->GetHere( $token->id ) . "\n" );
            $msg .= $self->GetUsage( $op );
            $self->Die( $msg );
        }
        my $arg_counter = 0;
        for( $arg_counter=0; $arg_counter<$check_len; $arg_counter++ ){
            my $el = ${ $self->{TOKENS} }[ $arg_counter ];
            if( !( $el->IsOperand() ) ){
                if( &TableProvider::IsSentinel( $el->data ) ){
                    if( $need_argc == TableProvider::VA ){
                        $need_argc = $arg_counter;
                        $self->dPrint( qq{variable arguments: \$need_argc="$need_argc"\n} );
                        last;
                    }
                }else{
                    my $msg = qq{"$op": Unexpected errors.\n};
                    $self->Die( $msg );
                }
                last;
            }
        }
        ## calc
        my @args = ();
        my $b_args_len_check = 0;
        my $msg = '';
        if( $case == C_FNCMLT ){
            $b_args_len_check = 1 if( ($arg_counter % $argc_min ) != 0 );
            $msg = qq{$op: \$arg_counter="$arg_counter": Not a multiple of $argc_min.\n};
        }else{
            $b_args_len_check = 1 if( $arg_counter < $argc_min || $argc_max < $arg_counter );
            $msg = qq{$op: \$arg_counter="$arg_counter": The number of operands is incorrect.\n};
        }
#        printf( qq{\$b_args_len_check="$b_args_len_check", \$arg_counter="$arg_counter"\n} );
        if( $b_args_len_check ){
            $msg .= $self->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
            $msg .= $self->GenMsg( 'info', $self->{HELPER}->GetHere( $token->id ) . "\n" );
            $msg .= $self->GetUsage( $op );
            $self->Die( $msg );
        }
        for( my $idx=0; $idx<$need_argc; $idx++ ){
            my $el = shift( @{ $self->{TOKENS} } );
            unshift( @args, ( $el->data + 0 ) );
        }
        if( $bFunction ){
            my $sentinel = shift( @{ $self->{TOKENS} } );
            #printf( qq{E: 0x%X, "%s"\n}, $sentinel->flags, $sentinel->data );
            $self->dPrintf( qq{\$need_argc="$need_argc": "%s": Retrieve sentinel.\n},
                $sentinel->data );
        }
        $self->RegisterClear();
        my $formula = '';
        if( &TableProvider::IsOperatorExists( $op ) ){
            my $args_len = scalar( @args );
            if( $args_len == 1 ){
                $formula = qq{$op$args[ 0 ]};
            }else{
                $formula = qq{$args[ 0 ] $op $args[ 1 ]};
            }
        }else{
            $formula = qq{$op( } . join( ', ', @args ) . qq{ )};
        }
        $self->{FORMULA} = $formula;
        ## 計算実行
        my $result = 0;
        my @results = ();
        eval{   ## 子処理の戻り先を積んでおく（die()を補足）
            @results = &{ $subr }( @args );
        };
        if( $@ ){
            my $msg = $@;
            $msg =~ s/ at .*\d\.$/./;
            $msg .= $self->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
            $msg .= $self->GenMsg( 'info', $self->{HELPER}->GetHere( $token->id ) . "\n" );
            $msg .= $self->GetUsage( $op );
            $self->Die( $msg );
        }
        my $results_len = scalar( @results );
        $result = $results[ 0 ];
        $tokens[ 0 ] = FormulaToken::NewOperand( $result );
        if( $results_len > 1 ){
            $result = '( ' . join( ', ', @results ) . ' )';
            for ( my $idx=1; $idx<$results_len; $idx++ ){
                my $res = $results[ $idx ];
                my $new = FormulaToken::NewOperand( $res );
                unshift( @tokens, $new );
            }
        }
        $self->{REGISTER} = $result;
        if( $self->{APPCONFIG}->GetBVerboseOutput() ){
            print( qq{$self->{FORMULA} = $result\n} );
        }
    }

    unshift( @{ $self->{TOKENS} }, @tokens );
    if( ( $self->{APPCONFIG}->GetBVerboseOutput() ) &&
        ( $self->{APPCONFIG}->GetBRpn() || $self->{APPCONFIG}->GetDebug() ) ){
        print( 'Remain RPN: ' . $self->GetTokens() . "\n" );
    }

    return scalar( @{ $self->{TOKENS} } );
}

sub GetUsage( $ )
{
    my $self = shift( @_ );
    my $op = shift( @_ );
    my $info = '';
    my $usage = '';
    my $help = &TableProvider::GetHelp( $op );
    if( defined( $help ) ){
        $usage = $help;
        $usage = 'usage: ' . $usage;
        $info = $self->GenMsg( 'info', $usage ) . "\n";
    }
    return $info;
}

sub GetRpn()
{
    my $self = shift( @_ );
    my @rpn_val = ();
    for my $item( reverse( @{ $self->{RPN} } ) ){
        push( @rpn_val, $item->data );
    }
    return join( ' ', @rpn_val );
}

sub GetTokens()
{
    my $self = shift( @_ );
    my @rpn_val = ();
    for my $item( reverse( @{ $self->{TOKENS} } ) ){
        push( @rpn_val, $item->data );
    }
    return join( ' ', @rpn_val );
}

sub GetRegister()
{
    my $self = shift( @_ );
    return $self->{REGISTER};
}

sub ResultPrint()
{
    my $self = shift( @_ );
    my @reg_vals = ();
    my @raw_vals = ();
    my @mns_vals = ();
    my @hxa_vals = ();
    my $bDispRaw = 0;
    my $bDispMns = 0;
    for my $item( reverse( @{ $self->{TOKENS} } ) ){
        if( ! $item->IsOperand() ){
            $self->warnPrint( qq{There may be an error in the calculation formula.\n} );
            $self->warnPrint( qq{Remain RPN: } . $self->GetTokens() . "\n" );
            last;
        }
        my $reg_raw = $item->data;
        my $reg_str = undef;
        if( &NumberToString( $reg_raw, \$reg_str ) ){
            $bDispRaw = 1;
        }
        my $reg_hxa = undef;
        my $reg_mns = undef;
        if( &NumberToHex( $reg_str, \$reg_hxa, \$reg_mns ) ){
            $bDispMns = 1;
        }
        push( @raw_vals, $reg_raw );
        push( @reg_vals, $reg_str );
        push( @mns_vals, $reg_mns );
        push( @hxa_vals, $reg_hxa );
    }
    my $reg_len = scalar( @reg_vals );

    my $reg = join( ', ', @reg_vals );
    $reg = '( ' . $reg . ' )' if( $reg_len > 1 );
    if( $reg_len == 0 ){
        $reg = $self->GetRegister();
    }

    my $raw = '';
    if( $self->{APPCONFIG}->GetBVerboseOutput() && $bDispRaw ){
        $raw = join( ', ', @raw_vals );
        $raw = '( ' . $raw . ' )' if( $reg_len > 1 );
        $raw = " [ = $raw ]";
    }

    my $hxa = '';
    my $mns = '';
    if( $self->{FLAGS} & BIT_DISP_HEX ){
        if( $bDispMns ){
            $mns = join( ', ', @mns_vals );
            $mns = '( ' . $mns . ' )' if( $reg_len > 1 );
            $mns = " [ = $mns ]";
        }
        $hxa = join( ', ', @hxa_vals );
        $hxa = '( ' . $hxa . ' )' if( $reg_len > 1 );
        $hxa = " [ = $hxa ]";
    }

    $self->{REGISTER} = "$reg$raw$mns$hxa";

    return $self->{REGISTER};
}

sub NumberToString( $ )
{
    my $number = shift( @_ );
    my $ref_str = shift( @_ );

    $$ref_str = $number;
    my $bRet = 0;

    ## ex) 2.2e-07 -> 0.00000022
    if( $number =~ m/e\-(\d+)$/ ){
        my $width = $1 + 1;
#        $self->dPrint( qq{\$width="$width"\n} );
        $$ref_str = sprintf( qq{%.${width}f}, $number );
        $bRet = 1;
    ## ex) 1.59226291813144e+15 -> 1592262918131443.25
    }elsif( $number =~ m/e\+(\d+)$/ ){
        my $width = 20;
        $$ref_str = sprintf( qq{%.${width}f}, $number );
#        $self->dPrint( qq{\$width="$width" -> "$$ref_str"\n} );
        $$ref_str =~ s!\.?0+$!!o;
        $bRet = 1;
    }else{
        $$ref_str = sprintf( qq{%s}, $number );
    }

    return $bRet;
}

sub NumberToHex( $ )
{
    my $number = shift( @_ );
    my $ref_hxa = shift( @_ );
    my $ref_mns = shift( @_ );
    $$ref_hxa = $number;
    $$ref_mns = '-';
    my $bRet = 0;

    if( !( $number =~ m/\d\.\d/o ) ){
        ## 負数とみなせる場合
        my $signed_int = sprintf( '%d', $number );
        #print( qq{\$number="$number", \$signed_int="$signed_int"\n} );
        if( $number != $signed_int ){
            $bRet = 1;
            &NumberToString( $signed_int, $ref_mns );
        }
        $$ref_hxa = sprintf( qq{0x%X}, $number );
    }

    #$$ref_str = qq{$$ref_str$hex_str$hexadecimal};

    return $bRet;
}


package FormulaHelper;
use strict;
use warnings 'all';

sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{LEXER} = shift( @_ );
    return $self;               # 無名ハッシュ参照を返す
};

sub GetFormula()
{
    my $self = shift( @_ );
    return $self->{LEXER}->GetFormula();
}

sub GetHere()
{
    my $self = shift( @_ );
    my $id = shift( @_ );
    return $self->{LEXER}->GetHere( $id );
}


package FormulaEngine;
use strict;
use warnings 'all';
use base qq{OutputFunc};

# FormulaEngine コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{APPCONFIG} = shift( @_ );
    $self->SetLabel( 'engine' );
    $self->{TBL_PROVIDER} = TableProvider->new( $self->{APPCONFIG} );
    $self->{LEXER} = FormulaLexer->new( $self->{APPCONFIG} );
    $self->{HELPER} = FormulaHelper->new( $self->{LEXER} );
    $self->{PARSER} = FormulaParser->new( $self->{HELPER}, $self->{APPCONFIG} );
    $self->{EVALUATOR} = FormulaEvaluator->new( $self->{HELPER}, $self->{APPCONFIG} );
#    $self->Reset();
#    $self->dPrint( qq{$self->{APPCONFIG}->{APPNAME}: FormulaEngine: create\n} );
    if( $self->{APPCONFIG}->GetBTest() ){
        my $help_of_unknown_operator = &OutputFunc::FmtHelp( 100, '***' );
        $self->dPrint( qq{\$help_of_unknown_operator="$help_of_unknown_operator"\n} );
        $self->Reset();
        my $tblProvider2 = TableProvider->new( $self->{APPCONFIG} );
        $tblProvider2 = undef;
        $self->Reset();
    }
    return $self;               # 無名ハッシュ参照を返す
}

sub Reset()
{
    my $self = shift( @_ );
    $self->{TBL_PROVIDER}->Reset();
    $self->Parser->Reset();
    $self->Lexer->Reset();
    $self->Evaluator->Reset();
}

sub Parser()
{
    my $self = shift( @_ );
    return $self->{PARSER};
}

sub Lexer()
{
    my $self = shift( @_ );
    return $self->{LEXER};
}

sub Evaluator()
{
    my $self = shift( @_ );
    return $self->{EVALUATOR};
}

sub Run( @ )
{
    my $self = shift( @_ );
    my @exprs_raw = @_;

    my $expr = $self->Parser->FormulaNormalization( @exprs_raw );
    my $status = 0;
    my $bReadStdin = ! -t STDIN;
    if( $expr eq '' ){
        $self->dPrint( qq{\$expr is empty\n} );
        $bReadStdin = 1;
    }else{
        $status = $self->Calculate( $expr );
    }

    if( $bReadStdin ){
        while( <STDIN> ){
            my $line_raw = $_;
            $line_raw =~ s!\r?\n$!!o;
            my $line = $self->Parser->FormulaNormalization( $line_raw );
            if( $line eq '' ){
                print( qq{\n} );
                next;
            }
            eval{   ## 子処理の戻り場所を積んでおく（die()を補足）
                $self->Calculate( $line );
            };
            if( $@ ){
                print STDERR ( $@ );
                $@ = '';
                $status++;
            }
        }
    }

    return $status;
}

sub Calculate( $ )
{
    my $self = shift( @_ );
    my $expr = shift( @_ );

    $self->Reset();

    my $bParserFinish = 0;
    my $Evaluator_remain = 0;
    while( $expr ne '' ){
        my $curr_token = $self->Lexer->GetToken( \$expr );
        if( !defined( $curr_token ) ){
            next;
        }
        if( $bParserFinish ){
            my $msg = sprintf( qq{"%s$expr"}, $curr_token->data );
            $self->warnPrint( qq{$msg: Ignore. The calculation process has been completed.\n} );
            return -1;
        }

        my @evaluator_queue;
        $bParserFinish = $self->Parser->RouteDetermination( $curr_token, \@evaluator_queue );
        $Evaluator_remain = $self->Evaluator->Inputs( @evaluator_queue );
    }

    if( $self->{APPCONFIG}->GetBVerboseOutput() ){
        print( qq{Formula: '} . $self->Lexer->GetFormula() . qq{'\n} );
        print( qq{    RPN: '} . $self->Evaluator->GetRpn() . qq{'\n} );
    }

    if( $self->{APPCONFIG}->GetBRpn() ){
        print( $self->Evaluator->GetRpn() . "\n" );
    }elsif( $self->{APPCONFIG}->GetBVerboseOutput() ){
        print( qq{ Result: } . $self->Evaluator->ResultPrint() . "\n" );
    }else{
        print( $self->Evaluator->ResultPrint() . "\n" );
    }

    return 0;
}


package CAppConfig;
use strict;
use warnings 'all';

# CAppConfig コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{APPPATH} = shift( @_ );
    $self->{APPNAME} = shift( @_ );
    $self->{DEBUG} = shift( @_ );
    $self->{B_TEST} = shift( @_ );
    $self->{B_VERBOSEOUTPUT} = shift( @_ );
    $self->{B_RPN} = shift( @_ );
    $self->{B_IS_STDOUT_TTY} = shift( @_ );
    $self->{B_PRINT_USER_DEFINED} = shift( @_ );
    return $self;               # 無名ハッシュ参照を返す
}

sub SetDebug( $ )
{
    my $self = shift( @_ );
    $self->{DEBUG} = shift( @_ );
}
sub GetDebug( $ )
{
    my $self = shift( @_ );
    return $self->{DEBUG};
}

sub SetBTest( $ )
{
    my $self = shift( @_ );
    $self->{B_TEST} = shift( @_ );
}
sub GetBTest( $ )
{
    my $self = shift( @_ );
    return $self->{B_TEST};
}

sub SetBVerboseOutput( $ )
{
    my $self = shift( @_ );
    $self->{B_VERBOSEOUTPUT} = shift( @_ );
}
sub GetBVerboseOutput( $ )
{
    my $self = shift( @_ );
    return $self->{B_VERBOSEOUTPUT};
}

sub SetBRpn( $ )
{
    my $self = shift( @_ );
    $self->{B_RPN} = shift( @_ );
}
sub GetBRpn( $ )
{
    my $self = shift( @_ );
    return $self->{B_RPN};
}

sub SetBIsStdoutTty( $ )
{
    my $self = shift( @_ );
    $self->{B_IS_STDOUT_TTY} = shift( @_ );
}
sub GetBIsStdoutTty( $ )
{
    my $self = shift( @_ );
    return $self->{B_IS_STDOUT_TTY};
}

sub SetBPrintUserDefined( $ )
{
    my $self = shift( @_ );
    $self->{B_PRINT_USER_DEFINED} = shift( @_ );
}
sub GetBPrintUserDefined( $ )
{
    my $self = shift( @_ );
    return $self->{B_PRINT_USER_DEFINED};
}

package main;

use strict;
use warnings 'all';
use File::Basename;

my $opf = undef;

exit( &pl_main( @ARGV ) );


sub pl_main( @ )
{
    ## 初期化処理
    my $conf = &init_script();

    ## 引数解析
    &parse_arg( $conf, @_ );

    my $fEngine = FormulaEngine->new( $conf );
    my $status = $fEngine->Run( @main::expressions_raw );

    return $status;
}

##########
## 初期化処理
## Revision: 1.3
sub init_script()
{
    ### GLOBAL ###
    @main::expressions_raw = ();
    ##############

    my $apppath = dirname( $0 );
    my $appname = basename( $0 );
    my $debug = 0;
    my $bTest = 0;
    my $bVerboseOutput = 0;
    my $bRpn = 0;
    my $bIsStdoutTty = -t STDOUT;
    my $bPrintUserDefined = 0;

    my $config = CAppConfig->new( $apppath, $appname, $debug,
        $bTest, $bVerboseOutput, $bRpn, $bIsStdoutTty, $bPrintUserDefined );

    $opf = OutputFunc->new( $config, 'dbg' );

    return $config;
}

##########
## 引数解析
sub parse_arg()
{
    my $conf = shift( @_ );
    my @val = @_;

    ## 引数分のループを回す
    while( my $myparam = shift( @val ) ){

        ## アルファベットは1文字ずつ分割
        if( $myparam =~ s/^-([dhrvu])(\S+)$/-$1/o ){
            my $remainparam = "-$2";
            $opf->dPrintf( qq{\$myparam="%s", \$remainparam="%s"\n}, $myparam, $remainparam );
            unshift( @val, $remainparam );
        }

        ## デバッグモードOn
        if    ( $myparam eq '-d' || $myparam eq '--debug' ){
            $conf->SetDebug( 1 );
            $conf->SetBVerboseOutput( 1 );
        }elsif( $myparam eq '-h' || $myparam eq '--help' ){
            $opf->PrintHelp( 0 );
            exit( 0 );
        }elsif( $myparam eq '-r' || $myparam eq '--rpn' ){
            $conf->SetBRpn( 1 );
        }elsif( $myparam eq '-v' || $myparam eq '--verbose' ){
            $conf->SetBVerboseOutput( 1 );
        }elsif( $myparam eq '--version' ){
            $opf->PrintVersion();
            exit( 0 );
        }elsif( $myparam eq '-u' || $myparam eq '--user-defined' ){
            $conf->SetBPrintUserDefined( 1 );
        }elsif( $myparam eq '--test-test' ){
            $conf->SetBTest( 1 );
            $conf->SetBIsStdoutTty( 1 );
        }else{
            push( @main::expressions_raw, $myparam );
        }

        $opf->dPrintf( qq{arg="%s", \@val=%d\n},
            $myparam, scalar( @val ) );
    }
}
__END__

=pod

=encoding utf8

=head1 NAME

C - The Flat Text Calculator

=head1 DESCRIPTION

The B<c> script displays the result of the given expression.

=head1 SYNOPSIS

$ c [I<OPTIONS...>] I<EXPRESSIONS>

=head1 EXPRESSIONS

=head2 OPERANDS

=head3 Decimal:

0, -1, 100 ...

=head3 Hexadecimal:

0xf, -0x1, 0x0064 ...

=head3 Constant:

=over 4

=item PI

3.14159265358979

=item NOW

CURRENT-TIME

=item User-defined-file

".c.rc" should be placed in the same directory as "c script" or in "$HOME".

  [ .c.rc ]
  ## - ".c.rc" should be placed
  ##   in the same directory as "c script" or in "$HOME".
  ##
  ## - "c script" is not case-sensitive.
  ## - All keys are converted to lowercase.
  ## - If you create definitions with different case,
  ##   they will be overwritten by definitions loaded later.

  my %user_constant;

  ## ex.) $ c 'geo_distance_km( MADAGASCAR_COORD, GALAPAGOS_ISLANDS_COORD )'
  ##      14907.357977036
  $user_constant{MADAGASCAR_COORD} = 'deg2rad( -18.76694, 46.8691 )';
  $user_constant{GALAPAGOS_ISLANDS_COORD} = 'deg2rad( -0.3831, -90.42333 )';

  $user_constant{GOLDEN_RATIO} = '( ( 1 + sqrt( 5 ) ) / 2 )'; # 1.61803398874989

  return %user_constant;

=back

=head2 OPERATORS

+ - * / % ** | & ^ E<lt>E<lt> E<gt>E<gt> ~ ( , ) =

=head2 FUNCTIONS

abs, int, floor, ceil, rounddown, round, roundup, percentage, ratio_scaling, is_prime, prime_factorize, get_prime, gcd, lcm, ncr, min,
max, shuffle, first, slice, uniq, sum, prod, avg, add_each, mul_each, linspace, linstep, mul_growth, gen_fibo_seq, paper_size, rand, exp,
exp2, exp10, log, log2, log10, sqrt, pow, pow_inv, rad2deg, deg2rad, dms2rad, dms2deg, deg2dms, dms2dms, sin, cos, tan, asin, acos, atan,
atan2, hypot, angle_deg, dist_between_points, midpt_between_points, angle_between_points, geo_radius, radius_of_lat, geo_distance,
geo_distance_m, geo_distance_km, geo_azimuth, geo_dist_m_and_azimuth, geo_dist_km_and_azimuth, is_leap, age_of_moon, local2epoch, gmt2epoch,
epoch2local, epoch2gmt, sec2dhms, dhms2sec, ri2meter, meter2ri, mile2meter, meter2mile, nautical_mile2meter, meter2nautical_mile,
pound2gram, gram2pound, ounce2gram, gram2ounce, laptimer, timer, stopwatch, bpm, bpm15, bpm30, tachymeter, telemeter, telemeter_m,
telemeter_km

=head1 OPTIONS

=over 4

=item -d, --debug

  Enable debug output.

=item -v, --verbose

  The intermediate steps of the calculation will also be displayed.

=item -r, --rpn

  The expression will be displayed in Reverse Polish Notation,
  but the calculation result will not be shown.

  If you want to display the calculation result,
  please use the --verbose option as well.

=item -u, --user-defined

Outputs a list of user-defined values ​​defined in ".c.rc".

=item --version

Print the version of this script and Perl and exit.

=item -h, --help

  Display simple help and exit.

=back

=head1 ADVANCED USAGE

=head2 BASIC USE CASE

When you provide a calculation formula, it will display the result.

  $ c 123456-59+123.456*2=
  123643.912

Use parentheses if you want to control the order of operations.

  $ c '123456-(59+123.456)*2='
  123091.088

Using the I<-v> or I<--verbose> option will display the intermediate calculations as well.

  $ c 123456-59+123.456*2= -v
  123456 - 59 = 123397
  123.456 * 2 = 246.912
  123397 + 246.912 = 123643.912
  Formula: '123456 - 59 + 123.456 * 2 ='
      RPN: '123456 59 - 123.456 2 * +'
   Result: 123643.912

You can also specify calculation formulas written in UTF-8.

  $ c １２３，４５６－５９ ＋ １２３．４５６＊２＝
  123643.912

If you simply want to format a mathematical formula that you found on the web,
please use the I<-v> or I<--verbose> option switch.

  $ c '２ ＰＩ １０＝' --verbose
  2 * 3.14159265358979 = 6.28318530717958
  6.28318530717958 * 10 = 62.8318530717958
  Formula: '2 * 3.14159265358979 * 10 ='    <--- HERE
      RPN: '2 3.14159265358979 * 10 *'
   Result: 62.8318530717958

Several functions are also available.

  $ c 'sqrt( power( 1920, 2 ) + power( 1080, 2 ) ) ='
  2202.9071700823

Example of using the functions.

What combinations involve choosing 4 out of 6 ?

  $ c 'nCr( 6, 4 )'
  15

Alternative Method

  $ c 'prod( linstep( 6, -1, 4 ) ) / prod( linstep( 4, -1, 4 ) )' -v
  linstep( 6, -1, 4 ) = ( 6, 5, 4, 3 )
  prod( 6, 5, 4, 3 ) = 360
  linstep( 4, -1, 4 ) = ( 4, 3, 2, 1 )
  prod( 4, 3, 2, 1 ) = 24
  360 / 24 = 15
  Formula: 'prod( linstep( 6, -1, 4 ) ) / prod( linstep( 4, -1, 4 ) ) ='
      RPN: '# # 6 -1 4 linstep prod # # 4 -1 4 linstep prod /'
   Result: 15

The candidate values ​​are 10 equally spaced values ​​from 0 to 90 degrees,
and the radians of an arbitrarily selected value are calculated.

  $ c 'deg2rad( first( shuffle( linspace( 0, 90, 10 ) ) ) )' -v
  linspace( 0, 90, 10 ) = ( 0, 10, 20, 30, 40, 50, 60, 70, 80, 90 )
  shuffle( 0, 10, 20, 30, 40, 50, 60, 70, 80, 90 ) = ( 10, 80, 60, 40, 30, 90, 50, 70, 20, 0 )
  first( 10, 80, 60, 40, 30, 90, 50, 70, 20, 0 ) = 10
  deg2rad( 10 ) = 0.174532925199433
  Formula: 'deg2rad( first( shuffle( linspace( 0, 90, 10 ) ) ) ) ='
      RPN: '# # # # 0 90 10 linspace shuffle first deg2rad'
   Result: 0.174532925199433

If you specify the operands in hexadecimal or use bitwise operators,
the calculation result will also be displayed in hexadecimal.

  # Bitwise AND
  $ c '0xfc & 0x3f'
  60 [ = 0x3C ]

  # Bitwise OR
  $ c '0xfc | 0x3f'
  255 [ = 0xFF ]

  # Bitwise Exclusive OR
  $ c '0xfc ^ 0x3f'
  195 [ = 0xC3 ]

  # Bitwise left shift
  $ c '0x3c << 1'
  120 [ = 0x78 ]

  # Bitwise right shift
  $ c '0x3c >> 1'
  30 [ = 0x1E ]

  # Bitwise Inversion
  $ c '~0x1 & 0x3f'
  62 [ = 0x3E ]

There is no option switch to display the calculation results in hexadecimal.
However, you can display it by performing a bitwise 'I<|[OR]>' operation with 0.

  $ c '100|0'
  100 [ = 0x64 ]

[ radical (of n) ] Eliminate duplicates of each prime factor and take the product:

  ## Factorize any given number into prime factors...
  $ c 'prime_factorize( 4428 )'
  ( 2, 2, 3, 3, 3, 41 )

  ## Eliminate duplicates...
  $ c 'uniq( prime_factorize( 4428 ) )'
  ( 2, 3, 41 )

  ## Take the product of each value
  $ c 'prod( uniq( prime_factorize( 4428 ) ) )'
  246

You can also:

  ## Generate prime numbers in 16-bit width
  $ c 'prod( get_prime( 16 ), get_prime( 16 ) )'
  1691574281

  ## check
  $ c 'pf( 1691574281 )|0'  ## pf() is an alias for prime_factorize().
  ( 29303, 57727 ) [ = ( 0x7277, 0xE17F ) ]

=head2 STANDARD INPUT (STDIN) MODE

If no calculation formula is specified as an argument,
the program will wait for input from STDIN.
To exit, send an End Of File signal (for example, press Ctrl + D).

  $ c
  ^D

Example of running with the I<-v> or I<--verbose> option:

  $ c --verbose
  0.22*10**(-6)=    <-- INPUT FROM KEYBOARD
  10 ** -6 = 1e-06
  0.22 * 1e-06 = 2.2e-07
  Formula: '0.22 * 10 ** ( -6 ) ='
      RPN: '0.22 10 -6 ** *'
   Result: 0.00000022 [ = 2.2e-07 ]
  <-- INPUT FROM KEYBOARD

  sqrt(2)=    <-- INPUT FROM KEYBOARD
  sqrt( 2 ) = 1.4142135623731
  Formula: 'sqrt( 2 ) ='
      RPN: '# 2 sqrt'
   Result: 1.4142135623731
  ^D    <-- INPUT FROM KEYBOARD

By constructing the calculation formula first,
you can easily repeat similar calculations.
For example, when using B<sed>:

  $ cat - | sed -u 's/^\(.*\)$/round( (\1+0) * 1.1 , 0 ) =/'
  1028    <-- INPUT FROM KEYBOARD
  round( (1028+0) * 1.1 , 0 ) =
  <-- INPUT FROM KEYBOARD
  round( (+0) * 1.1 , 0 ) =
  ^D    <-- INPUT FROM KEYBOARD

The formula looks fine, so let's pipe it into the I<c> script:

  $ !! | c
  cat - | sed -u 's/^\(.*\)$/round( (\1+0) * 1.1 , 0 ) =/' | c
  1000
  1100    <-- RESULT
  500
  550     <-- RESULT
  998
  1098    <-- RESULT
  ^D

It might be convenient to register it as an alias:

  ex.) ~/.bashrc
  alias ctax="cat - | sed -u 's/^\(.*\)$/round( (\1+0) * 1.1 , 0 ) =/' | c"

=head2 TIME CALCULATIONS

Current time in seconds since the epoch:

  $ c now
  1764003197

In an easy-to-understand format:

  $ c 'epoch2local( now )'
  ( 2025, 11, 25, 1, 53, 17 )   # 2025-11-25 01:53:17

Time elapsed since a specified date:

  $ c 'sec2dhms( now - local2epoch( 2011, 03, 11, 14, 46 ) )'
  ( 5372, 15, 51, 18 )  # 5372 days, 15 hours, 51 minutes, and 18 seconds

1 hour and 45 minutes before two days later:

  $ c 'epoch2local( local2epoch( 2020, 1, 1, 15, 0, 0 ) + dhms2sec( 2, -1, -45 ) )'
  ( 2020, 1, 3, 13, 15, 0 ) # Jan. 3, 2020 at 13:15:00.

If it takes 1 hour and 18 minutes to make 3, when will 15 be completed?:

  $ c 'epoch2local(
         local2epoch( 2025, 11, 25, 09, 00 ) +
         ratio_scaling( 3, dhms2sec( 0, 1, 18 ), 15 )
       )'
  ( 2025, 11, 25, 15, 30, 0 )   # Pace to complete on Nov. 25, 2025 at 15:30:00.

=head2 COORDINATE CALCULATION

I think this is a feature that anyone who likes looking at maps will want to use.

Here we use the following coordinates (latitude and longitude):

  ex)
  Madagascar:        degrees: -18.76694, 46.8691
  Galapagos Islands: degrees: -0.3831, -90.42333

Calculate the distance between two points.

  $ c 'geo_distance_km(
         deg2rad( -18.76694, 46.8691 ),
         deg2rad( -0.3831, -90.42333 )
       ) ='
  14890.6974607313  # 14891 km

The straight-line distance between Madagascar and the Galapagos Islands was found to be 14,907 km.

If you want to specify latitude and longitude in DMS, use dms2rad().
Be sure to include the sign if the value is negative.

  # gd_km() is an alias for geo_distance_km().
  $ c 'gd_km(
         dms2rad( -18, -46,  -0.984000000006233 ), dms2rad( 46, 52, 8.76000000001113 ),
         dms2rad(  -0, -22, -59.16 ), dms2rad( -90, -25, -23.9880000000255 ) ) ='
  14890.6974607313  # 14891 km

The direction can also be calculated.

  $ c 'geo_azimuth( deg2rad( -18.76694, 46.8691, -0.3831, -90.42333 ) )'
  250.3084344602    # About west-southwest ( WSW )

It may be more intuitive to represent the direction as a value from 0 to 4 (N-E-S-W) rather than 0 to 360 degrees.

  $ c 'ratio_scaling(
         360,
         geo_azimuth( deg2rad( -18.76694, 46.8691, -0.3831, -90.42333 ) ),
         4
       )'
  2.78120482733556  # Direction Index (2.78 is between South(2) and West(3), closer to West)
                    # Approx: West-Southwest (WSW)

If you record the calculation as shown below,
you can save not only the calculation results but also the calculation method,
which I think will be easy to reuse and convenient.
This is one of the reasons why I wrote this tool.

Calculates distance and direction simultaneously.

  $ Madagascar_coord='-18.76694, 46.8691'
  $ Galapagos_Islands_coord='-0.3831, -90.42333'
  $ c "gd_km_azm(
         deg2rad(
           $Madagascar_coord, $Galapagos_Islands_coord
         )
       )"
  ( 14890.6974607313, 250.3084344602 )  # Dist: 14891 km, Brg: 250 degrees (WSW)
  $

The B<c> script was created with the following in mind:

- It will run with just Perl.

- The calculation formulas are easy to understand even when read later.

=head1 OPERATORS

=over 8

=item C<+>

Addition.
C<1 + 2> -> C<3>.

=item C<->

Subtraction.
C<3 - 2> -> C<1>.

=item C<*>

Multiplication.
C<1 * 2> -> C<2>.

=item C</>

Division.
C<1 / 2> -> C<0.5>.

=item C<%>

Modulo arithmetic.
C<5 % 3> -> C<2>.

=item C<**>

Exponentiation.
C<2 ** 3> -> C<8>. Similarly, C<pow( 2, 3 )>.

=item C<|>

Bitwise OR.
C<0x2 | 0x4> -> C<6 [ = 0x6 ]>.

=item C<&>

Bitwise AND.
C<0x6 & 0x4> -> C<4 [ = 0x4 ]>.

=item C<^>

Bitwise Exclusive OR.
C<0x6 ^ 0x4> -> C<2 [ = 0x2 ]>.

=item C<E<lt>E<lt>>

Bitwise left shift.
C<0x6 E<lt>E<lt> 1> -> C<12 [ = 0xC ]>.

=item C<E<gt>E<gt>>

Bitwise right shift.
C<0x6 E<gt>E<gt> 1> -> C<3 [ = 0x3 ]>.

=item C<~>

Bitwise Inversion.
C<~0> -> C<0xFFFFFFFFFFFFFFFFFF>.

=item C<(>

A symbol that controls the priority of calculations.

=item C<,>

The separator that separates function arguments.

=item C<)>

A symbol that controls the priority of calculations.

=item C<=>

Equals sign.
In I<c> script, it has the meaning of terminating the calculation formula,
but it is not necessary.
C<1 + 2 =>.
Similarly, C<1 + 2>.

=back

=head1 FUNCTIONS

=over 8

=item C<abs>

abs( I<N1> [,.. ] ).
Returns the absolute value of its argument.
[Perl Native]

  $ c 'abs( -1.2, 1.2 )'
  ( 1.2, 1.2 )

=item C<int>

int( I<N1> [,.. ] ).
Returns the integer portion of I<N>.
[Perl Native]

  $ c 'int( -1.2, 1.2 )'
  ( -1, 1 )

=item C<floor>

floor( I<N1> [,.. ] ).
Returning the largest integer value less than or equal to the numerical argument.
[POSIX]

  $ c 'floor( -1.2, 1.2 )'
  ( -2, 1 )

=item C<ceil>

ceil( I<N1> [,.. ] ).
Returning the smallest integer value greater than or equal to the given numerical argument.
[POSIX]

  $ c 'ceil( -1.2, 1.2 )'
  ( -1, 2 )

=item C<rounddown>

rounddown( I<NUMBER1> [ ,.. ], I<DECIMAL_PLACES> ).
Returns the value of I<NUMBER1> truncated to I<DECIMAL_PLACES>.

  $ c 'rounddown( -1.2, 1.2, 0 )'
  ( -1, 1 )

=item C<round>

round( I<NUMBER1> [ ,.. ], I<DECIMAL_PLACES> ).
Returns the value of I<NUMBER1> rounded to I<DECIMAL_PLACES>

  $ c 'round( -1.4, -1.5, 1.4, 1.5, 0 )'
  ( -1, -2, 1, 2 )

=item C<roundup>

roundup( I<NUMBER1> [ ,.. ], I<DECIMAL_PLACES> ).
Returns the value of I<NUMBER1> rounded up to I<DECIMAL_PLACES>.

  $ c 'roundup( -1.2, 1.2, 0 )'
  ( -2, 2 )

=item C<percentage>

percentage( I<NUMERATOR>, I<DENOMINATOR> [, I<DECIMAL_PLACES> ] ).
Returns the percentage, rounding the number if I<DECIMAL_PLACES> is specified.
alias: pct().

  $ c 'percentage( 1, 6 )'
  16.6666666666667
  $ c 'percentage( 1, 6, 2 )'
  16.67

=item C<ratio_scaling>

ratio_scaling( I<A>, I<B>, I<C> [, I<DECIMAL_PLACES> ] ).
When I<A>:I<B>, return the value of I<X> in I<A>:I<B>=I<C>:I<X>.
Rounding the number if I<DECIMAL_PLACES> is specified.
alias: rs().

If it takes 66 seconds to make 5 units, what will be the production quantity after 3600 seconds (1 hour)?:

  $ c 'ratio_scaling( 66, 5, 3600 )'
  272.727272727273
  $ c 'ratio_scaling( 66, 5, 3600, 1 )'
  272.7

=item C<is_prime>

is_prime( I<NUM1> [,.. ] ).
Prime number test.
Returns 1 if I<NUM> is prime, otherwise returns 0.

  $ c 'is_prime( 1576770818 )'
  0
  $ c 'is_prime( 1576770817 )'
  1

=item C<prime_factorize>

prime_factorize( I<NUM> ).
Do prime factorization. I<NUM> is an integer greater than or equal to 2.
alias: pf().

  $ c 'prime_factorize( 1576770818 )'
  ( 2, 7, 112626487 )

  $ c 'prime_factorize( 1576770817 )'
  1576770817

=item C<get_prime>

get_prime( I<BIT_WIDTH> ).
Returns a random prime number within the range of I<BIT_WIDTH>,
where I<BIT_WIDTH> is an integer between 4 and 32, inclusive.

  $ c 'get_prime( 32 )'
  1576770817

=item C<gcd>

gcd( I<NUMBER1>,.. ).
Returns the greatest common divisor (GCD),
which is the largest positive integer that divides each of the operands.
[Math::BigInt::bgcd()]

  $ c 'gcd( 402, 670, 804 )'
  134

=item C<lcm>

lcm( I<NUMBER1>,.. ).
Returns the least common multiple (LCM).
[Math::BigInt::blcm()]

  $ c 'lcm( 402, 670, 804 )'
  4020

=item C<ncr>

nCr( I<N>, I<R> ).
I<N> Choose I<R>. A combination of I<R> items selected from I<N> items.
I<N> is a non-negative integer.
I<R> is a positive integer.

Number of combinations of choosing 3 out of 5:

  $ c 'nCr( 5, 3 )'
  10

=item C<min>

min( I<NUMBER1>,.. ).
Returns the entry in the list with the lowest numerical value.
[List::Util]

  $ c 'min( 402, 670, 804 )'
  402

=item C<max>

max( I<NUMBER1>,.. ).
Returns the entry in the list with the highest numerical value.
[List::Util]

  $ c 'max( 402, 670, 804 )'
  804

=item C<shuffle>

shuffle( I<NUMBER1>,.. ).
Returns the values of the input in a random order.
[List::Util]

  $ c 'shuffle( 402, 670, 804 )'
  ( 804, 402, 670 )

=item C<first>

first( I<NUMBER1>,.. ).
Returns the head of the set.
Same as slice( I<NUMBER1>,.. , 0, 1 ).

  $ c 'first( 402, 670, 804 )'
  402

=item C<slice>

slice( I<NUMBER1>,.., I<OFFSET>, I<LENGTH> ).
Extracts elements specified by I<OFFSET> and I<LENGTH> from a set.

Extract only the date (first three):

  $ c 'slice( ( 2025, 12, 17, 22, 13, 14 ), 0, 3 )'
  ( 2025, 12, 17 )

=item C<uniq>

uniq( I<NUMBER1>,.. ).
Filters a list of values to remove subsequent duplicates,
as judged by a DWIM-ish string equality or "undef" test.
Preserves the order of unique elements, and retains the first value of any duplicate set.
[List::Util]

  $ c 'uniq( 2, 3, 2, 3, 67, 3 )'
  ( 2, 3, 67 )

=item C<sum>

sum( I<NUMBER1>,.. ).
Returns the numerical sum of all the elements in the list.
[List::Util]

  $ c 'sum( 1, 2, 3, 4 )'
  10

=item C<prod>

prod( I<NUMBER1>,.. ).
Returns the product of each value.

  $ c 'prod( 1, 2, 3, 4 )'
  24

=item C<avg>

avg( I<NUMBER1>,.. ).
Returns the average value of all elements in a list.

  $ c 'avg( 1, 2, 3, 4 )'
  2.5

=item C<add_each>

add_each( I<NUMBER1>,.. , I<DELTA> ). Add each number.

  $ c 'add_each( 100, 200, -10 )'
  ( 90, 190 )

=item C<mul_each>

mul_each( I<NUMBER1>,.. , I<FACTOR> ). Multiply each number.

  $ c 'mul_each( 100, 200, 2 )'
  ( 200, 400 )

Estimate the size (pixels) of an A4 sheet of paper (millimeters) scanned at 300 dpi:

  $ c 'mul_each( 210, 297, ( 1 / 25.4 ) * 300 )'
  ( 2480.31496062992, 3507.87401574803 )

=item C<linspace>

linspace( I<START>, I<END>, I<LENGTH> [, I<DECIMAL_PLACES> ] ).
Generates a list of evenly spaced numbers from I<START> to I<END>.
Returns a sequence of numbers of size I<LENGTH>.
I<LENGTH> is an integer greater than or equal to 2.
Rounding the number if I<DECIMAL_PLACES> is specified.

Divide the range from 0x33 to 0xCC into 5 parts:

  $ c 'linspace( 0x33, 0xcc, 5 )'
  ( 51, 89.25, 127.5, 165.75, 204 ) [ = ( 0x33, 89.25, 127.5, 165.75, 0xCC ) ]
  $ c 'linspace( 0x33, 0xcc, 5, 0 )'
  ( 51, 89, 128, 166, 204 ) [ = ( 0x33, 0x59, 0x80, 0xA6, 0xCC ) ]

=item C<linstep>

linstep( I<START>, I<DELTA>, I<LENGTH> ).
Generates a list of I<LENGTH> numbers that increase from I<START> by I<DELTA>.
Returns the sequence of numbers starting at I<START> and of size I<LENGTH>.
I<LENGTH> is an integer greater than or equal to 1.

A sequence of 10 numbers that decrease by 2 from 101:

  $ c 'linstep( 101, -2, 10 )'
  ( 101, 99, 97, 95, 93, 91, 89, 87, 85, 83 )

=item C<mul_growth>

mul_growth( I<START>, I<FACTOR>, I<LENGTH> ).
Starting from I<START>, we multiply the value by I<FACTOR> and add it to the sequence.
Returns the sequence of numbers starting at I<START> and of size I<LENGTH>.
I<LENGTH> is an integer greater than or equal to 1.

  $ c 'mul_growth( 100, 0.9, 8 )'
  ( 100, 90, 81, 72.9, 65.61, 59.049, 53.1441, 47.82969 )

=item C<gen_fibo_seq>

gen_fibo_seq( I<A>, I<B>, I<LENGTH> ).
Generates the Generalized Fibonacci Sequence.
Returns the sequence of numbers starting at I<A>, I<B> and of size I<LENGTH>.
I<LENGTH> is an integer greater than or equal to 2.

Generate the Lucas sequence:

  $ c 'gen_fibo_seq( 2, 1, 10 )'
  ( 2, 1, 3, 4, 7, 11, 18, 29, 47, 76 )

=item C<paper_size>

paper_size( SIZE [, TYPE ] ).
Returns the following information in this order:
length of short side, length of long side (in mm).
SIZE is a non-negative integer.
If TYPE is omitted or 0 is specified, it will be A size.
If TYPE is specified as 1, it will be B size ( Japan's unique standards ).

What are the dimensions of A4 size ?:

  $ c 'paper_size( 4 )'
  ( 210, 297 )  # Short: 210 mm, Long: 297 mm

What are the dimensions of B4 size ?: ( B size is a standard unique to Japan )

  $ c 'paper_size( 4, 1 )'
  ( 257, 364 )  # Short: 257 mm, Long: 364 mm

Area of ​​A5 size:

  $ c 'prod( paper_size( 5 ) )'
  31080         # Area: 31,080 mm2

=item C<rand>

rand( I<N> ).
Returns a random fractional number greater than or equal to 0 and less than the value of I<N>.
[Perl Native]

A random number between 0 and 6:

  $ c 'rand( 6 )'
  4.11497904963291

0 or 1 or 2 or 3 or 4 or 5:

  $ c 'int( rand( 6 ) )'
  2

=item C<exp>

exp( I<N1> [,.. ] ).
Returns e (the natural logarithm base) to the power of I<N>.
[Perl Native]

The base of natural logarithms e (Napier's constant):

  $ c 'exp( 1 )'
  2.71828182845905

=item C<log>

log( I<N1> [,.. ] ).
Returns the natural logarithm (base e) of I<N>.
[Perl Native]

exp(1) is the base of the natural logarithm ( Napier's constant ):

  $ c 'log( 100 )'
  4.60517018598809
  $ c 'exp( log( 100 ) )'
  100
  $ c 'pow( exp( 1 ), log( 100 ) )'
  100

A product of antilogarithms is transformed into a sum of logarithms:

  $ c 'log( 200 * 300 )'
  11.0020998412042
  $ c 'log( 200 ) + log( 300 )'
  11.0020998412042

The quotient of real numbers is the difference of logarithms:

  $ c 'log( 200 / 300 )'
  -0.405465108108164
  $ c 'log( 200 ) - log( 300 )'
  -0.405465108108165

Antilogarithmic exponents are converted to constant multiples of the logarithm:

  $ c 'log( power( 200, 100 ) )'
  529.831736654804
  $ c '100 * log( 200 )'
  529.831736654804

The reciprocal of an antilogarithm reverses the sign of the logarithm.

  $ c 'log( 1 / 100 )'
  -4.60517018598809
  $ c 'log( power( 100, -1 ) )'
  -4.60517018598809
  $ c '-1 * log( 100 )'
  -4.60517018598809

=item C<exp2>

exp2( I<N1> [,.. ] ).
Returns the base 2 raised to the power N.

  $ c 'exp2( 8, 16, 32 )'
  ( 256, 65536, 4294967296 )

The following three expressions are equivalent:

  $ c 'exp2( 10 )'
  1024
  $ c 'exp( 10 * log( 2 ) )'
  1024
  $ c 'pow( 2, 10 )'
  1024

=item C<log2>

log2( I<N1> [,.. ] ).
Returns the common logarithm to the base 2.

  $ c 'log2( 256, 65536, 4294967296 )'
  ( 8, 16, 32 )

The following three expressions are equivalent:

  $ c 'log2( 1024 )'
  10
  $ c 'log( 1024 ) / log( 2 )'
  10
  $ c 'pow_inv( 1024, 2 )'
  10

=item C<exp10>

exp10( I<N1> [,.. ] ).
Returns the base 10 raised to the power N.

  $ c 'exp10( 1, 2, 3 )'
  ( 10, 100, 1000 )

The following three expressions are equivalent:

  $ c 'exp10( 5 )'
  100000
  $ c 'exp( 5 * log( 10 ) )'
  100000
  $ c 'pow( 10, 5 )'
  100000

=item C<log10>

log10( I<N1> [,.. ] ).
Returns the common logarithm to the base 10.

  $ c 'log10( 10, 100, 1000 )'
  ( 1, 2, 3 )

The following three expressions are equivalent:

  $ c 'log10( 10000 )'
  4
  $ c 'log( 10000 ) / log( 10 )'
  4
  $ c 'pow_inv( 10000, 10 )'
  4

=item C<sqrt>

sqrt( I<N1> [,.. ] ).
Return the positive square root of I<N>.
Works only for non-negative operands.
[Perl Native]

  $ c 'sqrt( 9, 16, 25 )'
  ( 3, 4, 5 )

=item C<pow>

pow( I<A>, I<B> ).
Exponentiation.
"pow( 2, 3 )" -> 8.
Similarly, "2 ** 3".
[Perl Native]

  $ c 'pow( 2, 3 )'
  8

=item C<pow_inv>

pow_inv( I<A>, I<B> ).
Returns the power of I<A> to which I<B> is raised.

  $ c 'pow_inv( 8, 2 )'
  3

=item C<rad2deg>

rad2deg( I<RADIANS> [, I<RADIANS>..] ) -> ( I<DEGREES> [, I<DEGREES>..] ).
[Math::Trig]

  $ c 'rad2deg( 2.50620553940126 )'
  143.595

=item C<deg2rad>

deg2rad( I<DEGREES> [, I<DEGREES>..] ) -> ( I<RADIANS> [, I<RADIANS>..] ).
[Math::Trig]

  $ c 'deg2rad( 143.595 )'
  2.50620553940126

=item C<dms2rad>

dms2rad( I<DEG>, I<MIN>, I<SEC> [, I<DEG>, I<MIN>, I<SEC> ..] ) -> ( I<RADIANS> [, I<RADIANS>..] ).

  $ c 'dms2rad( 143, 35, 42.0000000000002 )'
  2.50620553940126

=item C<dms2deg>

dms2deg( I<DEG>, I<MIN>, I<SEC> [, I<DEG>, I<MIN>, I<SEC> ..] ) -> ( I<DEGREES> [, I<DEGREES>..] ).

  $ c 'dms2deg( 143, 35, 42.0000000000002 )'
  143.595

=item C<deg2dms>

deg2dms( I<DEGREES> [, I<DEGREES>..] ) -> ( I<DEG>, I<MIN>, I<SEC> [, I<DEG>, I<MIN>, I<SEC> ..] ).

  $ c 'deg2dms( 143.595 )'
  ( 143, 35, 41.9999999999959 )

=item C<dms2dms>

dms2dms( I<DEG>, I<MIN>, I<SEC> [, I<DEG>, I<MIN>, I<SEC> ..] ) -> ( I<DEG>, I<MIN>, I<SEC> [, I<DEG>, I<MIN>, I<SEC> ..] ).

  $ c 'dms2dms( 143, 35.7, 0 )'
  ( 143, 35, 42.0000000000002 )

=item C<sin>

sin( I<RADIANS> ).
Returns the sine of I<RADIANS>.
[Perl Native]

=item C<cos>

cos( I<RADIANS> ).
Returns the cosine of I<RADIANS>.
[Perl Native]

=item C<tan>

tan( I<RADIANS> ).
Returns the tangent of I<RADIANS>.
[Math::Trig]

=item C<asin>

asin( I<RATIO> ).
The arcus (also known as the inverse) functions of the sine.
[Math::Trig]

  $ c 'rad2deg( asin( 1 / 2 ) )'
  30

=item C<acos>

acos( I<RATIO> ).
The arcus (also known as the inverse) functions of the cosine.
[Math::Trig]

  $ c 'rad2deg( acos( 1 / 2 ) )'
  60

=item C<atan>

atan( I<RATIO> ).
The arcus (also known as the inverse) functions of the tangent.
[Math::Trig]

  $ c 'rad2deg( atan( 1 / 1 ) )'
  45

=item C<atan2>

atan2( I<Y>, I<X> ).
The principal value of the arc tangent of I<Y> / I<X>.
[Math::Trig]

  $ c 'rad2deg( atan2( 1, 1 ) )'
  45

=item C<hypot>

hypot( I<X>, I<Y> ).
Equivalent to "sqrt( I<X> * I<X> + I<Y> * I<Y> )" except more stable on very large or very small arguments.
[POSIX]

  $ c 'hypot( 3, 4 )'
  5

=item C<angle_deg>

angle_deg( I<X>, I<Y> [, I<IS_AZIMUTH> ] ).
Returns the straight line distance from (0,0) to (I<X>,I<Y>).
Returns the standard mathematical angle (0 degrees = east, counterclockwise).
If I<IS_AZIMUTH> is set to true, returns the angle (0 degrees = north, clockwise).

  $ c 'angle_deg( 3, 4 )'
  53.130102354156

=item C<dist_between_points>

dist_between_points( I<X1>, I<Y1>, I<X2>, I<Y2> ) or dist_between_points( I<X1>, I<Y1>, I<Z1>, I<X2>, I<Y2>, I<Z2> ).
Returns the straight-line distance from (I<X1>,I<Y1>) to (I<X2>,I<Y2>) or from (I<X1>,I<Y1>,I<Z1>) to (I<X2>,I<Y2>,I<Z2>).
alias: dist().

  $ c 'dist_between_points( 100, 10, 200, 110 )'
  141.42135623731

  $ c 'dist_between_points( 100, 10, 50, 200, 110, 150 )'
  173.205080756888

=item C<midpt_between_points>

midpt_between_points( I<X1>, I<Y1>, I<X2>, I<Y2> ) or midpt_between_points( I<X1>, I<Y1>, I<Z1>, I<X2>, I<Y2>, I<Z2> ).
Returns the coordinates of the midpoint between (I<X1>,I<Y1>) and (I<X2>,I<Y2>), or (I<X1>,I<Y1>,I<Z1>) and (I<X2>,I<Y2>,I<Z2>).
alias: midpt().

  $ c 'midpt_between_points( 100, 10, 200, 110 )'
  ( 150, 60 )

  $ c 'midpt_between_points( 100, 10, 50, 200, 110, 150 )'
  ( 150, 60, 100 )

=item C<angle_between_points>

angle_between_points( I<X1>, I<Y1>, I<X2>, I<Y2> [, I<IS_AZIMUTH> ] ) or angle_between_points( I<X1>, I<Y1>, I<Z1>, I<X2>, I<Y2>, I<Z2> [, I<IS_AZIMUTH> ] ).
Returns the angle from (I<X1>,I<Y1>) to (I<X2>,I<Y2>) or the horizontal and vertical angles from (I<X1>,I<Y1>,I<Z1>) to (I<X2>,I<Y2>,I<Z2>).
Angles are in degrees.
Returns the standard mathematical angle (0 degrees = East, counter-clockwise).
If I<IS_AZIMUTH> is set to true, the horizontal angle is returned (0 degrees = north, clockwise).
alias: angle().

  $ c 'angle_between_points( 100, 10, 150, 110 )'
  63.434948822922

  $ c 'angle_between_points( 100, 10, 50, 150, 110, 150 )'
  ( 63.434948822922, 41.8103148957786 )

I<IS_AZIMUTH> is set to true

  $ c 'angle_between_points( 100, 10, 150, 110, 1 )'
  26.565051177078

  $ c 'angle_between_points( 100, 10, 50, 150, 110, 150, 1 )'
  ( 26.565051177078, 41.8103148957786 )

=item C<geo_radius>

geo_radius( I<LAT> ).
Given a latitude (in radians),
returns the distance from the center of the Earth to its surface (in meters).

What is the radius of the equator (0 degrees latitude)?

  $ c 'geo_radius( deg2rad( 0 ) )'
  6378137   # 6,378,137 m

=item C<radius_of_lat>

radius_of_lat( I<LAT> ).
Given a latitude (in radians), returns the radius of that parallel (in meters).

Radius of the parallel at 45 degrees latitude (distance of 1 radian):

  $ c 'radius_of_lat( deg2rad( 45 ) )'
  4517590.87888605  # 4,517,590.88 m

=item C<geo_distance>

geo_distance( I<A_LAT>, I<A_LON>, I<B_LAT>, I<B_LON> ).
Calculates and returns the distance (in meters) from I<A> to I<B>.
Latitude and longitude must be specified in radians.
Same as geo_distance_m().

  $ TOKYO_ST='35.68129, 139.76706'
  $ OSAKA_ST='34.70248, 135.49595'
  $ c "geo_distance( deg2rad( $TOKYO_ST, $OSAKA_ST ) )"
  403054.141024738  # 403,054.14 m

=item C<geo_distance_m>

geo_distance_m( I<A_LAT>, I<A_LON>, I<B_LAT>, I<B_LON> ).
Calculates and returns the distance (in meters) from I<A> to I<B>.
Latitude and longitude must be specified in radians.
Same as geo_distance().
alias: gd_m().

  $ TOKYO_ST='35.68129, 139.76706'
  $ OSAKA_ST='34.70248, 135.49595'
  $ c "geo_distance_m( deg2rad( $TOKYO_ST, $OSAKA_ST ) )"
  403054.141024738  # 403,054.11 m

=item C<geo_distance_km>

geo_distance_km( I<A_LAT>, I<A_LON>, I<B_LAT>, I<B_LON> ).
Calculates and returns the distance (in kilometers) from I<A> to I<B>.
Latitude and longitude must be specified in radians.
Same as geo_distance_m() / 1000.
alias: gd_km().

  $ TOKYO_ST='35.68129, 139.76706'
  $ OSAKA_ST='34.70248, 135.49595'
  $ c "geo_distance_km( deg2rad( $TOKYO_ST, $OSAKA_ST ) )"
  403.054141024738  # 403.05 km

=item C<geo_azimuth>

geo_azimuth( A_LAT, A_LON, B_LAT, B_LON ).
Returns the geographic azimuth (bearing) in degrees from A to B.
Note: 0 degrees is North, 90 degrees is East (clockwise).
Input: Latitude/Longitude in radians.
alias: gazm().

  $ c 'geo_azimuth( deg2rad( 35.68129, 139.76706 ), dms2rad( 33, 27, 56, 130, 10, 32 )  )'
  257.090172330251

=item C<geo_dist_m_and_azimuth>

geo_dist_m_and_azimuth( A_LAT, A_LON, B_LAT, B_LON ).
Returns the distance (in meters) and bearing (in degrees) from A to B.
Latitude and longitude must be specified in radians.
North is 0 degrees.
alias: gd_m_azm().

  $ c 'geo_dist_m_and_azimuth( deg2rad( 35.68129, 139.76706 ), dms2rad( 33, 27, 56, 130, 10, 32 )  )'
  ( 911639.540768677, 257.090172330251 )    # 911,639.54 m ; 257 degrees

=item C<geo_dist_km_and_azimuth>

geo_dist_km_and_azimuth( A_LAT, A_LON, B_LAT, B_LON ).
Returns the distance (in kilometers) and bearing (in degrees) from A to B.
Latitude and longitude must be specified in radians.
North is 0 degrees.
alias: gd_km_azm().

  $ c 'geo_dist_km_and_azimuth( deg2rad( 35.68129, 139.76706 ), dms2rad( 33, 27, 56, 130, 10, 32 )  )'
  ( 911.639540768677, 257.090172330251 )    # 911.64 km ; 257 degrees

=item C<is_leap>

is_leap( I<YEAR1> [,.. ] ).
Leap year test: Returns 1 if I<YEAR> is a leap year, 0 otherwise.

  $ c 'is_leap( 2024 )'
  1
  $ c 'is_leap( 2025 )'
  0

Evaluate together:

  $ c 'is_leap( 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000, 2100 )'
  ( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0 )

=item C<age_of_moon>

age_of_moon( I<Y>, I<m>, I<d> ).
Simple calculation of the age of the moon.
Maximum deviation of about 2 days.

  $ c 'age_of_moon( 2025, 12, 5 )'
  15    # Moon's age is 15 days

Today's Moon Age:

  $ c 'age_of_moon( slice( epoch2local( now ), 0, 3 ) )' -v
  epoch2local( 1764935943 ) = ( 2025, 12, 5, 20, 59, 3 )
  slice( 2025, 12, 5, 20, 59, 3, 0, 3 ) = ( 2025, 12, 5 )
  age_of_moon( 2025, 12, 5 ) = 15
  Formula: 'age_of_moon( slice( epoch2local( 1766677137 ), 0, 3 ) ) ='
      RPN: '# # # 1764935943 epoch2local 0 3 slice age_of_moon'
   Result: 15

=item C<local2epoch>

local2epoch( I<Y>, I<m>, I<d> [, I<H>, I<M>, I<S> ] ).
Returns the local time in seconds since the epoch.
alias: l2e().

  $ c 'local2epoch( 2025, 1, 2, 03, 40, 50 )'
  1735756850

=item C<gmt2epoch>

gmt2epoch( I<Y>, I<m>, I<d> [, I<H>, I<M>, I<S> ] ).
Returns the GMT time in seconds since the epoch.
alias: g2e().

  $ c 'gmt2epoch( 2025, 1, 1, 18, 40, 50 )'
  1735756850

=item C<epoch2local>

epoch2local( I<EPOCH> ).
Returns the local time.
( I<Y>, I<m>, I<d>, I<H>, I<M>, I<S> ).
alias: e2l().

  $ c 'epoch2local( 1735756850 )'
  ( 2025, 1, 2, 3, 40, 50 )     # 2025-01-02 03:40:50 LOCAL(JST)

=item C<epoch2gmt>

epoch2gmt( I<EPOCH> ).
Returns the GMT time.
( I<Y>, I<m>, I<d>, I<H>, I<M>, I<S> ).
alias: e2g().

  $ c 'epoch2gmt( 1735756850 )'
  ( 2025, 1, 1, 18, 40, 50 )    # 2025-01-01 18:40:50 GMT

=item C<sec2dhms>

sec2dhms( I<SECOND> ) --Convert-to--> ( I<D>, I<H>, I<M>, I<S> ).

  $ c 'sec2dhms( 356521 )'
  ( 4, 3, 2, 1 )    # 4 days, 3 hours, 2 minutes and 1 second

=item C<dhms2sec>

dhms2sec( I<D> [, I<H>, I<M>, I<S> ] ) --Convert-to--> ( I<SECOND> ).

  $ c 'dhms2sec( 4, 03, 02, 01 )'
  356521            # 356,521 seconds

=item C<ri2meter>

ri2meter( RI ) --Convert-to--> METER.
alias: 里→メートル(), 里２メートル().

  $ c 'ri2meter( 1 )'
  3927.2727272727

=item C<meter2ri>

meter2ri( METER ) --Convert-to--> RI.
alias: メートル→里(), メートル２里().

  $ c 'meter2ri( 4000 )'
  1.01851851851853

=item C<mile2meter>

mile2meter( MILE ) --Convert-to--> METER.
alias: マイル→メートル(), マイル２メートル().

  $ c 'mile2meter( 1 )'
  1609.344

=item C<meter2mile>

meter2mile( METER ) --Convert-to--> MILE.
alias: メートル→マイル(), メートル２マイル().

  $ c 'meter2mile( 2000 )'
  1.24274238447467

=item C<nautical_mile2meter>

nautical_mile2meter( NAUTICAL_MILE ) --Convert-to--> METER.
alias: 海里→メートル(), 海里２メートル().

  $ c 'nautical_mile2meter( 1 )'
  1852

=item C<meter2nautical_mile>

meter2nautical_mile( METER ) --Convert-to--> NAUTICAL_MILE.
alias: メートル→海里(), メートル２海里().

  $ c 'meter2nautical_mile( 2000 )'
  1.07991360691145

=item C<pound2gram>

pound2gram( POUND ) --Convert-to--> GRAM.
alias: ポンド→グラム(), ポンド２グラム().

  $ c 'pound2gram( 1 )'
  453.59237

=item C<gram2pound>

gram2pound( GRAM ) --Convert-to--> POUND.
alias: グラム→ポンド(), グラム２ポンド().

  $ c 'gram2pound( 500 )'
  1.10231131092439

=item C<ounce2gram>

ounce2gram( OUNCE ) -->Convert-to--> GRAM.
alias: オンス→グラム(), オンス２グラム().

  $ c 'ounce2gram( 1 )'
  28.349523125

=item C<gram2ounce>

gram2ounce( GRAM ) -->Convert-to--> OUNCE.
alias: グラム→オンス(), グラム２オンス().

  $ c 'gram2ounce( 30 )'
  1.05821885848741

=item C<laptimer>

laptimer( I<LAPS> ).
Each time you press Enter,
the split time is measured and the time taken to measure I<LAPS> is returned.
If I<LAPS> is set to a negative value, the split time is not output.
alias: lt().

The time for 3 laps was measured:

  $ c 'laptimer( 3 )'
  Lap  Split-Time    Lap-Time      Date-Time
  ---  ------------  ------------  -------------------
  <-- Enter key
  1/3  00:00:19.785  00:00:19.785  2025-12-17 22:18:29
  <-- Enter key
  2/3  00:00:39.562  00:00:19.777  2025-12-17 22:18:49
  <-- Enter key
  3/3  00:00:59.892  00:00:20.330  2025-12-17 22:19:09
  59.8917651176453

=item C<timer>

timer( I<SECOND> ).
If you specify a value less than 31536000 (365 days x 86400 seconds) for I<SECOND>,
the countdown will begin and end when it reaches zero.
If you specify a value greater than this,
it will be recognized as an epoch second,
and the countdown or countup will begin with that date and time as zero.
In this case, the countup will continue without stopping at zero.
In either mode, press Enter to end.

Specify the seconds in I<SECOND>:

  $ c 'timer( 10 )'
  2025-12-27 06:02:58.002  TARGET
  2025-12-27 06:02:58.017    <-- 10 seconds have passed or press Enter
  0.0172009468078613    # Number of seconds from the TARGET time

Specify the epoch second in I<SECOND>: ( Dates before 1971 cannot be specified )

  $ c 'timer( local2epoch( 2025, 12, 27, 06, 07, 00 ) )'
  2025-12-27 06:07:00.222  TARGET
  00:00:15.150    <-- Enter key
  2025-12-27 06:07:15.236
  15.2361481189728      # Number of seconds from the TARGET time

=item C<stopwatch>

stopwatch().
Measures the time until the Enter key is pressed.
The measured time is displayed on the screen.
alias: sw().

Usage example:

  $ c 'stopwatch()'
  <-- Enter key
  2025-11-25 01:53:17
  stopwatch() = 10.2675848007202 sec.
  10.2675848007202

=item C<bpm>

bpm( I<COUNT>, I<SECOND> ).
Specify the number of beats as I<COUNT> and the elapsed time as I<SECOND> to calculate the BPM.

  $ c 'bpm( 4, sw() )'
  <-- Enter key
  2025-11-25 01:53:17
  stopwatch() = 2.15290594100952 sec.
  111.477234294528

=item C<bpm15>

bpm15().
Once you have confirmed 15 beats, press the Enter key.
The BPM will be calculated from the elapsed time.
The measured time is displayed on the screen.

  $ c 'bpm15()'
  <-- Enter key
  2025-11-25 01:53:17
  stopwatch() = 12.7652950286865 sec.
  70.5036583939106

=item C<bpm30>

bpm30().
Once you have confirmed 30 beats, press the Enter key.
The BPM will be calculated from the elapsed time.
The measured time is displayed on the screen.

  $ c 'bpm30()'
  <-- Enter key
  2025-11-25 01:53:17
  stopwatch() = 24.9058220386505 sec.
  72.2722581574156

=item C<tachymeter>

tachymeter( I<SECOND> ).
Returns the number of units of work that can be completed per hour,
where I<SECOND> is the number of seconds required to complete one unit of work.
Same as ratio_scaling( I<SECOND>, 1, 3600 ).

Measure the time for a 1km section and calculate the speed:

  $ c 'tachymeter( sw() )'
  <-- Enter key
  2025-11-25 01:53:17
  stopwatch() = 35.5551850795746 sec.
  101.251054999235  # 101 km/h

=item C<telemeter>

telemeter( I<SECOND> ).
Measures distance using the difference in the speed of light and sound.
Returns the distance equivalent to I<SECOND> in meters.
Same as telemeter_m().

  $ c 'telemeter( sw() )'
  <-- Enter key
  2025-11-25 01:53:17
  stopwatch() = 7.9051628112793 sec.
  2687.75535583496  # 2687.76 m

=item C<telemeter_m>

telemeter_m( I<SECOND> ).
Measures distance using the difference in the speed of light and sound.
Returns the distance equivalent to I<SECOND> in meters.
Same as telemeter().

  $ c 'telemeter_m( 8 )'
  2720  # 2720 m

=item C<telemeter_km>

telemeter_km( I<SECOND> ).
Measures distance using the difference in the speed of light and sound.
Returns the distance equivalent to I<SECOND> in kilometers.
Same as telemeter_m() / 1000.

  $ c 'telemeter_km( 8 )'
  2.72  # 2.72 km

=back

=head1 DEPENDENCIES

This script uses only B<core Perl modules>. No external modules from CPAN are required.

=head2 Core Modules Used

=over 4

=item * base - first included in perl 5.00405

=item * Class::Struct — first included in perl 5.004

=item * constant — first included in perl 5.004

=item * Encode — first included in perl v5.7.3

=item * File::Basename — first included in perl 5

=item * List::Util — first included in perl v5.7.3

=item * Math::BigInt — first included in perl 5

=item * Math::Trig — first included in perl 5.004

=item * POSIX — first included in perl 5

=item * strict — first included in perl 5

=item * Time::HiRes - first included in perl v5.7.3

=item * Time::Local - first included in perl 5

=item * utf8 — first included in perl v5.6.0

=item * warnings — first included in perl v5.6.0

=back

=head2 Survey methodology

=over 4

=item 1. Preparation

Define the script name:

  $ target_script=c

=item 2. Extract used modules

Generate a list of modules from C<use> statements:

  $ grep '^use ' $target_script | sed 's!^use \([^ ;{][^ ;{]*\).*$!\1!' | \
      sort | uniq | tee ${target_script}.uselist

=item 3. Check core module status

Run C<corelist> for each module to find the first Perl version it appeared in:

  $ cat ${target_script}.uselist | while read line; do
      corelist $line
    done

=back

=head1 SEE ALSO

=over 4

=item L<perl>(1)

=item L<List::Util>

=item L<Math::BigInt>

=item L<Math::Trig>

=item L<POSIX>

=item L<Time::HiRes>

=item L<Time::Local>

=back

=head1 AUTHOR

2025-2026, tomyama

=head1 LICENSE

Copyright (c) 2025-2026, tomyama

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of tomyama nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
