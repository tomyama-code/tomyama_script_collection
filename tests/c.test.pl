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

my $apppath = dirname( $0 );
chdir( "$apppath/../" );
my $cur_dir = getcwd();
$apppath = $cur_dir . '/tests';
my $TARGCMD = "./tests/cmd_wrapper";

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
    $cmd->stdout_is_eq( qq{33 \( = 0x21 \)\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x0055**2-0XC-2='} );
    $cmd->exit_is_num( 0, qq{./c '0x0055**2-0XC-2='} );
    $cmd->stdout_is_eq( qq{7211 \( = 0x1C2B \)\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x9+0xc&0xe='} );
    $cmd->exit_is_num( 0, qq{./c '0x9+0xc&0xe='} );
    $cmd->stdout_is_eq( qq{4 \( = 0x4 \)\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x9&0xc+0xe='} );
    $cmd->exit_is_num( 0, qq{./c '0x9&0xc+0xe='} );
    $cmd->stdout_is_eq( qq{8 \( = 0x8 \)\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x9+0xc|0xe='} );
    $cmd->exit_is_num( 0, qq{./c '0x9+0xc|0xe='} );
    $cmd->stdout_is_eq( qq{31 \( = 0x1F \)\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x9|0xc+0xe='} );
    $cmd->exit_is_num( 0, qq{./c '0x9|0xc+0xe='} );
    $cmd->stdout_is_eq( qq{27 \( = 0x1B \)\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x1 ^ 0x2 ='} );
    $cmd->exit_is_num( 0, qq{./c '0x1 ^ 0x2 ='} );
    $cmd->stdout_is_eq( qq{3 ( = 0x3 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x3 ^ 0x2 ='} );
    $cmd->exit_is_num( 0, qq{./c '0x3 ^ 0x2 ='} );
    $cmd->stdout_is_eq( qq{1 ( = 0x1 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0x3 ^ 0x3 ='} );
    $cmd->exit_is_num( 0, qq{./c '0x3 ^ 0x3 ='} );
    $cmd->stdout_is_eq( qq{0 ( = 0x0 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '5 ^ 3 ='} );
    $cmd->exit_is_num( 0, qq{./c '5 ^ 3 ='} );
    $cmd->stdout_is_eq( qq{6 ( = 0x6 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '~1+1='} );
    $cmd->exit_is_num( 0, qq{./c '~1+1='} );
    $cmd->stdout_is_eq( qq{18446744073709551615 \( = -1 \) \( = 0xFFFFFFFFFFFFFFFF \)\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1+~1='} );
    $cmd->exit_is_num( 0, qq{./c '1+~1='} );
    $cmd->stdout_is_eq( qq{18446744073709551615 \( = -1 \) \( = 0xFFFFFFFFFFFFFFFF \)\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '~1*2='} );
    $cmd->exit_is_num( 0, qq{./c '~1*2='} );
    $cmd->stdout_is_eq( qq{36893488147419103232 \( = -1 \) \( = 0xFFFFFFFFFFFFFFFF \)\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '2*~1='} );
    $cmd->exit_is_num( 0, qq{./c '2*~1='} );
    $cmd->stdout_is_eq( qq{36893488147419103232 \( = -1 \) \( = 0xFFFFFFFFFFFFFFFF \)\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '2' '~1='} );
    $cmd->exit_is_num( 0, qq{./c '2' '~1='} );
    $cmd->stdout_is_eq( qq{36893488147419103232 \( = -1 \) \( = 0xFFFFFFFFFFFFFFFF \)\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0xfc & 0x10  ~0x1 | 0x8 =' -v} );
    $cmd->exit_is_num( 0, qq{./c '0xfc & 0x10  ~0x1 | 0x8 =' -v} );
    $cmd->stdout_like( qr/\n    RPN: '252 16 1 ~ \* & 8 \|'\n/ );
    $cmd->stdout_like( qr/\n Result: 252 \( = 0xFC \)\n/ );
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

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'int(10/3*100+0.5)/100='} );
    $cmd->exit_is_num( 0, qq{./c 'int(10/3*100+0.5)/100='} );
    $cmd->stdout_is_eq( qq{3.33\n} );
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

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'hypot(1920, 1080 )='} );
    $cmd->exit_is_num( 0, qq{./c 'hypot(1920, 1080 )='} );
    $cmd->stdout_is_eq( qq{2202.9071700823\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(power(2,100)+power(2,100))='} );
    $cmd->exit_isnt_num( 0, qq{./c 'sqrt(power(2,100)+power(2,100))='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: pow: \$arg_counter="1": The number of operands is incorrect\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(power(2, 100)+power(2, 100))='} );
    $cmd->exit_is_num( 0, qq{./c 'sqrt(power(2, 100)+power(2, 100))='} );
    $cmd->stdout_is_eq( qq{1592262918131443.25\n} );    ## 1592262918131443.1411559535896932
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
    $cmd->stdout_is_eq( qq{0.00000022\n} );             ## 0.00000022
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

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'radius_of_lat_circle( deg2rad( 35.68129 ) ) / 1000 ='} );
    $cmd->exit_is_num( 0, qq{./c 'radius_of_lat_circle( deg2rad( 35.68129 ) ) / 1000 ='} );
    $cmd->stdout_is_eq( qq{5186.70483557997\n}, qq{地球が楕円である事を考慮して東京駅を通る緯線の半径（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance( deg2rad( 35.68129 ), deg2rad( 139.76706 ), deg2rad( 34.70248 ), deg2rad( 135.49595 ) ) / 1000'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance( deg2rad( 35.68129 ), deg2rad( 139.76706 ), deg2rad( 34.70248 ), deg2rad( 135.49595 ) ) / 1000'} );
    $cmd->stdout_like( qr/^403.50509975960[89]\n/, qq{東京駅から大阪駅までの距離（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance( deg2rad( 35.68129 ), deg2rad( 139.76706 ), deg2rad( -69.00439 ), deg2rad( 39.5822 ) ) / 1000'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance( deg2rad( 35.68129 ), deg2rad( 139.76706 ), deg2rad( -69.00439 ), deg2rad( 39.5822 ) ) / 1000'} );
    $cmd->stdout_is_eq( qq{14091.3660897614\n}, qq{東京駅から昭和基地までの距離（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance( deg2rad( 35.68129, 139.76706 ), deg2rad( -69.00439, 39.5822 ) ) / 1000'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance( deg2rad( 35.68129, 139.76706 ), deg2rad( -69.00439, 39.5822 ) ) / 1000'} );
    $cmd->stdout_is_eq( qq{14091.3660897614\n}, qq{東京駅から昭和基地までの距離（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) ) / 1000'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance( deg2rad( 35.68129, 139.76706, -69.00439, 39.5822 ) ) / 1000'} );
    $cmd->stdout_is_eq( qq{14091.3660897614\n}, qq{東京駅から昭和基地までの距離（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151 ), dms2rad( -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) ) / 1000'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151 ), dms2rad( -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) ) / 1000'} );
    $cmd->stdout_is_eq( qq{14091.3660897614\n}, qq{東京駅から昭和基地までの距離（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'geo_distance( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) ) / 1000'} );
    $cmd->exit_is_num( 0, qq{./c 'geo_distance( dms2rad( 35, 40, 52.6439999999894, 139, 46, 1.41599999995151, -69, 0, -15.8040000000028, 39, 34, 55.920000000001 ) ) / 1000'} );
    $cmd->stdout_is_eq( qq{14091.3660897614\n}, qq{東京駅から昭和基地までの距離（km）} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'abs(-29.3577535427913)='} );
    $cmd->exit_is_num( 0, qq{./c 'abs(-29.3577535427913)='} );
    $cmd->stdout_is_eq( qq{29.3577535427913\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log(3)='} );
    $cmd->exit_is_num( 0, qq{./c 'log(3)='} );
    $cmd->stdout_is_eq( qq{1.09861228866811\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log(0)/log(2)='} );
    $cmd->exit_isnt_num( 0, qq{./c 'log(0)/log(2)='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: log\( 0 \): Illegal operand\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'log(~0+1)/log(2)='} );
    $cmd->exit_is_num( 0, qq{./c 'log(~0+1)/log(2)='} );
    $cmd->stdout_is_eq( qq{64 ( = 0x40 )\n}, qq{64bit: perlの整数は固定幅ではないが基本は64bitが多いはず。} );
    $cmd->stderr_is_eq( qq{}, qq{"~0+1": perlの整数は固定幅ではないので桁溢れしない。} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pow_inv( ~0+1, 2 )'} );
    $cmd->exit_is_num( 0, qq{./c 'pow_inv( ~0+1, 2 )'} );
    $cmd->stdout_is_eq( qq{64 ( = 0x40 )\n}, qq{64bit: perlの整数は固定幅ではないが基本は64bitが多いはず。} );
    $cmd->stderr_is_eq( qq{}, qq{"~0+1": perlの整数は固定幅ではないので桁溢れしない。} );
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
    $cmd->stderr_like( qr/\nc: lexer: info: Supported functions:\n/ );
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

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pct( 2, 3 )'} );
    $cmd->exit_is_num( 0, qq{./c 'pct( 2, 3 )'} );
    $cmd->stdout_is_eq( qq{66.6666666666667\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pct( 2, 3, 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'pct( 2, 3, 1 )'} );
    $cmd->stdout_is_eq( qq{66.7\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pct( 2, 3, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'pct( 2, 3, 0 )'} );
    $cmd->stdout_is_eq( qq{67\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pct( 2, 3, -1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'pct( 2, 3, -1 )'} );
    $cmd->stdout_is_eq( qq{70\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pct( 2 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'pct( 2 )'} );
    $cmd->stdout_is_eq( qq{} );
    $cmd->stderr_like( qr/^c: evaluator: error: pct: Not enough operands.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pct()'} );
    $cmd->exit_isnt_num( 0, qq{./c 'pct()'} );
    $cmd->stdout_is_eq( qq{} );
    $cmd->stderr_like( qr/^c: evaluator: error: "pct": Operand missing\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'pct( 2, 0 )'} );
    $cmd->exit_isnt_num( 0, qq{./c 'pct( 2, 0 )'} );
    $cmd->stdout_is_eq( qq{} );
    $cmd->stderr_like( qr/^c: evaluator: error: Illegal division by zero.\n/ );
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

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( -10, 10, 9, 1 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linspace( -10, 10, 9, 1 )'} );
    $cmd->stdout_is_eq( qq{( -10, -7, -5, -2, 0, 2, 5, 7, 10 )\n} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'linspace( -10, 10, 0 )'} );
    $cmd->exit_is_num( 0, qq{./c 'linspace( -10, 10, 0 )'} );
    $cmd->stdout_is_eq( qq{-10\n} );
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
    $cmd->stderr_like( qr/^c: lexer: error: "_": unknown operator\.\n/ );
    $cmd->stderr_like( qr/\nc: lexer: info: Supported operators: / );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(#)='} );
    $cmd->exit_isnt_num( 0, qq{./c 'sqrt(#)='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: lexer: error: "#": unknown operator\.\n/ );
    $cmd->stderr_like( qr/\nc: lexer: info: Supported operators: / );
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

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt( 1920 ** 2, 1080 ** 2 ) ='} );
    $cmd->exit_isnt_num( 0, qq{./c 'sqrt( 1920 ** 2, 1080 ** 2 ) ='} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: sqrt: \$arg_counter="2": The number of operands is incorrect\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(-1)'} );
    $cmd->exit_isnt_num( 0, qq{./c 'sqrt(-1)'} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^c: evaluator: error: Can't take sqrt of \-1\.\n/ );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '1+(2+(3+(4+(5+(6+((7+8*9)))))))=' --test-test -d} );
    $cmd->exit_is_num( 0, qq{./c '1+(2+(3+(4+(5+(6+((7+8*9)))))))=' --test-test -d} );
    ## OutputFunc
    $cmd->stdout_like( qr/\nengine: \$help_unknown_operator="  \*\*\*\n/, 'OutputFunc' );
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
    $cmd->stdout_like( qr/\n Result: 1125899906842624 \( = 1\.12589990684262e\+15 \)\n/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD 'sqrt(power(2, 100)+power(2, 100))=' --verbose} );
    $cmd->exit_is_num( 0, qq{./c 'sqrt(power(2, 100)+power(2, 100))=' --verbose} );
    $cmd->stdout_like( qr/\n Result: 1592262918131443\.25 \( = 1\.59226291813144e\+15 \)\n/ );  ## 1592262918131443.1411559535896932
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD '0.22*10**(-6)=' --verbose} );
    $cmd->exit_is_num( 0, qq{./c '0.22*10**(-6)=' --verbose} );
    $cmd->stdout_like( qr/\n Result: 0.00000022 \( = 2\.2e\-07 \)\n/ );            ## 0.00000022
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
    $cmd->stdout_like( qr/\n Result: 51 \( = 0x33 \)\n/ );
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
