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
## - $Revision: 4.46 $
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
## - Author: 2025, tomyama
## - Intended primarily for personal use, but BSD license permits redistribution.
##
## BSD 2-Clause License:
## Copyright (c) 2025, tomyama
## All rights reserved.
################################################################################

## Revision: 1.1
package OutputFunc;
use strict;
use warnings 'all';
#use Term::ReadKey;  ## GetTerminalSize()

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

    my $trm_columns = $self->GetTerminalWidth();
    #print( qq{$trm_columns, $trm_lines\n} );

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
        qq{              TIME (=CURRENT-TIME)\n} .
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
        qq{  -h, --help: Display this help and exit.\n} .
        qq{\n} .
        qq{$ops_help} .
        qq{\n} .
        qq{$fns_help} .
        qq{\n} .
        qq{Try "perldoc $self->{APPCONFIG}->{APPNAME}" for more information.\n};

    return $msg;
}

sub GetRevision()
{
    my $rev = q{$Revision: 4.46 $};
    $rev =~ s!^\$[R]evision: (\d+\.\d+) \$$!$1!o;
    return $rev;
}

sub GetVersion()
{
    my $rev = &GetRevision();

    my $major = 1;
    my( $minor, $revision ) = split( /\./, $rev );
    my $version = sprintf( '%d.%02d.%03d', $major, $minor, $revision );

    return $version;
}

sub PrintVersion()
{
    my $self = shift( @_ );

    my $ver = &GetVersion();
    my $v = qq{Version: $ver\n} .
            qq{   Perl: $^V\n};
    print( $v );
}

