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
## - $Revision: 3.1 $
##
## - Script Structure
##   - main
##     - FormulaEngine
##       - FormulaLexer
##       - FormulaParser
##         - FormulaStack
##       - FormulaEvaluator
##     - [ shared package ] OutputFunc, FormulaToken, TableProvider
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

$OutputFunc::counter = 0;

# OutputFunc コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{APPNAME} = shift( @_ );
    $self->{DEBUG} = shift( @_ );
    $self->{LABEL} = shift( @_ );
    $self->Reset();
    $OutputFunc::counter++;
#    $self->dPrint( qq{OutputFunc: label="$label": instance is generated: \$counter=$OutputFunc::counter\n} );
    return $self;               # 無名ハッシュ参照を返す
}

sub Reset()
{
    my $self = shift( @_ );
}

##########
## 書式表示
sub Usage( $ )
{
    my $self = shift( @_ );

    my $ops = join( ' ', &TableProvider::GetOperatorsList() );
    my $fns = join( ', ', &TableProvider::GetFunctionsList() );
    $fns =~ s!(([a-z0-9]+, ){10})!$1\n    !go;

    my $ops_help = qq{<OPERATORS>\n};
    for my $op( &TableProvider::GetOperatorsList() ){
        $ops_help .= &FmtHelp( $op );
    }

    my $fns_help = qq{<FUNCTIONS>\n};
    for my $fn( &TableProvider::GetFunctionsList() ){
        $fns_help .= &FmtHelp( $fn );
    }

    my $msg = "Usage: " .
        qq{$self->{APPNAME} [<OPTIONS...>] [<EXPRESSIONS...>]\n} .
        qq{\n} .
        qq{  - The c script displays the result of the given expression.\n} .
         q{  - $Revision: 3.1 $}.qq{\n} .
        qq{\n} .
        qq{<EXPRESSIONS>: Specify the expression.\n} .
        qq{\n} .
        qq{  <OPERANDS>:\n} .
        qq{    Decimal:  0, -1, 100 ...\n} .
        qq{    Hexadecimal: 0xf, -0x1, 0x0064 ...\n} .
        qq{    Constant: PI (=3.14159265358979)\n} .
        qq{\n} .
        qq{  <OPERATORS>:\n} .
        qq{    $ops\n} .
        qq{\n} .
        qq{  <FUNCTIONS>:\n} .
        qq{    $fns\n} .
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
        qq{Try "perldoc $self->{APPNAME}" for more information.\n};

#    if( $_[0] ){
#        print STDERR ( $msg );
#    }else{
        print STDOUT ( $msg );
#    }

    return 0;
}

sub FmtHelp( $ )
{
    my $ope = shift( @_ );

    ##1234567890
    ##  1234567
    ##  ceil  ceil( N ). Returning the smallest integer value greater than or equal
    ##        to the given numerical argument. [POSIX]
    ##  $ope  $help
    my $ope_len = length( $ope );
    my $fmt = qq{  %-5s %s\n};
    $fmt = qq{  %s\n        %s\n} if( $ope_len > 5 );
    my $help = &TableProvider::GetHelp( $ope );
    if( !defined( $help ) ){
        $help = '';
        $fmt = qq{  %s%s\n};
    }else{
        $help =~ s/\n/\n        /go;
    }

    return sprintf( $fmt, $ope, $help );
}

sub SetDebug()
{
    my $self = shift( @_ );
    $self->{DEBUG} = shift( @_ );
}

sub dPrint( @ )
{
    my $self = shift( @_ );
    if( $self->{DEBUG} ){
        print( $self->{LABEL} . ': ' );
        print( @_ );
    }
}