# 端末幅を取得するための Term::ReadKey は非コアモジュールで、
# インストール時に C コンパイラが必要となる環境もある。
# ビルド要件を増やしたくない場合にこのサブルーチンを使用するという前提。
## Revision: 1.2
sub GetTerminalWidth()
{
    my $self = shift( @_ );

    # Try stty
    if( $self->{APPCONFIG}->GetBIsStdoutTty() ){
        #my( $trm_columns, $trm_lines, $trm_width, $trm_height ) =
        #    &Term::ReadKey::GetTerminalSize();
        # 「ヘルプ整形」程度でビルド要件を増やすのは避けたいので、使用しないことに。

        my $stty_out = `stty size 2>/dev/null`;
        if( $stty_out =~ m/^\s*(\d+)\s+(\d+)/ ){
            return $2;
        }
    }

    # ▼ 代表的な歴史的/実用的な幅
    #   72 : GNU 系コマンド／メール折り返しの伝統
    #   76 : perldoc が使用
    #   78 : 80 の“2字控え”として昔使われた妥協値
    #   80 : 端末標準幅。多くの CLI のデフォルト。最も一般的。
    # 今回は汎用性と説明のしやすさを優先し、80 を採用する。
    return $ENV{COLUMNS} // 80;     # Fall back to environment
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
    H_ABS_ => qq{abs( N ). Returns the absolute value of its argument. [Perl Native]},
    H_INT_ => qq{int( N ). Returns the integer portion of N. [Perl Native]},
    H_FLOR => qq{floor( N ). Returning the largest integer value less than or equal to the numerical argument. [POSIX]},
    H_CEIL => qq{ceil( N ). Returning the smallest integer value greater than or equal to the given numerical argument. [POSIX]},
    H_RODD => qq{rounddown( A, B ). Returns the value of A truncated to B decimal places.},
    H_ROUD => qq{round( A, B ). Returns the value of A rounded to B decimal places.},
    H_RODU => qq{roundup( A, B ). Returns the value of A rounded up to B decimal places.},
    H_PCTG => qq{pct( NUMERATOR, DENOMINATOR [, DECIMAL_PLACES ] ). Returns the percentage, rounding the number if DECIMAL_PLACES is specified.},
    H_RASC => qq{ratio_scaling( A, B, C [, DECIMAL_PLACES ] ). When A:B, return the value of X in A:B=C:X. Rounding the number if DECIMAL_PLACES is specified. alias: rs().},
    H_PRIM => qq{is_prime( NUM ). Prime number test. Returns 1 if NUM is prime, otherwise returns 0.},
    H_PRFR => qq{prime_factorize( N ). Do prime factorization. N is an integer greater than or equal to 2. alias: pf().},
    H_GPRM => qq{get_prime( BIT_WIDTH ). Returns a random prime number within the range of BIT_WIDTH, where BIT_WIDTH is an integer between 4 and 32, inclusive.},
    H_GCD_ => qq{gcd( A,.. ). Returns the greatest common divisor (GCD), which is the largest positive integer that divides each of the operands. [Math::BigInt::bgcd()]},
    H_LCM_ => qq{lcm( A,.. ). Returns the least common multiple (LCM). [Math::BigInt::blcm()]},
    H_MIN_ => qq{min( A,.. ). Returns the entry in the list with the lowest numerical value. [List::Util]},
    H_MAX_ => qq{max( A,.. ). Returns the entry in the list with the highest numerical value. [List::Util]},
    H_SHFL => qq{shuffle( A,.. ). Returns the values of the input in a random order. [List::Util]},
    H_FRST => qq{first( A,.. ). Returns the head of the set.},
    H_UNIQ => qq{uniq( A,.. ). Filters a list of values to remove subsequent duplicates, as judged by a DWIM-ish string equality or "undef" test. Preserves the order of unique elements, and retains the first value of any duplicate set. [List::Util]},
    H_SUM_ => qq{sum( A,.. ). Returns the numerical sum of all the elements in the list. [List::Util]},
    H_PROD => qq{prod( A,.. ). Returns the product of each value.},
    H_AVRG => qq{avg( A,.. ). Returns the average value of all elements in a list.},
    H_LNSP => qq{linspace( LOWER, UPPER, COUNT [, ROUND] ). Generates a list of numbers from LOWER to UPPER divided into equal intervals by COUNT. If ROUND is set to true, the numbers are rounded down to integers.},
    H_LNST => qq{linstep( START, STEP, COUNT ). Generates a list of COUNT numbers that increase from START by STEP.},
    H_RAND => qq{rand( N ).  Returns a random fractional number greater than or equal to 0 and less than the value of N. [Perl Native]},
    H_LOGA => qq{log( N ). Returns the natural logarithm (base e) of N. [Perl Native]},
    H_SQRT => qq{sqrt( N ). Return the positive square root of N. Works only for non-negative operands. [Perl Native]},
    H_R2DG => qq{rad2deg( <RADIANS> ) -> <DEGREES>. [Math::Trig]},
    H_D2RD => qq{deg2rad( <DEGREES> [, <DEGREES>..] ) -> ( <RADIANS> [, <RADIANS>..] ). [Math::Trig]},
    H_DM2R => qq{dms2rad( <DEG>, <MIN>, <SEC> [, <DEG>, <MIN>, <SEC> ..] ) -> ( <RADIANS> [, <RADIANS>..] ).},
    H_DEGM => qq{dms2deg( <DEG>, <MIN>, <SEC> ) -> decimal degrees (DD).},
    H_D2DM => qq{deg2dms( <DEGREES> ) -> ( <DEG>, <MIN>, <SEC> ).},
    H_SINE => qq{sin( <RADIANS> ). Returns the sine of <RADIANS>. [Perl Native]},
    H_COSI => qq{cos( <RADIANS> ). Returns the cosine of <RADIANS>. [Perl Native]},
    H_TANG => qq{tan( <RADIANS> ). Returns the tangent of <RADIANS>. [Math::Trig]},
    H_ASIN => qq{asin( N ). The arcus (also known as the inverse) functions of the sine. [Math::Trig]},
    H_ACOS => qq{acos( N ). The arcus (also known as the inverse) functions of the cosine. [Math::Trig]},
    H_ATAN => qq{atan( N ). The arcus (also known as the inverse) functions of the tangent. [Math::Trig]},
    H_ATN2 => qq{atan2( Y, X ). The principal value of the arc tangent of Y / X. [Math::Trig]},
    H_HYPT => qq{hypot( X, Y ). Equivalent to "sqrt( X * X + Y * Y )" except more stable on very large or very small arguments. [POSIX]},
    H_POWE => qq{pow( A, B ). Exponentiation. "pow( 2, 3 )" -> 8. Similarly, "2 ** 3". [Perl Native]},
    H_PWIV => qq{pow_inv( A, B ). Returns the power of A to which B is raised.},
    H_GERA => qq{geo_radius( LAT ). Given a latitude (in radians), returns the distance from the center of the Earth to its surface (in meters).},
    H_LATC => qq{radius_of_lat( LAT ). Given a latitude (in radians), returns the radius of that parallel (in meters).},
    H_GDIS => qq{geo_distance( A_LAT, A_LON, B_LAT, B_LON ). Calculates and returns the distance (in meters) from A to B. Latitude and longitude must be specified in radians. Same as geo_distance_m().},
    H_GDIM => qq{geo_distance_m( A_LAT, A_LON, B_LAT, B_LON ). Calculates and returns the distance (in meters) from A to B. Latitude and longitude must be specified in radians. Same as geo_distance(). alias: gd_m().},
    H_GDKM => qq{geo_distance_km( A_LAT, A_LON, B_LAT, B_LON ). Calculates and returns the distance (in kilometers) from A to B. Latitude and longitude must be specified in radians. Same as geo_distance_m() / 1000. alias: gd_km().},
    H_L2EP => qq{local2epoch( Y, m, d [, H, M, S ] ). Returns the local time in seconds since the epoch.},
    H_G2EP => qq{gmt2epoch( Y, m, d [, H, M, S ] ). Returns the GMT time in seconds since the epoch.},
    H_EP2L => qq{epoch2local( EPOCH ). Returns the local time. ( Y, m, d, H, M, S ).},
    H_EP2G => qq{epoch2gmt( EPOCH ). Returns the GMT time. ( Y, m, d, H, M, S ).},
    H_SHMS => qq{sec2dhms( DURATION_SEC ) --Convert-to--> ( D, H, M, S ).},
    H_HMSS => qq{dhms2sec( D [, H, M, S ] ) --Convert-to--> ( DURATION_SEC ).},
};

%TableProvider::operators = (
    '+'               => [   0, T_OPERATOR,     2, H_PLUS, sub{ $_[ 0 ] + $_[ 1 ] } ],
    '-'               => [   1, T_OPERATOR,     2, H_MINU, sub{ $_[ 0 ] - $_[ 1 ] } ],
    '*'               => [   2, T_OPERATOR,     2, H_MULT, sub{ $_[ 0 ] * $_[ 1 ] } ],
    '/'               => [   3, T_OPERATOR,     2, H_DIVI, sub{ &DIV( $_[ 0 ], $_[ 1 ] ) } ],
    '%'               => [   4, T_OPERATOR,     2, H_MODU, sub{ &MOD( $_[ 0 ], $_[ 1 ] ) } ],
    '**'              => [   5, T_OPERATOR,     2, H_EXPO, sub{ $_[ 0 ] ** $_[ 1 ] } ],
    '|'               => [   6, T_OPERATOR,     2, H_BWOR, sub{ $_[ 0 ] | $_[ 1 ] } ],
    '&'               => [   7, T_OPERATOR,     2, H_BWAN, sub{ $_[ 0 ] & $_[ 1 ] } ],
    '^'               => [   8, T_OPERATOR,     2, H_BWEO, sub{ $_[ 0 ] ^ $_[ 1 ] } ],
    '<<'              => [   9, T_OPERATOR,     2, H_SHTL, sub{ $_[ 0 ] << $_[ 1 ] } ],
    '>>'              => [  10, T_OPERATOR,     2, H_SHTR, sub{ $_[ 0 ] >> $_[ 1 ] } ],
    '~'               => [  11, T_OPERATOR,     1, H_BWIV, sub{ ~( $_[ 0 ] ) } ],
    'fn('             => [  12, T_OTHER,       -1, undef  ],
    '('               => [  13, T_OPERATOR,     2, H_BBEG ],
    ','               => [  14, T_OPERATOR,    -1, H_COMA ],
    ')'               => [  15, T_OPERATOR,     2, H_BEND ],
    '='               => [  16, T_OPERATOR,     1, H_EQUA ],
    'OPERAND'         => [  17, T_OTHER,        0, undef  ],
    'BEGIN'           => [  18, T_OTHER,        0, undef  ],
    '#'               => [  19, T_SENTINEL,    -1, undef  ],
    'testfunc'        => [  20, T_OTHER,        1, undef  ],
    'abs'             => [  30, T_FUNCTION,     1, H_ABS_, sub{ abs( $_[ 0 ] ) } ],
    'int'             => [  40, T_FUNCTION,     1, H_INT_, sub{ int( $_[ 0 ] ) } ],
    'floor'           => [  50, T_FUNCTION,     1, H_FLOR, sub{ &POSIX::floor( $_[ 0 ] ) } ],
    'ceil'            => [  60, T_FUNCTION,     1, H_CEIL, sub{ &POSIX::ceil( $_[ 0 ] ) } ],
    'rounddown'       => [  70, T_FUNCTION,     2, H_RODD, sub{ &rounddown( $_[ 0 ], $_[ 1 ] ) } ],
    'round'           => [  80, T_FUNCTION,     2, H_ROUD, sub{ &round( $_[ 0 ], $_[ 1 ] ) } ],
    'roundup'         => [  90, T_FUNCTION,     2, H_RODU, sub{ &roundup( $_[ 0 ], $_[ 1 ] ) } ],
    'pct'             => [ 100, T_FUNCTION,    VA, H_PCTG, sub{ &percentage( @_ ) } ],
    'ratio_scaling'   => [ 110, T_FUNCTION, '3-4', H_RASC, sub{ &ratio_scaling( @_ ) } ],
    'is_prime'        => [ 120, T_FUNCTION,     1, H_PRIM, sub{ &is_prime_num( $_[ 0 ] ) } ],
    'prime_factorize' => [ 130, T_FUNCTION,     1, H_PRFR, sub{ &prime_factorize( $_[ 0 ] ) } ],
    'get_prime'       => [ 140, T_FUNCTION,     1, H_GPRM, sub{ &get_prime_num( $_[ 0 ] ) } ],
    'gcd'             => [ 150, T_FUNCTION,    VA, H_GCD_, sub{ &Math::BigInt::bgcd( @_ ) } ],
    'lcm'             => [ 160, T_FUNCTION,    VA, H_LCM_, sub{ &Math::BigInt::blcm( @_ ) } ],
    'min'             => [ 170, T_FUNCTION,    VA, H_MIN_, sub{ &List::Util::min( @_ ) } ],
    'max'             => [ 180, T_FUNCTION,    VA, H_MAX_, sub{ &List::Util::max( @_ ) } ],
    'shuffle'         => [ 190, T_FUNCTION,    VA, H_SHFL, sub{ &List::Util::shuffle( @_ ) } ],
    'first'           => [ 200, T_FUNCTION,    VA, H_FRST, sub{ &FIRST( @_ ) } ],
    'uniq'            => [ 210, T_FUNCTION,    VA, H_UNIQ, sub{ &List::Util::uniq( @_ ) } ],
    'sum'             => [ 220, T_FUNCTION,    VA, H_SUM_, sub{ &List::Util::sum( @_ ) } ],
    'prod'            => [ 230, T_FUNCTION,    VA, H_PROD, sub{ &prod( @_ ) } ],
    'avg'             => [ 240, T_FUNCTION,    VA, H_AVRG, sub{ &AVG( @_ ) } ],
    'linspace'        => [ 250, T_FUNCTION, '3-4', H_LNSP, sub{ &LINSPACE( @_ ) } ],
    'linstep'         => [ 260, T_FUNCTION,     3, H_LNST, sub{ &LINSTEP( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) } ],
    'rand'            => [ 270, T_FUNCTION,     1, H_RAND, sub{ rand( $_[ 0 ] ) } ],
    'log'             => [ 280, T_FUNCTION,     1, H_LOGA, sub{ &LOG( $_[ 0 ] ) } ],
    'sqrt'            => [ 290, T_FUNCTION,     1, H_SQRT, sub{ sqrt( $_[ 0 ] ) } ],
    'pow'             => [ 300, T_FUNCTION,     2, H_POWE, sub{ $_[ 0 ] ** $_[ 1 ] } ],
    'pow_inv'         => [ 310, T_FUNCTION,     2, H_PWIV, sub{ &pow_inv( $_[ 0 ], $_[ 1 ] ) } ],
    'rad2deg'         => [ 320, T_FUNCTION,     1, H_R2DG, sub{ &Math::Trig::rad2deg( $_[ 0 ] ) } ],
    'deg2rad'         => [ 330, T_FUNCTION,    VA, H_D2RD, sub{ &DEG2RAD( @_ ) } ],
    'dms2rad'         => [ 340, T_FUNCTION,  '3M', H_DM2R, sub{ &DMS2RAD( @_ ) } ],
    'dms2deg'         => [ 350, T_FUNCTION,     3, H_DEGM, sub{ &DMS2DEG( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) } ],
    'deg2dms'         => [ 360, T_FUNCTION,     1, H_D2DM, sub{ &DEG2DMS( $_[ 0 ] ) } ],
    'sin'             => [ 370, T_FUNCTION,     1, H_SINE, sub{ sin( $_[ 0 ] ) } ],
    'cos'             => [ 380, T_FUNCTION,     1, H_COSI, sub{ cos( $_[ 0 ] ) } ],
    'tan'             => [ 390, T_FUNCTION,     1, H_TANG, sub{ &Math::Trig::tan( $_[ 0 ] ) } ],
    'asin'            => [ 400, T_FUNCTION,     1, H_ASIN, sub{ &Math::Trig::asin( $_[ 0 ] ) } ],
    'acos'            => [ 410, T_FUNCTION,     1, H_ACOS, sub{ &Math::Trig::acos( $_[ 0 ] ) } ],
    'atan'            => [ 420, T_FUNCTION,     1, H_ATAN, sub{ &Math::Trig::atan( $_[ 0 ] ) } ],
    'atan2'           => [ 430, T_FUNCTION,     2, H_ATN2, sub{ &Math::Trig::atan2( $_[ 0 ], $_[ 1 ] ) } ],
    'hypot'           => [ 440, T_FUNCTION,     2, H_HYPT, sub{ &POSIX::hypot( $_[ 0 ], $_[ 1 ] ) } ],
    'geo_radius'      => [ 450, T_FUNCTION,     1, H_GERA, sub{ &geocentric_radius( $_[ 0 ] ) } ],
    'radius_of_lat'   => [ 460, T_FUNCTION,     1, H_LATC, sub{ &radius_of_latitude_circle( $_[ 0 ] ) } ],
    'geo_distance'    => [ 470, T_FUNCTION,     4, H_GDIS, sub{ &distance_between_points( $_[ 0 ], $_[ 1 ], $_[ 2 ], $_[ 3 ] ) } ],
    'geo_distance_m'  => [ 480, T_FUNCTION,     4, H_GDIM, sub{ &distance_between_points( $_[ 0 ], $_[ 1 ], $_[ 2 ], $_[ 3 ] ) } ],
    'geo_distance_km' => [ 490, T_FUNCTION,     4, H_GDKM, sub{ &distance_between_points_km( $_[ 0 ], $_[ 1 ], $_[ 2 ], $_[ 3 ] ) } ],
    'local2epoch'     => [ 500, T_FUNCTION, '3-6', H_L2EP, sub{ &local2epoch( @_ ) } ],
    'gmt2epoch'       => [ 510, T_FUNCTION, '3-6', H_G2EP, sub{ &gmt2epoch( @_ ) } ],
    'epoch2local'     => [ 520, T_FUNCTION,     1, H_EP2L, sub{ &epoch2local( $_[ 0 ] ) } ],
    'epoch2gmt'       => [ 530, T_FUNCTION,     1, H_EP2G, sub{ &epoch2gmt( $_[ 0 ] ) } ],
    'sec2dhms'        => [ 540, T_FUNCTION,     1, H_SHMS, sub{ &sec2dhms( $_[ 0 ] ) } ],
    'dhms2sec'        => [ 550, T_FUNCTION, '1-4', H_HMSS, sub{ &dhms2sec( @_ ) } ],
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

sub DIV( $$ )
{
    if( $_[1] == 0 ){
        die( qq{"$_[0] / $_[1]": Illegal division by zero.\n} );
    }
    return $_[ 0 ] / $_[ 1 ];
}

sub MOD( $$ )
{
    if( $_[1] == 0 ){
        return $_[ 0 ];
    }elsif( -1 < $_[ 1 ] && $_[ 1 ] < 1 ){
        die( qq{"$_[0] \% $_[1]": Illegal modulus operand.\n} );
    }
    return $_[ 0 ] % $_[ 1 ];
}

sub FIRST( @ )
{
    return $_[ 0 ];
}

sub LOG( $ )
{
    if( $_[ 0 ] == 0 ){
        die( qq{log( $_[0] ): Illegal operand.\n} );
    }
    return log( $_[ 0 ] );
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

sub DMS2DEG( $$$ )
{
    my $degrees = shift( @_ );
    my $min = shift( @_ );
    my $sec = shift( @_ );
    return $degrees + ( $min / 60 ) + ( $sec / 3600 );
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

sub DEG2DMS( $ )
{
    my $deg = shift( @_ );
    my $d = int( $deg );
    $d = '-0' if( $d == 0 && $deg < 0 );
    my $m_raw = ( $deg - $d ) * 60;
    my $m = int( $m_raw );
    my $s = ( $m_raw - $m ) * 60;
    return ( $d, $m, $s );
}

sub rounddown( $$ )
{
    return &round_rf( $_[ 0 ], $_[ 1 ], 0 );
}

sub round( $$ )
{
    return &round_rf( $_[ 0 ], $_[ 1 ], 0.5 );
}

sub roundup( $$ )
{
    return &round_rf( $_[ 0 ], $_[ 1 ], 1 );
}

sub round_rf( $$$ )
{
    my $value = shift( @_ );
    my $digit = shift( @_ );
    my $rounding_factor = shift( @_ );
    #print( qq{\$value="$value", \$digit="$digit", \$rounding_factor="$rounding_factor"\n} );
    my $carry_factor = 10 ** $digit;
    $rounding_factor *= -1 if( $value < 0 );
    my $tmp = $value * $carry_factor + $rounding_factor;
    my $integer = int( $tmp );
    $integer -= $rounding_factor if( $tmp == $integer );
    return $integer / $carry_factor;
}

sub percentage( $$;$ )
{
    my $numerator = shift( @_ );
    my $denominator = shift( @_ );
    if( !defined( $denominator ) ){
        die( qq{pct: Not enough operands.\n} );
    }
    my $decimal_places = undef;
    $decimal_places = shift( @_ ) if( defined( $_[ 0 ] ) );
    my $ret_value = $numerator * 100 / $denominator;
    if( defined( $decimal_places ) ){
        $ret_value = &round( $ret_value, $decimal_places );
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
        $forecast_quantity = &round( $forecast_quantity, $decimal_places );
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
            return $num if( is_prime_num( $num ) );
        }
    }
}

sub prod( @ )
{
    my $product = 1;
    for my $arg( @_ ){
        $product *= $arg;
    }
    return $product;
}

sub AVG( @ )
{
    my $total = List::Util::sum( @_ );
    my $len = scalar( @_ );
    return $total / $len;
}

# 機能: 下限値、上限値、分割数に基づき、等間隔の数値リストを生成する
# 引数: $lower (下限値), $upper (上限値), $count (分割数),
#       $bRound (省略可: 真値なら整数に丸める, デフォルトは丸めない)
sub LINSPACE( $$$;$ )
{
    my( $lower, $upper, $count, $bRound ) = @_;

    return $lower if( $count <= 1 );

    my @list;
    my $interval = ( $upper - $lower ) / ( $count - 1 );

    for( my $idx=0; $idx<$count; $idx++ ){
        my $value = ( $idx == $count - 1 ) ? $upper : $lower + $idx * $interval;

        # 第4引数 $bRound が真値であれば整数に丸める
        if( $bRound ){
            $value = int( $value );
        }

        push( @list, $value );
    }

    return @list;
}

# 機能: 開始値、ステップ幅、個数に基づき、等間隔の数値リストを生成する
# 引数: $start (開始値), $step (ステップ幅), $count (個数),
sub LINSTEP( $$$ )
{
    my( $start, $step, $count ) = @_;

    return $start if( $count <= 1 );

    my @list;
    my $cycle = $count - 1;
    my $value = $start;
    push( @list, $value );
    for( my $idx=0; $idx<$cycle; $idx++ ){
        $value += $step;
        push( @list, $value );
    }

    return @list;
}

sub pow_inv( $$ )
{
    my( $n, $x ) = @_;
    my $y = log( $n ) / log( $x );
    my $rounded = int( $y + 0.5 );  # 四捨五入
    return ( $x ** $rounded == $n ) ? $rounded : $y;
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
sub distance_between_points( $$$$ )
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

#    # 地球の平均半径 (メートル)
#    my $earth_radius_m = 6371008.7714;

    my $distance_m = GRS80_EQUATORIAL_RADIUS_M * $distance;

    return $distance_m;
}

sub distance_between_points_km( $$$$ )
{
    return &distance_between_points( @_ ) / 1000;
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
    $expr =~ tr!Ａ-Ｚａ-ｚ０-９，、．＋＊・･／＾（）＝　!a-za-z0-9,,.+***/^()= !;
    ## tr///で使えなかった → －
    $expr =~ s!－!-!go;
    $expr =~ s!√!sqrt!go;
    $expr =~ s!π!pi!go;
    $expr =~ s!(?:北緯|東経)(\d+(?:\.\d+)?)[度°]!deg2rad( $1 )!go;
    $expr =~ s!(?:南緯|西経)(\d+(?:\.\d+)?)[度°]!deg2rad( -$1 )!go;
    ## ex.) 35°12'34"N 139°40'56"E
    $expr =~ s!(\d+)°(\d+)'(\d+(?:\.\d+)?)"[NE]!dms2rad( $1, $2, $3 )!go;
    $expr =~ s!(\d+)°(\d+)'(\d+(?:\.\d+)?)"[SW]!dms2rad( -$1, -$2, -$3 )!go;
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
    $expr =~ s!rs\(!ratio_scaling(!go;
    $expr =~ s!pf\(!prime_factorize(!go;
    $expr =~ s!gd_m\(!geo_distance_m(!go;
    $expr =~ s!gd_km\(!geo_distance_km(!go;

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
        my $kv = sprintf( '%s = "%s"', $key, ${ $self->{CONSTANTS} }{ $key } );
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
#    my $debug = 1;
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

=item TIME

CURRENT-TIME

=item User-defined-file

".c.rc" should be placed in the same directory as "c script" or in "$HOME".

  [ .c.rc ]
  ## - ".c.rc" should be placed
  ##   in the same directory as "c script" or in "$HOME".
  ##
  ## - "c script" is not case-sensitive.
  ## - All keys are converted to lowercase.
  ## - If you create definitions with different case, they will be overwritten by definitions loaded later.

  my %user_constant;

  ## ex.) $ ./c 'geo_distance_km( TOKYO_ST_COORD, OSAKA_ST_COORD )'
  ##      403.505099759608
  $user_constant{TOKYO_ST_COORD} = 'deg2rad( 35.68129, 139.76706 )';
  $user_constant{OSAKA_ST_COORD} = 'deg2rad( 34.70248, 135.49595 )';
  ## ex.) $ ./c 'geo_distance_km( MADAGASCAR_COORD, GALAPAGOS_ISLANDS_COORD )'
  ##      14907.357977036
  $user_constant{MADAGASCAR_COORD} = 'deg2rad( -18.76694, 46.8691 )';
  $user_constant{GALAPAGOS_ISLANDS_COORD} = 'deg2rad( -0.3831, -90.42333 )';

  return %user_constant;

=back

=head2 OPERATORS

+ - * / % ** | & ^ E<lt>E<lt> E<gt>E<gt> ~ ( , ) =

=head2 FUNCTIONS

abs, int, floor, ceil, rounddown, round, roundup, pct, ratio_scaling, is_prime, prime_factorize,
get_prime, gcd, lcm, min, max, shuffle, first, uniq, sum, prod, avg, linspace, linstep, rand, log, sqrt,
pow, pow_inv, rad2deg, deg2rad, dms2rad, dms2deg, deg2dms, sin, cos, tan, asin, acos, atan, atan2, hypot,
geo_radius, radius_of_lat, geo_distance, geo_distance_m, geo_distance_km, local2epoch, gmt2epoch,
epoch2local, epoch2gmt, sec2dhms, dhms2sec

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

  $ c 'sqrt(power(1920,2)+power(1080,2))='
  2202.9071700823

Example of using the functions.
The candidate values ​​are 10 equally spaced values ​​from 0 to 90 degrees,
and the radians of an arbitrarily selected value are calculated.

  $ c 'deg2rad( first( shuffle( linspace( 0, 90, 10 ) ) ) )' -v
  linspace( 0, 90, 10 ) = ( 0, 10, 20, 30, 40, 50, 60, 70, 80, 90 )
  shuffle( 0, 10, 20, 30, 40, 50, 60, 70, 80, 90 ) = ( 10, 80, 60, 40, 30, 90, 50, 70, 20, 0 )
  first( 10, 80, 60, 40, 30, 90, 50, 70, 20, 0 ) = 10
  deg2rad( 10 ) = 0.174532925199433
  Formula: 'deg2rad( first( shuffle( linspace( 0 , 90 , 10 ) ) ) ) ='
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

  $ c time
  1764003197

In an easy-to-understand format:

  $ c 'epoch2local( time )'
  ( 2025, 11, 25, 1, 53, 17 )   # 2025-11-25 01:53:17

Time elapsed since a specified date:

  $ c 'sec2dhms( time - local2epoch( 2011, 03, 11, 14, 46 ) )'
  ( 5372, 15, 51, 18 )  # 5372 days, 15 hours, 51 minutes, and 18 seconds

Time interval:

  $ c 'sec2dhms( local2epoch( 2024, 01, 01, 16, 10 ) - local2epoch( 2011, 03, 11, 14, 46 ) )'
  ( 4679, 1, 24, 0 )

1 hour and 45 minutes before two days later:

  $ c 'epoch2local( local2epoch( 2020, 1, 1, 15, 0, 0 ) + dhms2sec( 2, -1, -45 ) )'
  ( 2020, 1, 3, 13, 15, 0 )

If it takes 1 hour and 18 minutes to make 3, when will 15 be completed?:

  $ c 'epoch2local(
         local2epoch( 2025, 11, 25, 09, 00 ) +
         ratio_scaling( 3, dhms2sec( 0, 1, 18 ), 15 )
       )'
  ( 2025, 11, 25, 15, 30, 0 )

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
  14907.357977036

The straight-line distance between Madagascar and the Galapagos Islands was found to be 14,907 km.

If you want to specify latitude and longitude in DMS, use dms2rad().
Be sure to include the sign if the value is negative.

  # gd_km() is an alias for geo_distance_km().
  $ c 'gd_km(
         dms2rad( -18, -46,  -0.984000000006233 ), dms2rad( 46, 52, 8.76000000001113 ),
         dms2rad(  -0, -22, -59.16 ), dms2rad( -90, -25, -23.9880000000255 ) ) ='
  14907.357977036

If you record the calculation as shown below,
you can save not only the calculation results but also the calculation method,
which I think will be easy to reuse and convenient.
This is one of the reasons why I wrote this tool.

  $ Madagascar_coord='-18.76694, 46.8691'
  $ Galapagos_Islands_coord='-0.3831, -90.42333'
  $ c "geo_distance_km(
         deg2rad(
           $Madagascar_coord, $Galapagos_Islands_coord
         )
       )"
  14907.357977036
  $

The B<c> script was created with the following in mind:

- It will run with just Perl.

- The calculation formulas are easy to understand even when read later.

=head1 OPERATORS

=over 8

=item C<+>

Addition. C<1 + 2> -> C<3>.

=item C<->

Subtraction. C<3 - 2> -> C<1>.

=item C<*>

Multiplication. C<1 * 2> -> C<2>.

=item C</>

Division. C<1 / 2> -> C<0.5>.

=item C<%>

Modulo arithmetic. C<5 % 3> -> C<2>.

=item C<**>

Exponentiation. C<2 ** 3> -> C<8>. Similarly, C<pow( 2, 3 )>.

=item C<|>

Bitwise OR. C<0x2 | 0x4> -> C<6 [ = 0x6 ]>.

=item C<&>

Bitwise AND. C<0x6 & 0x4> -> C<4 [ = 0x4 ]>.

=item C<^>

Bitwise Exclusive OR. C<0x6 ^ 0x4> -> C<2 [ = 0x2 ]>.

=item C<E<lt>E<lt>>

Bitwise left shift. C<0x6 E<lt>E<lt> 1> -> C<12 [ = 0xC ]>.

=item C<E<gt>E<gt>>

Bitwise right shift. C<0x6 E<gt>E<gt> 1> -> C<3 [ = 0x3 ]>.

=item C<~>

Bitwise Inversion. C<~0> -> C<0xFFFFFFFFFFFFFFFFFF>.

=item C<(>

A symbol that controls the priority of calculations.

=item C<,>

The separator that separates function arguments.

=item C<)>

A symbol that controls the priority of calculations.

=item C<=>

Equals sign. In I<c> script, it has the meaning of terminating the calculation formula,
but it is not necessary. C<1 + 2 =>. Similarly, C<1 + 2>.

=back

=head1 FUNCTIONS

=over 8

=item C<abs>

abs( N ). Returns the absolute value of its argument. [Perl Native]

=item C<int>

int( N ). Returns the integer portion of N. [Perl Native]

=item C<floor>

floor( N ). Returning the largest integer value less than or equal to the numerical argument. [POSIX]

=item C<ceil>

ceil( N ). Returning the smallest integer value greater than or equal to the given numerical argument. [POSIX]

=item C<rounddown>

rounddown( A, B ). Returns the value of A truncated to B decimal places.

=item C<round>

round( A, B ). Returns the value of A rounded to B decimal places.

=item C<roundup>

roundup( A, B ). Returns the value of A rounded up to B decimal places.

=item C<pct>

pct( I<NUMERATOR>, I<DENOMINATOR> [, I<DECIMAL_PLACES> ] ). Returns the percentage, rounding the number if I<DECIMAL_PLACES> is specified.

=item C<ratio_scaling>

ratio_scaling( I<A>, I<B>, I<C> [, I<DECIMAL_PLACES> ] ). When I<A>:I<B>, return the value of I<X> in I<A>:I<B>=I<C>:I<X>. Rounding the number if I<DECIMAL_PLACES> is specified. alias: rs().

=item C<is_prime>

is_prime( I<NUM> ). Prime number test. Returns 1 if I<NUM> is prime, otherwise returns 0.

=item C<prime_factorize>

prime_factorize( I<NUM> ). Do prime factorization. I<NUM> is an integer greater than or equal to 2. alias: pf().

=item C<get_prime>

get_prime( I<BIT_WIDTH> ). Returns a random prime number within the range of I<BIT_WIDTH>, where I<BIT_WIDTH> is an integer between 4 and 32, inclusive.

=item C<gcd>

gcd( A,.. ). Returns the greatest common divisor (GCD), which is the largest positive integer that divides each of the operands. [Math::BigInt::bgcd()]

=item C<lcm>

lcm( A,.. ). Returns the least common multiple (LCM). [Math::BigInt::blcm()]

=item C<min>

min( A,.. ). Returns the entry in the list with the lowest numerical value. [List::Util]

=item C<max>

max( A,.. ). Returns the entry in the list with the highest numerical value. [List::Util]

=item C<shuffle>

shuffle( A,.. ). Returns the values of the input in a random order. [List::Util]

=item C<first>

first( A,.. ). Returns the head of the set.

=item C<uniq>

uniq( A,.. ). Filters a list of values to remove subsequent duplicates, as judged by a DWIM-ish string equality or "undef" test. Preserves the order of unique elements, and retains the first value of any duplicate set. [List::Util]

=item C<sum>

sum( A,.. ). Returns the numerical sum of all the elements in the list. [List::Util]

=item C<prod>

prod( A,.. ). Returns the product of each value.

=item C<avg>

avg( A,.. ). Returns the average value of all elements in a list.

=item C<linspace>

linspace( I<LOWER>, I<UPPER>, I<COUNT> [, I<ROUND>] ).
Generates a list of numbers from I<LOWER> to I<UPPER> divided into equal intervals by I<COUNT>.
If I<ROUND> is set to true, the numbers are rounded down to integers.

=item C<linstep>

linstep( I<START>, I<STEP>, I<COUNT> ). Generates a list of I<COUNT> numbers that increase from I<START> by I<STEP>.

=item C<rand>

rand( N ).  Returns a random fractional number greater than or equal to 0 and
less than the value of N. [Perl Native]

=item C<log>

log( N ). Returns the natural logarithm (base e) of N. [Perl Native]

=item C<sqrt>

sqrt( N ). Return the positive square root of N. Works only for non-negative operands. [Perl Native]

=item C<pow>

pow( A, B ). Exponentiation. "pow( 2, 3 )" -> 8. Similarly, "2 ** 3". [Perl Native]

=item C<pow_inv>

pow_inv( A, B ). Returns the power of A to which B is raised.

=item C<rad2deg>

rad2deg( I<RADIANS> ) -> I<DEGREES>. [Math::Trig]

=item C<deg2rad>

deg2rad( I<DEGREES> [, I<DEGREES>..] ) -> ( I<RADIANS> [, I<RADIANS>..] ). [Math::Trig]

=item C<dms2rad>

dms2rad( I<DEG>, I<MIN>, I<SEC> [, I<DEG>, I<MIN>, I<SEC> ..] ) -> ( I<RADIANS> [, I<RADIANS>..] ).

=item C<dms2deg>

dms2deg( I<DEG>, I<MIN>, I<SEC> ) -> decimal degrees (DD).

=item C<deg2dms>

deg2dms( I<DEGREES> ) -> ( I<DEG>, I<MIN>, I<SEC> ).

=item C<sin>

sin( I<RADIANS> ). Returns the sine of I<RADIANS>. [Perl Native]

=item C<cos>

cos( I<RADIANS> ). Returns the cosine of I<RADIANS>. [Perl Native]

=item C<tan>

tan( I<RADIANS> ). Returns the tangent of I<RADIANS>. [Math::Trig]

=item C<asin>

asin( N ). The arcus (also known as the inverse) functions of the sine. [Math::Trig]

=item C<acos>

acos( N ). The arcus (also known as the inverse) functions of the cosine. [Math::Trig]

=item C<atan>

atan( N ). The arcus (also known as the inverse) functions of the tangent. [Math::Trig]

=item C<atan2>

atan2( Y, X ). The principal value of the arc tangent of Y / X. [Math::Trig]

=item C<hypot>

hypot( X, Y ). Equivalent to "sqrt( X * X + Y * Y )" except more stable on very large or very small arguments. [POSIX]

=item C<geo_radius>

geo_radius( LAT ). Given a latitude (in radians), returns the distance from the center of the Earth to its surface (in meters).

=item C<radius_of_lat>

radius_of_lat( LAT ). Given a latitude (in radians), returns the radius of that parallel (in meters).

=item C<geo_distance>

geo_distance( I<A_LAT>, I<A_LON>, I<B_LAT>, I<B_LON> ). Calculates and returns the distance (in meters) from A to B. Latitude and longitude must be specified in radians. Same as geo_distance_m().

=item C<geo_distance_m>

geo_distance_m( I<A_LAT>, I<A_LON>, I<B_LAT>, I<B_LON> ). Calculates and returns the distance (in meters) from A to B. Latitude and longitude must be specified in radians. Same as geo_distance(). alias: gd_m().

=item C<geo_distance_km>

geo_distance_km( I<A_LAT>, I<A_LON>, I<B_LAT>, I<B_LON> ). Calculates and returns the distance (in kilometers) from A to B. Latitude and longitude must be specified in radians. Same as geo_distance_m() / 1000. alias: gd_km().

=item C<local2epoch>

local2epoch( I<Y>, I<m>, I<d> [, I<H>, I<M>, I<S> ] ). Returns the local time in seconds since the epoch.

=item C<gmt2epoch>

gmt2epoch( I<Y>, I<m>, I<d> [, I<H>, I<M>, I<S> ] ). Returns the GMT time in seconds since the epoch.

=item C<epoch2local>

epoch2local( I<EPOCH> ). Returns the local time. ( I<Y>, I<m>, I<d>, I<H>, I<M>, I<S> ).

=item C<epoch2gmt>

epoch2gmt( I<EPOCH> ). Returns the GMT time. ( I<Y>, I<m>, I<d>, I<H>, I<M>, I<S> ).

=item C<sec2dhms>

sec2dhms( I<DURATION_SEC> ) --Convert-to--> ( I<D>, I<H>, I<M>, I<S> ).

=item C<dhms2sec>

dhms2sec( I<D> [, I<H>, I<M>, I<S> ] ) --Convert-to--> ( I<DURATION_SEC> ).

=back

=head1 Environmental requirements

=head2 List of modules used

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

=item * Time::Local - first included in perl 5

=item * utf8 — first included in perl v5.6.0

=item * warnings — first included in perl v5.6.0

=back

=head2 Survey methodology

- Preparation:

  $ target_script=c

- 1st. column:

  $ grep '^use ' $target_script | sed 's!^use \([^ ;{][^ ;{]*\).*$!\1!' | \
      sort | uniq | tee ${target_script}.uselist

- 2nd. column:

  $ cat ${target_script}.uselist | while read line; do
      corelist $line
    done

=head1 SEE ALSO

=over 4

=item L<perl>(1)

=item L<List::Util>

=item L<Math::BigInt>

=item L<Math::Trig>

=item L<POSIX>

=item L<Time::Local>

=back

=head1 AUTHOR

2025, tomyama

=head1 LICENSE

Copyright (c) 2025, tomyama

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