sub dPrintf( @ )
{
    my $self = shift( @_ );
    if( $self->{DEBUG} ){
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
    my $label = shift( @_ );
    my $msg = qq{$self->{APPNAME}: $self->{LABEL}: $label: } .
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
use List::Util; ## min(), max()

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
    $self->{APPNAME} = shift( @_ );
    $self->{DEBUG} = shift( @_ );
    $self->{B_TEST} = shift( @_ );
    if( !defined( $TableProvider::opf ) ){
        $TableProvider::opf = OutputFunc->new( $self->{APPNAME}, $self->{DEBUG}, 'tbl_prvdr' );
    }
    $self->Reset();
    if( $self->{B_TEST} ){
        my $opeIdx = &GetOperatorsInfo( '_', O_INDX );
        $TableProvider::opf->dPrint( qq{test: \$opeIdx="$opeIdx"\n} );
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
        # '+'     '-'     '*'     '/'     '%'     '**'    '|'     '&'     '^'     '~'     'fn('   '('     ','     ')'     '='     OPERAND END
        [ E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  0 '+'
        [ E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  1 '-'
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  2 '*'
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  3 '/'
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  4 '%'
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  5 '**'
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_RIGH, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  6 '|'
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  7 '&'
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_RIGH, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  8 '^'
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_RIGH, E_RIGH, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_LEFT ], ##  9 '~'
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_IGNR, E_FUNC, E_LEFT, E_RIGH, E_UNKN ], ## 10 'fn('
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_IGNR, E_REMV, E_LEFT, E_RIGH, E_UNKN ], ## 11 '('
        [ E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN ], ## 12 ','
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_RIGH, E_UNKN, E_UNKN, E_IGNR, E_LEFT, E_LEFT, E_UNKN, E_LEFT ], ## 13 ')'
        [ E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN, E_UNKN ], ## 14 '='
        [ E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_LEFT, E_UNKN, E_UNKN, E_LEFT, E_LEFT, E_LEFT, E_UNKN, E_LEFT ], ## 15 OPERAND
        [ E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_RIGH, E_UNKN, E_UNKN, E_REMV, E_RIGH, E_REMV ], ## 16 BEGIN
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
    H_BWOR => qq{Bitwise OR. "0x2 | 0x4" -> "6 ( = 0x6 )".},
    H_BWAN => qq{Bitwise AND. "0x6 & 0x4" -> "4 ( = 0x4 )".},
    H_BWEO => qq{Bitwise exclusive or. "0x6 ^ 0x4" -> "2 ( = 0x2 )".},
    H_BWIV => qq{Bitwise inversion. "~0" -> 0xFFFFFFFFFFFFFFFFFF.},
    H_BBEG => qq{A symbol that controls the priority of calculations.},
    H_COMA => qq{The separator that separates function arguments.},
    H_BEND => qq{A symbol that controls the priority of calculations.},
    H_EQUA => qq{Equals sign. In *c* script, it has the meaning of terminating \n} .
              qq{the calculation formula, but it is not necessary. \n"1 + 2 =". Similarly, "1 + 2".},
    H_ABS_ => qq{abs( N ). Returns the absolute value of its argument. [Perl Native]},
    H_INT_ => qq{int( N ). Returns the integer portion of N. [Perl Native]},
    H_FLOR => qq{floor( N ). Returning the largest integer value less than or equal \nto the numerical argument. [POSIX]},
    H_CEIL => qq{ceil( N ). Returning the smallest integer value greater than or equal \nto the given numerical argument. [POSIX]},
    H_RODD => qq{rounddown( A, B ). Returns the value of A truncated to B decimal places.},
    H_ROUD => qq{round( A, B ). Returns the value of A rounded to B decimal places.},
    H_RODU => qq{roundup( A, B ). Returns the value of A rounded up to B decimal places.},
    H_PCTG => qq{pct( NUMERATOR, DENOMINATOR [, DECIMAL_PLACES ] ). \nReturns the percentage, rounding the number if DECIMAL_PLACES is specified.},
    H_GCD_ => qq{gcd( A,.. ). Returns the greatest common divisor (GCD), which is the largest \npositive integer that divides each of the operands. [Math::BigInt::bgcd()]},
    H_LCM_ => qq{lcm( A,.. ). Returns the least common multiple (LCM). [Math::BigInt::blcm()]},
    H_MIN_ => qq{min( A,.. ). Returns the entry in the list with the lowest numerical value. [List::Util]},
    H_MAX_ => qq{max( A,.. ). Returns the entry in the list with the highest numerical value. [List::Util]},
    H_SUM_ => qq{sum( A,.. ). Returns the numerical sum of all the elements in the list. [List::Util]},
    H_AVRG => qq{avg( A,.. ). Returns the average value of all elements in a list.},
    H_RAND => qq{rand( N ).  Returns a random fractional number greater than or equal to 0 and \nless than the value of N. [Perl Native]},
    H_LOGA => qq{log( N ). Returns the natural logarithm (base e) of N. [Perl Native]},
    H_SQRT => qq{sqrt( N ). Return the positive square root of N. \nWorks only for non-negative operands. [Perl Native]},
    H_D2RD => qq{deg2rad( <DEGREES> ) -> <RADIANS>. [Math::Trig]},
    H_R2DG => qq{rad2deg( <RADIANS> ) -> <DEGREES>. [Math::Trig]},
    H_DEGM => qq{dms( DEG, MIN, SEC ) -> decimal degrees (DD).},
    H_DD2R => qq{dms2rad( DEG, MIN, SEC ) -> <RADIANS>.},
    H_SINE => qq{sin( <RADIANS> ). Returns the sine of <RADIANS>. [Perl Native]},
    H_COSI => qq{cos( <RADIANS> ). Returns the cosine of <RADIANS>. [Perl Native]},
    H_TANG => qq{tan( <RADIANS> ). Returns the tangent of <RADIANS>. [Math::Trig]},
    H_ASIN => qq{asin( N ). The arcus (also known as the inverse) functions of the sine. [Math::Trig]},
    H_ACOS => qq{acos( N ). The arcus (also known as the inverse) functions of the cosine. [Math::Trig]},
    H_ATAN => qq{atan( N ). The arcus (also known as the inverse) functions of the tangent. [Math::Trig]},
    H_ATN2 => qq{atan2( Y, X ). The principal value of the arc tangent of Y / X. [Math::Trig]},
    H_HYPT => qq{hypot( X, Y ). Equivalent to "sqrt( X * X + Y * Y )" except more stable \non very large or very small arguments. [POSIX]},
    H_POWE => qq{pow( A, B ). Exponentiation. "pow( 2, 3 )" -> 8. Similarly, "2 ** 3". [Perl Native]},
    H_GERA => qq{geocentric_radius( LAT ). Given a latitude (in radians), returns \nthe distance from the center of the Earth to its surface (in meters).},
    H_LATC => qq{radius_of_latitude_circle( LAT ). Given a latitude (in radians), \nreturns the radius of that parallel (in meters).},
    H_DBPT => qq{distance_between_points( ptA_lat, ptA_lon, ptB_lat, ptB_lon ). \nCalculates and returns the distance (in meters) between two points, \nlatitude and longitude must be specified in radians.},
};

%TableProvider::operators = (
    '+'          => [  0, T_OPERATOR,  2, H_PLUS, sub{ $_[ 0 ] + $_[ 1 ] } ],
    '-'          => [  1, T_OPERATOR,  2, H_MINU, sub{ $_[ 0 ] - $_[ 1 ] } ],
    '*'          => [  2, T_OPERATOR,  2, H_MULT, sub{ $_[ 0 ] * $_[ 1 ] } ],
    '/'          => [  3, T_OPERATOR,  2, H_DIVI, sub{ &DIV( $_[ 0 ], $_[ 1 ] ) } ],
    '%'          => [  4, T_OPERATOR,  2, H_MODU, sub{ &MOD( $_[ 0 ], $_[ 1 ] ) } ],
    '**'         => [  5, T_OPERATOR,  2, H_EXPO, sub{ $_[ 0 ] ** $_[ 1 ] } ],
    '|'          => [  6, T_OPERATOR,  2, H_BWOR, sub{ $_[ 0 ] | $_[ 1 ] } ],
    '&'          => [  7, T_OPERATOR,  2, H_BWAN, sub{ $_[ 0 ] & $_[ 1 ] } ],
    '^'          => [  8, T_OPERATOR,  2, H_BWEO, sub{ $_[ 0 ] ^ $_[ 1 ] } ],
    '~'          => [  9, T_OPERATOR,  1, H_BWIV, sub{ ~( $_[ 0 ] ) } ],
    'fn('        => [ 10, T_OTHER,    -1, undef  ],
    '('          => [ 11, T_OPERATOR,  2, H_BBEG ],
    ','          => [ 12, T_OPERATOR, -1, H_COMA ],
    ')'          => [ 13, T_OPERATOR,  2, H_BEND ],
    '='          => [ 14, T_OPERATOR,  1, H_EQUA ],
    'OPERAND'    => [ 15, T_OTHER,     0, undef  ],
    'BEGIN'      => [ 16, T_OTHER,     0, undef  ],
    '#'          => [ 17, T_SENTINEL, -1, undef  ],
    'testfunc'   => [ 18, T_OTHER,     1, undef  ],
    'abs'        => [ 19, T_FUNCTION,  1, H_ABS_, sub{ abs( $_[ 0 ] ) } ],
    'int'        => [ 20, T_FUNCTION,  1, H_INT_, sub{ int( $_[ 0 ] ) } ],
    'floor'      => [ 21, T_FUNCTION,  1, H_FLOR, sub{ &POSIX::floor( $_[ 0 ] ) } ],
    'ceil'       => [ 22, T_FUNCTION,  1, H_CEIL, sub{ &POSIX::ceil( $_[ 0 ] ) } ],
    'rounddown'  => [ 23, T_FUNCTION,  2, H_RODD, sub{ &rounddown( $_[ 0 ], $_[ 1 ] ) } ],
    'round'      => [ 24, T_FUNCTION,  2, H_ROUD, sub{ &round( $_[ 0 ], $_[ 1 ] ) } ],
    'roundup'    => [ 25, T_FUNCTION,  2, H_RODU, sub{ &roundup( $_[ 0 ], $_[ 1 ] ) } ],
    'pct'        => [ 26, T_FUNCTION, VA, H_PCTG, sub{ &percentage( @_ ) } ],
    'gcd'        => [ 27, T_FUNCTION, VA, H_GCD_, sub{ &Math::BigInt::bgcd( @_ ) } ],
    'lcm'        => [ 28, T_FUNCTION, VA, H_LCM_, sub{ &Math::BigInt::blcm( @_ ) } ],
    'min'        => [ 29, T_FUNCTION, VA, H_MIN_, sub{ &List::Util::min( @_ ) } ],
    'max'        => [ 30, T_FUNCTION, VA, H_MAX_, sub{ &List::Util::max( @_ ) } ],
    'sum'        => [ 31, T_FUNCTION, VA, H_SUM_, sub{ &List::Util::sum( @_ ) } ],
    'avg'        => [ 32, T_FUNCTION, VA, H_AVRG, sub{ &AVG( @_ ) } ],
    'rand'       => [ 33, T_FUNCTION,  1, H_RAND, sub{ rand( $_[ 0 ] ) } ],
    'log'        => [ 34, T_FUNCTION,  1, H_LOGA, sub{ &LOG( $_[ 0 ] ) } ],
    'sqrt'       => [ 35, T_FUNCTION,  1, H_SQRT, sub{ sqrt( $_[ 0 ] ) } ],
    'deg2rad'    => [ 36, T_FUNCTION,  1, H_D2RD, sub{ &Math::Trig::deg2rad( $_[ 0 ] ) } ],
    'rad2deg'    => [ 37, T_FUNCTION,  1, H_R2DG, sub{ &Math::Trig::rad2deg( $_[ 0 ] ) } ],
    'dms'        => [ 38, T_FUNCTION,  3, H_DEGM, sub{ &DMS( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) } ],
    'dms2rad'    => [ 39, T_FUNCTION,  3, H_DD2R, sub{ &DMS2RAD( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) } ],
    'sin'        => [ 40, T_FUNCTION,  1, H_SINE, sub{ sin( $_[ 0 ] ) } ],
    'cos'        => [ 41, T_FUNCTION,  1, H_COSI, sub{ cos( $_[ 0 ] ) } ],
    'tan'        => [ 42, T_FUNCTION,  1, H_TANG, sub{ &Math::Trig::tan( $_[ 0 ] ) } ],
    'asin'       => [ 43, T_FUNCTION,  1, H_ASIN, sub{ &Math::Trig::asin( $_[ 0 ] ) } ],
    'acos'       => [ 44, T_FUNCTION,  1, H_ACOS, sub{ &Math::Trig::acos( $_[ 0 ] ) } ],
    'atan'       => [ 45, T_FUNCTION,  1, H_ATAN, sub{ &Math::Trig::atan( $_[ 0 ] ) } ],
    'atan2'      => [ 46, T_FUNCTION,  2, H_ATN2, sub{ &Math::Trig::atan2( $_[ 0 ], $_[ 1 ] ) } ],
    'hypot'      => [ 47, T_FUNCTION,  2, H_HYPT, sub{ &POSIX::hypot( $_[ 0 ], $_[ 1 ] ) } ],
    'pow'        => [ 48, T_FUNCTION,  2, H_POWE, sub{ $_[ 0 ] ** $_[ 1 ] } ],
    'geocentric_radius'         => [ 49, T_FUNCTION, 1, H_GERA, sub{ &geocentric_radius( $_[ 0 ] ) } ],
    'radius_of_latitude_circle' => [ 50, T_FUNCTION, 1, H_LATC, sub{ &radius_of_latitude_circle( $_[ 0 ] ) } ],
    'distance_between_points'   => [ 51, T_FUNCTION, 4, H_DBPT, sub{ &distance_between_points( $_[ 0 ], $_[ 1 ], $_[ 2 ], $_[ 3 ] ) } ],
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

sub LOG( $ )
{
    if( $_[ 0 ] == 0 ){
        die( qq{log( $_[0] ): Illegal operand.\n} );
    }
    return log( $_[ 0 ] );
}

sub DMS( $$$ )
{
    my $degrees = shift( @_ );
    my $min = shift( @_ );
    my $sec = shift( @_ );
    return $degrees + ( $min / 60 ) + ( $sec / 3600 );
}

sub DMS2RAD( $$$ )
{
    my $degrees = shift( @_ );
    my $min = shift( @_ );
    my $sec = shift( @_ );
    return &Math::Trig::deg2rad( &DMS( $degrees, $min, $sec ) );
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

sub AVG( @ )
{
    my $total = List::Util::sum( @_ );
    my $len = scalar( @_ );
    return $total / $len;
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


package FormulaParser;
use strict;
use warnings 'all';
use utf8;
use Encode;

# FormulaParser コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{HELPER} = shift( @_ );
    $self->{APPNAME} = shift( @_ );
    $self->{DEBUG} = shift( @_ );
    $self->{B_TEST} = shift( @_ );
    $self->{STACK} = FormulaStack->new( $self->{APPNAME}, $self->{DEBUG}, $self->{B_TEST} );
    $self->{OPF} = OutputFunc->new( $self->{APPNAME}, $self->{DEBUG}, 'parser' );
#    $self->Reset();
#    $self->opf->dPrint( qq{$self->{APPNAME}: FormulaParser: create\n} );
    return $self;               # 無名ハッシュ参照を返す
}

sub Reset()
{
    my $self = shift( @_ );
    $self->Stack->Reset();
    my $el_r = FormulaToken::NewOperator( "BEGIN" );
    $self->Stack->Push( $el_r );
}

sub opf()
{
    my $self = shift( @_ );
    return $self->{OPF};
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

    $self->opf->dPrint( qq{FormulaNormalization(): "$formula_raw"\n} );
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
    $expr =~ tr!Ａ-Ｚａ-ｚ０-９，．＋＊・･／＾（）＝!a-za-z0-9,.+***/^()=!;
    ## tr///で使えなかった → －
    $expr =~ s!－!-!go;
    $expr =~ s!√!sqrt!go;
    $expr =~ s!π!pi!go;
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
#    $expr =~ s!pow\(\s*([^,]+)\s*,\s*([^)]+)\)!($1^$2)!go;

    $self->opf->dPrint( qq{FormulaNormalizationOneLine(): "$expr_org" -> "$expr"\n} );
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
        $self->opf->dPrintf( qq{delete "%s" xxx "%s"\n}, $tokenL, $tokenR );
        if( $tokenL eq 'BEGIN' ){
            $bFormulaFin = 1;
            $self->opf->dPrint( qq{Check the end of the calculation formula.\n} );
        }
    }elsif( $act == TableProvider::E_FUNC ){
        my $stack_out = $self->Stack->Pop();
        $self->opf->dPrintf( qq{queing "%s", delete "%s"\n}, $tokenL, $tokenR );
        $self->Queuing( $ref_parser_output, $stack_out, $act );
    }elsif( $act == TableProvider::E_IGNR ){
    }else{
        my $msg = qq{"$tokenL", "$tokenR": Wrong combination.\n};
        $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
        $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetHere( $curr_token->id ) . "\n" );
        $self->opf->Die( $msg );
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
                $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
                $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetHere( $item->id ) . "\n" );
            }else{
                $msg = qq{"$simple_name": There is a problem with the calculation formula.\n};
            }
            $self->opf->Die( qq{$msg} );
        }
    }

    if( $bFunc && $act != TableProvider::E_FUNC ){
        my $msg = qq{"$simple_name(": ")" may be incorrect.\n};
        $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
        $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetHere( $item->id ) . "\n" );
        $self->opf->warnPrint( $msg );
    }

    $self->opf->dPrintf( qq{Queuing: 0x%04X, "%s"\n}, $newitem->flags, $newitem->data );
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
use Math::Trig qw/pi/;

#use constant SHIFT_REG_LEN => 2;

# FormulaLexer コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{APPNAME} = shift( @_ );
    $self->{DEBUG} = shift( @_ );
    $self->{OPF} = OutputFunc->new( $self->{APPNAME}, $self->{DEBUG}, 'lexer' );
#    $self->Reset();
#    $self->opf->dPrint( qq{$self->{APPNAME}: FormulaLexer: create\n} );
    return $self;               # 無名ハッシュ参照を返す
}

sub Reset()
{
    my $self = shift( @_ );
    @{ $self->{TOKENS} } = ();
}

sub opf()
{
    my $self = shift( @_ );
    return $self->{OPF};
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

        ## オペランド
        if( ( $$ref_expr =~ s!^([\-\+])(0x[\da-f]+)!!o ) ||
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
            $el_d = FormulaToken::NewOperand( "$operator$operand", $bHex );

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
            $el_d = FormulaToken::NewOperand( $operand, $bHex );
            ## 必要であれば暗黙の乗算子を挿入
            if( $self->IsNeedInsert( '*', $el_d, " $operand $$ref_expr", $ref_expr ) ){
                return $ret_obj;
            }
            $self->unshift( $el_d );
            $ret_obj = $el_d;

        }elsif( $$ref_expr =~ s!^(pi)(?=[^a-z])!!o ){
            $operand = eval( $1 );
            my $el_d = FormulaToken::NewOperand( $operand );
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
                    $fns =~ s!(([a-z0-9]+, ){10})!$1\n    !go;
                    my $info = $self->opf->GenMsg( 'info', qq{Supported functions:\n    $fns\n} );
                    $self->opf->Die( qq{"$funcname()": unknown function.\n$info} );
                }
                $bFunction = 1;
            }

            my $el_r = FormulaToken::NewOperator( $operator, $bFunction );
            ## 必要であれば暗黙の乗算子を挿入
            if( $self->IsNeedInsert( '*', $el_r, "$operator$$ref_expr", $ref_expr ) ){
                return $ret_obj;
            }
            $self->unshift( $el_r );
            $ret_obj = $el_r;

        }else{
            ## 先頭の半角スペースは除去されていて文字数ゼロでもない状態
            my $b_operator_is_confirmed = 0;
            if( $$ref_expr =~ m!^([\S]{2})!o ){
                $operator = $1;
                if( &TableProvider::IsOperatorExists( $operator ) ){
                    $$ref_expr = substr( $$ref_expr, 2 );
                    $b_operator_is_confirmed = 1;
                }
            }
            if( !$b_operator_is_confirmed ){
                $$ref_expr =~ m!^([\S])!o;
                $operator = $1;
                if( ! &TableProvider::IsOperatorExists( $operator ) ){
                    my $ops = join( ' ', &TableProvider::GetOperatorsList() );
                    my $info = $self->opf->GenMsg( 'info', qq{Supported operators: "$ops"\n} );
                    $self->opf->Die( qq{"$operator": unknown operator.\n$info} );
                }
                $$ref_expr = substr( $$ref_expr, 1 );
                $b_operator_is_confirmed = 1;
            }
            my $el_r = FormulaToken::NewOperator( $operator );
            ## 必要であれば暗黙の乗算子を挿入
            if( $self->IsNeedInsert( '*', $el_r, "$operator$$ref_expr", $ref_expr ) ){
                return $ret_obj;
            }
            $self->unshift( $el_r );
            $ret_obj = $el_r;
        }
    }

    if( $self->{DEBUG} ){
        my $token_data = 'undef';
        if( defined( $ret_obj ) ){
            $token_data = $ret_obj->data;
        }
        $self->opf->dPrint( qq{GetToken="$token_data", remain="$$ref_expr"\n} );
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
        $self->opf->dPrint( qq{IsNeedInsert(): \$operator="$operator", \$\$ref_expr="$$ref_expr"\n} );
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

# FormulaStack コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{APPNAME} = shift( @_ );
    $self->{DEBUG} = shift( @_ );
    $self->{B_TEST} = shift( @_ );
    $self->{OPF} = OutputFunc->new( $self->{APPNAME}, $self->{DEBUG}, 'stack' );
#    $self->Reset();
#    $self->opf->dPrint( qq{$self->{APPNAME}: FormulaStack: create\n} );
    if( $self->{B_TEST} ){
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

sub opf()
{
    my $self = shift( @_ );
    return $self->{OPF};
}

## 名前はPush()だが実際にはunshift()を使っている
sub Push( $ )
{
    my $self = shift( @_ );
    my $item = shift( @_ );

    unshift( @{ $self->{TOKENS} }, $item );

    $self->opf->dPrintf( qq{Push(): [%d] %s\n},
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

        $self->opf->dPrintf( qq{Pop(): [%d] %s -> "%s"\n},
            scalar( @{ $self->{TOKENS} } ),
            $self->GetItems(), $ret_item->data );
    }else{
        $self->opf->dPrint( qq{Pop(): enmpy!\n} );
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
        $self->opf->dPrint( qq{GetNewer(): enmpy!\n} );
    }

    return $ret_item;
}


package FormulaEvaluator;
use strict;
use warnings 'all';

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
    $self->{APPNAME} = shift( @_ );
    $self->{DEBUG} = shift( @_ );
    $self->{B_TEST} = shift( @_ );
    $self->{B_VERBOSEOUTPUT} = shift( @_ );
    $self->{B_RPN} = shift( @_ );
    $self->{OPF} = OutputFunc->new( $self->{APPNAME}, $self->{DEBUG}, 'evaluator' );
#    $self->Reset();
#    $self->opf->dPrint( qq{$self->{APPNAME}: FormulaEvaluator: create\n} );
    if( $self->{B_TEST} ){
        $self->Reset();
        my $el_r = FormulaToken::NewOperator( '*' );
        unshift( @{ $self->{RPN} }, $el_r );
        unshift( @{ $self->{RPN} }, $el_r );
        unshift( @{ $self->{TOKENS} }, $el_r );
        unshift( @{ $self->{TOKENS} }, $el_r );
        $self->Input( $el_r );
        $self->opf->dPrintf( qq{scalar( \@{ \$self->{RPN} } ) = %d\n}, scalar( @{ $self->{RPN} } ) );
        $self->opf->dPrintf( qq{scalar( \@{ \$self->{TOKENS} } ) = %d\n}, scalar( @{ $self->{TOKENS} } ) );
        my $usage = $self->GetUsage( 'none-operator' );
        $self->opf->dPrintf( qq{GetUsage() test: \$usage="$usage"\n} );
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

sub opf()
{
    my $self = shift( @_ );
    return $self->{OPF};
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
sub Input( $ )
{
    my $self = shift( @_ );
    my $token = $_[ 0 ];

    unshift( @{ $self->{RPN} }, $token );

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
        $self->opf->dPrint( qq{Input(): \$op="$op"\n} );
        if( ( $op eq '|' ) || ( $op eq '&' ) || ( $op eq '~' ) ){
            $self->{FLAGS} |= BIT_DISP_HEX;
        }
        my $subr = &TableProvider::GetSubroutine( $op );
        ## GetSubroutine() で undef になるオペレーターは
        ## Parser もしくは この手前で（例えばsentinel）フィルター済み
        my $need_argc = &TableProvider::GetArgc( $op );
        my @args = ();
        ## check
        my $argc_counter = 0;
        my $len = scalar( @{ $self->{TOKENS} } );
        my $check_len = $need_argc;
        $check_len = $len if( $need_argc == TableProvider::VA );
        if( $len < $check_len ){
            my $msg = qq{"$op": Operand missing.\n};
            $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
            $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetHere( $token->id ) . "\n" );
            $msg .= $self->GetUsage( $op );
            $self->opf->Die( $msg );
        }
        for( $argc_counter=0; $argc_counter<$check_len; $argc_counter++ ){
            my $el = ${ $self->{TOKENS} }[ $argc_counter ];
            if( !( $el->IsOperand() ) ){
                if( &TableProvider::IsSentinel( $el->data ) ){
                    if( $need_argc == TableProvider::VA ){
                        $need_argc = $argc_counter;
                        $self->opf->dPrint( qq{variable arguments: \$need_argc="$need_argc"\n} );
                        if( $need_argc == 0 ){
                            my $msg = qq{"$op": No operands.\n};
                            $msg .= $self->GetUsage( $op );
                            $self->opf->Die( $msg );
                        }
                        last;
                    }else{
                        my $msg = qq{"$op": Not enough operands.\n};
                        $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
                        $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetHere( $token->id ) . "\n" );
                        $msg .= $self->GetUsage( $op );
                        $self->opf->Die( $msg );
                    }
                }
                last;
            }
        }
        ## calc
        if( $argc_counter == $need_argc ){
            for( my $idx=0; $idx<$need_argc; $idx++ ){
                my $el = shift( @{ $self->{TOKENS} } );
                unshift( @args, ( $el->data + 0 ) );
            }
            if( $bFunction ){
                my $sentinel = shift( @{ $self->{TOKENS} } );
#                printf( qq{E: 0x%X, "%s"\n}, $sentinel->flags, $sentinel->data );
                if( &TableProvider::IsSentinel( $sentinel->data ) ){
                    $self->opf->dPrint( qq{\$need_argc="$need_argc": Retrieve sentinel.\n} );
                }else{
                    unshift( @{ $self->{TOKENS} }, $sentinel );
                    my $msg = qq{"$op": The number of arguments is incorrect.\n};
                    $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
                    $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetHere( $token->id ) . "\n" );
                    $msg .= $self->GetUsage( $op );
                    $self->opf->Die( $msg );
                }
            }
            $self->RegisterClear();
            my $formula = '';
            if( &TableProvider::IsOperatorExists( $op ) ){
                my $len = scalar( @args );
                if( $len == 1 ){
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
            eval{   ## 子処理の戻り先を積んでおく（die()を補足）
                $result = &{ $subr }( @args );
            };
            if( $@ ){
                my $msg = $@;
                $msg =~ s/ at .*\d\.$/./;
                $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetFormula() . "\n" );
                $msg .= $self->opf->GenMsg( 'info', $self->{HELPER}->GetHere( $token->id ) . "\n" );
                $msg .= $self->GetUsage( $op );
                $self->opf->Die( $msg );
            }
            $self->{REGISTER} = $result;
            if( $self->{B_VERBOSEOUTPUT} ){
                print( qq{$self->{FORMULA} = $result\n} );
            }
            $token = FormulaToken::NewOperand( $result );
        }
    }

    unshift( @{ $self->{TOKENS} }, $token );
    if( ( $self->{B_VERBOSEOUTPUT} ) &&
        ( $self->{B_RPN} || $self->{DEBUG} ) ){
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
        $usage =~ s/\n//go;
        $usage = 'usage: ' . $usage;
        $info = $self->opf->GenMsg( 'info', $usage ) . "\n";
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

sub RegisterToString( $ )
{
    my $self = shift( @_ );
    my $register = $self->GetRegister();

    my $ret_val = $register;
    my $raw_str = '';

    ## ex) 2.2e-07 -> 0.00000022
    if( $register =~ m/e\-(\d+)$/ ){
        if( $self->{B_VERBOSEOUTPUT} ){
            $raw_str = qq{ ( = $register )};
        }
        my $width = $1 + 1;
        $self->opf->dPrint( qq{\$width="$width"\n} );
        $ret_val = sprintf( qq{%.${width}f}, $register );
    ## ex) 1.59226291813144e+15 -> 1592262918131443.25
    }elsif( $register =~ m/e\+(\d+)$/ ){
        if( $self->{B_VERBOSEOUTPUT} ){
            $raw_str = qq{ ( = $register )};
        }
        my $width = 20;
        $ret_val = sprintf( qq{%.${width}f}, $register );
        $self->opf->dPrint( qq{\$width="$width" -> "$ret_val"\n} );
        $ret_val =~ s!\.?0+$!!o;
    }else{
        $ret_val = sprintf( qq{%s}, $register );
    }

    my $hexadecimal = '';
    if( $self->{FLAGS} & BIT_DISP_HEX ){
        ## 負数の場合
        if( $register & ( 1 << 63 ) ){
            $hexadecimal .= sprintf( qq{ ( = %d )}, $register - ( 1 << 64 ) );
        }
        $hexadecimal .= sprintf( qq{ ( = 0x%X )}, $register );
    }

    $ret_val = qq{$ret_val$raw_str$hexadecimal};

    return $ret_val;
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

# FormulaEngine コンストラクタ
sub new {
    my( $class, $name ) = shift( @_ );
    my $self = {};              # 無名ハッシュ参照
    bless( $self, $class );     # クラス名を関連付け
    $self->{NAME} = $name;
    $self->{APPNAME} = shift( @_ );
    $self->{DEBUG} = shift( @_ );
    $self->{B_TEST} = shift( @_ );
    $self->{B_VERBOSEOUTPUT} = shift( @_ );
    $self->{B_RPN} = shift( @_ );
    $self->{OPF} = OutputFunc->new( $self->{APPNAME}, $self->{DEBUG}, 'engine' );
    $self->{TBL_PROVIDER} = TableProvider->new( $self->{APPNAME},
        $self->{DEBUG}, $self->{B_TEST} );
    $self->{LEXER} = FormulaLexer->new( $self->{APPNAME}, $self->{DEBUG} );
    $self->{HELPER} = FormulaHelper->new( $self->{LEXER} );
    $self->{PARSER} = FormulaParser->new( $self->{HELPER}, $self->{APPNAME}, $self->{DEBUG}, $self->{B_TEST} );
    $self->{EVALUATOR} = FormulaEvaluator->new( $self->{HELPER}, $self->{APPNAME},
        $self->{DEBUG}, $self->{B_TEST},
        $self->{B_VERBOSEOUTPUT}, $self->{B_RPN} );
#    $self->Reset();
#    $self->opf->dPrint( qq{$self->{APPNAME}: FormulaEngine: create\n} );
    if( $self->{B_TEST} ){
        my $help_unknown_operator = &OutputFunc::FmtHelp( '***' );
        $self->opf->dPrint( qq{\$help_unknown_operator="$help_unknown_operator"\n} );
        $self->Reset();
        my $tblProvider2 = TableProvider->new( $self->{APPNAME}, $self->{DEBUG}, $self->{B_TEST} );
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

sub opf()
{
    my $self = shift( @_ );
    return $self->{OPF};
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
        $self->opf->dPrint( qq{\$expr is empty\n} );
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
            $self->opf->warnPrint( qq{$msg: Ignore. The calculation process has been completed.\n} );
            return -1;
        }

        my @evaluator_queue;
        $bParserFinish = $self->Parser->RouteDetermination( $curr_token, \@evaluator_queue );
        $Evaluator_remain = $self->Evaluator->Inputs( @evaluator_queue );
    }

    if( $Evaluator_remain > 1 ){
        $self->opf->warnPrint( qq{There may be an error in the calculation formula.\n} );
        $self->opf->warnPrint( qq{Remain RPN: } . $self->Evaluator->GetTokens() . "\n" );
    }

    if( $self->{B_VERBOSEOUTPUT} ){
        print( qq{Formula: '} . $self->Lexer->GetFormula() . qq{'\n} );
        print( qq{    RPN: '} . $self->Evaluator->GetRpn() . qq{'\n} );
    }

    if( $self->{B_RPN} ){
        print( $self->Evaluator->GetRpn() . "\n" );
    }elsif( $self->{B_VERBOSEOUTPUT} ){
        print( qq{ Result: } . $self->Evaluator->RegisterToString() . "\n" );
    }else{
        print( $self->Evaluator->RegisterToString() . "\n" );
    }

    return 0;
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
    &init_script();

    ## 引数解析
    &parse_arg( @_ );

    my $fEngine = FormulaEngine->new( $main::appname, $main::debug, $main::bTest,
        $main::bVerboseOutput, $main::bRpn );
    my $status = $fEngine->Run( @main::expressions_raw );

    return $status;
}

##########
## 初期化処理
## Revision: 1.3
sub init_script()
{
    ### GLOBAL ###
#    $main::apppath = dirname( $0 );
    $main::appname = basename( $0 );
    $main::debug = 0;
#    $main::debug = 1;
    $main::bTest = 0;
    $main::bVerboseOutput = 0;
    $main::bRpn = 0;
#    $main::bIsStdoutATty = -t STDOUT;
    @main::expressions_raw = ();
    ##############

    $opf = OutputFunc->new( $main::appname, $main::debug, 'dbg' );
}

##########
## 引数解析
sub parse_arg()
{
    my @val = @_;

    ## 引数分のループを回す
    while( my $myparam = shift( @val ) ){

        ## アルファベットは1文字ずつ分割
        if( $myparam =~ s/^-([dhrv])(\S+)$/-$1/o ){
            my $remainparam = "-$2";
            $opf->dPrintf( qq{\$myparam="%s", \$remainparam="%s"\n}, $myparam, $remainparam );
            unshift( @val, $remainparam );
        }

        ## デバッグモードOn
        if    ( $myparam eq '-d' || $myparam eq '--debug' ){
            $main::debug = 1;
            $opf->SetDebug( $main::debug );
            $main::bVerboseOutput = 1;
        }elsif( $myparam eq '-h' || $myparam eq '--help' ){
            $opf->Usage( 0 );
            exit( 0 );
        }elsif( $myparam eq '-r' || $myparam eq '--rpn' ){
            $main::bRpn = 1;
        }elsif( $myparam eq '-v' || $myparam eq '--verbose' ){
            $main::bVerboseOutput = 1;
        }elsif( $myparam eq '--test-test' ){
            $main::bTest = 1;
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

PI (=3.14159265358979)

=head2 OPERATORS

+ - * / % ** | & ^ ~ ( , ) =

=head2 FUNCTIONS

abs, int, floor, ceil, rounddown, round, roundup, pct, gcd, lcm,
min, max, sum, avg, rand, log, sqrt, deg2rad, rad2deg, dms,
dms2rad, sin, cos, tan, asin, acos, atan, atan2, hypot, pow,
geocentric_radius, radius_of_latitude_circle, distance_between_points

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

If you specify the operands in hexadecimal or use bitwise operators,
the calculation result will also be displayed in hexadecimal.

  $ c '0xfc & 0x10 ='
  16 ( = 0x10 )

There is no option switch to display the calculation results in hexadecimal.
However, you can display it by performing a bitwise 'I<|[OR]>' operation with 0.

  $ c '100|0'
  100 ( = 0x64 )

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
   Result: 0.00000022 ( = 2.2e-07 )
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

Calculate the distance between two points.

  ex)
  Madagascar:        degrees: -18.76694, 46.8691
  Galapagos Islands: degrees: -0.3831, -90.42333

  $ c 'distance_between_points( deg2rad( -18.76694 ), deg2rad( 46.8691 ),
       deg2rad( -0.3831 ), deg2rad( -90.42333 ) ) / 1000 ='
  14907.357977036

If you want to specify latitude and longitude in DMS, use dms2rad().
Be sure to include the sign if the value is negative.

  $ c 'distance_between_points( ' \
      'dms2rad( -18, -46, -0.984000000006233 ), dms2rad( 46, 52, 8.76000000001113 ), ' \
      'dms2rad( -0, -22, -59.16 ), dms2rad( -90, -25, -23.9880000000255 ) ) / 1000 ='
  14907.357977036

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

Bitwise OR. C<0x2 | 0x4> -> C<6 ( = 0x6 )>.

=item C<&>

Bitwise AND. C<0x6 & 0x4> -> C<4 ( = 0x4 )>.

=item C<^>

Bitwise exclusive or. C<0x6 ^ 0x4> -> C<2 ( = 0x2 )>.

=item C<~>

Bitwise inversion. C<~0> -> C<0xFFFFFFFFFFFFFFFFFF>.

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

pct( NUMERATOR, DENOMINATOR [, DECIMAL_PLACES ] ). Returns the percentage, rounding the number if DECIMAL_PLACES is specified.

=item C<gcd>

gcd( A,.. ). Returns the greatest common divisor (GCD), which is the largest positive integer that divides each of the operands. [Math::BigInt::bgcd()]

=item C<lcm>

lcm( A,.. ). Returns the least common multiple (LCM). [Math::BigInt::blcm()]

=item C<min>

min( A,.. ). Returns the entry in the list with the lowest numerical value. [List::Util]

=item C<max>

max( A,.. ). Returns the entry in the list with the highest numerical value. [List::Util]

=item C<sum>

sum( A,.. ). Returns the numerical sum of all the elements in the list. [List::Util]

=item C<avg>

avg( A,.. ). Returns the average value of all elements in a list.

=item C<log>

log( N ). Returns the natural logarithm (base e) of N. [Perl Native]

=item C<sqrt>

sqrt( N ). Return the positive square root of N. Works only for non-negative operands. [Perl Native]

=item C<deg2rad>

deg2rad( <DEGREES> ) -> <RADIANS>. [Math::Trig]

=item C<rad2deg>

rad2deg( <RADIANS> ) -> <DEGREES>. [Math::Trig]

=item C<sin>

sin( <RADIANS> ). Returns the sine of <RADIANS>. [Perl Native]

=item C<cos>

cos( <RADIANS> ). Returns the cosine of <RADIANS>. [Perl Native]

=item C<tan>

tan( <RADIANS> ). Returns the tangent of <RADIANS>. [Math::Trig]

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

=item C<pow>

pow( A, B ). Exponentiation. "pow( 2, 3 )" -> 8. Similarly, "2 ** 3". [Perl Native]

=item C<geocentric_radius>

geocentric_radius( LAT ). Given a latitude (in radians), returns the distance from the center of the Earth to its surface (in meters).

=item C<radius_of_latitude_circle>

radius_of_latitude_circle( LAT ). Given a latitude (in radians), returns the radius of that parallel (in meters).

=item C<distance_between_points>

distance_between_points( ptA_lat, ptA_lon, ptB_lat, ptB_lon ). Calculates and returns the distance (in meters) between two points, latitude and longitude must be specified in radians.

=back

=head1 SEE ALSO

=over 4

=item L<perl>(1)

=item L<POSIX>

=item L<Math::BigInt>

=item L<Math::Trig>

=item L<List::Util>

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
