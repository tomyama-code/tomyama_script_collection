#!/usr/bin/perl -w
################################################################################
## CL -- CLOCK PROGRAM
##
## - A simple clock script with a Keep-Alive function to prevent TCP session
##   timeouts by maintaining active traffic during remote operations.
##
## - Version: 1
## - $Revision: 2.37 $
##
## - Author: 2005-2026, tomyama
## - Intended primarily for personal use, but BSD license permits redistribution.
##
## BSD 2-Clause License:
## Copyright (c) 2005-2026, tomyama
## All rights reserved.
################################################################################

use strict;
use warnings;
use File::Basename qw(dirname basename);
use Time::Local qw{timelocal};
use POSIX       qw{uname getcwd};
use Time::HiRes;

use constant FONT_W_LEN =>  6;
use constant FONT_H_LEN => 10;

# ( $sec, $minute, $hour, $mday, $month, $year ) = localtime( $epoch )
use constant C_SEC  => 0;
use constant C_MIN  => 1;
use constant C_HOR  => 2;
use constant C_DAY  => 3;
use constant C_MON  => 4;
use constant C_YEAR => 5;

## ANSI escape sequences: Color Definition
my %ANSI_es = (
    'RESET'           =>  '0',
    'BRIGHTER_COLORS' =>  '1',
    'UNDERLINED_TEXT' =>  '4',
    'FLASHING_TEXT'   =>  '5',
    'FG_BLACK'        => '30',
    'FG_RED'          => '31',
    'FG_GREEN'        => '32',
    'FG_YELLOW'       => '33',
    'FG_BLUE'         => '34',
    'FG_PURPLE'       => '35',
    'FG_CYAN'         => '36',
    'FG_WHITE'        => '37',
    'BG_BLACK'        => '40',
    'BG_RED'          => '41',
    'BG_GREEN'        => '42',
    'BG_YELLOW'       => '43',
    'BG_BLUE'         => '44',
    'BG_PURPLE'       => '45',
    'BG_CYAN'         => '46',
    'BG_WHITE'        => '47',
);

my $COLOR_RESET = qq{[$ANSI_es{'RESET'}m};
my $HOL_COLOR   = qq{[$ANSI_es{'BRIGHTER_COLORS'};$ANSI_es{'FG_RED'}m};
my $SUN_COLOR   = qq{[$ANSI_es{'FG_RED'}m};
my $SAT_COLOR   = qq{[$ANSI_es{'FG_BLUE'}m};
my $CUR_COLOR   = qq{[$ANSI_es{'FG_BLACK'}m[$ANSI_es{'BG_GREEN'}m};
my $DEF_COLOR_LIGHT = qq{$COLOR_RESET[$ANSI_es{'FG_BLACK'}m[$ANSI_es{'BG_WHITE'}m};
my $DEF_COLOR_DARK  = qq{$COLOR_RESET[$ANSI_es{'FG_WHITE'}m[$ANSI_es{'BG_BLACK'}m};
my $DEF_COLOR = $DEF_COLOR_DARK;

exit( &pl_main( @ARGV ) );


sub pl_main( @ )
{
    local $SIG{INT} = sub{
        $main::loopsw = 0;
    };

    ## 初期化処理
    &init_script();

    ## 引数解析
    &parse_arg( @_ );

    &setup_clock();

    $main::loopsw = 1;
    while( $main::loopsw ){
        &print_clock( time() );
        &sleep_until_boundary( $main::interval );
    }


    print( $COLOR_RESET );
    print( "${main::appname}: exitting...\n" );

    return 0;
}

##########
## 初期化処理
## Revision: 1.3
sub init_script()
{
    ### GLOBAL ###
    $main::apppath = &File::Basename::dirname( $0 );
    $main::appname = &File::Basename::basename( $0 );
    $main::interval = 1;
    $main::use_large_font = 0;

    return;
}

##########
## 引数解析
sub parse_arg()
{
    my @val = @_;

    ## 引数分のループを回す
    while( my $myparam = shift( @val ) ){
        if( $myparam eq '-h' || $myparam eq '--help' ){
            print( &GetHelpMsg() );
            exit( 0 );
        }elsif( $myparam eq '-l' ){
            $main::use_large_font = 1;
        }elsif( $myparam eq '-v' || $myparam eq '--version' ){
            &PrintVersion();
            exit( 0 );
        }else{
            if( &is_interval_sec( $myparam ) == 0 ){
                die( "usage: ${main::appname} [1-60]\n" );
            }
            $main::interval = $myparam;
        }
    }
}

sub GetHelpMsg()
{
    my $ver = &GetVersion();

    my $msg = qq{Usage: ${main::appname} [OPTIONS] [INTERVAL]\n} .
              qq{\n} .
              qq{Version: $ver\n} .
              qq{\n} .
              qq{This is a clock script.\n} .
              qq{A clock script created to act as a Keep-Alive mechanism, \n} .
              qq{preventing TCP session timeouts during remote work.\n} .
              qq{\n} .
              qq{Supports two display modes:\n} .
              qq{  - Normal Mode: Displays time in plain text. (default)\n} .
              qq{  - Large Font Mode (-l): \n} .
              qq{                 Displays time in large ASCII art, \n} .
              qq{                 similar to the 'banner' command.\n} .
              qq{\n} .
              qq{Interactive Commands (during execution):\n} .
              qq{  - Ctrl + C     Exit\n} .
              qq{  - L + Enter    Switch to Large Font Mode\n} .
              qq{  - N + Enter    Switch to Normal Mode\n} .
              qq{  - <INTERVAL> + Enter \n} .
              qq{                 Update interval in seconds (1-60)\n} .
              qq{  - Enter        Refresh the display immediately\n} .
              qq{\n} .
              qq{Options:\n} .
              qq{  -l:            Enable Large Font Mode (ASCII art).\n} .
              qq{  -v, --version: Display script version, Perl version, and exit.\n} .
              qq{  -h, --help:    Display this help and exit.\n} .
              qq{\n} .
              qq{Arguments:\n} .
              qq{  [INTERVAL]     Update interval in seconds (1-60). Default is 1.\n} .
              qq{\n};

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
    my $rev = q{$Revision: 2.37 $};
    $rev =~ s!^\$[R]evision: (\d+\.\d+) \$$!$1!o;
    return $rev;
}

sub update_moon_age_timing( $ )
{
    if( defined( $_[ 0 ] ) ){
        $main::epoch_update_timing_moon_age = $_[ 0 ];
    }
    return $main::epoch_update_timing_moon_age;
}

sub is_interval_sec( $ )
{
    my $interval = shift( @_ );
    my $bRet = 0;
    if( $interval =~ m/^\d+$/o ){
        if( 1 <= $interval && $interval <= 60 ){
            $bRet = 1;
        }
    }
    return $bRet;
}

sub setup_clock()
{
    ( $main::termX, $main::termY ) = &GetTermSize();
    $main::screenX = $main::termX;
    @main::month = ( 'January',
                     'February',
                     'March',
                     'April',
                     'May',
                     'June',
                     'July',
                     'August',
                     'September',
                     'October',
                     'November',
                     'December'
    );

    &update_moon_age_timing( -1 );

    if( $main::use_large_font == 0 ){
        &setup_clock_normal();
    }else{
        &setup_clock_use_large_font();
    }

    &read_holiday();
    @main::tm_last = ( -1, -1, -1, -1, -1, -1, -1 );

    &pos_printf( 3, 2, qq{CLOCK  (Update: ${main::interval}s or Enter. } .
                               qq{Ctrl+C: exit. } .
                               qq{Font: [N]ormal <-> [L]arge.)\n} );

    # 標準出力をオートフラッシュ（バッファリング無効）
    $| = 1;

    return 0;
}

sub setup_clock_normal()
{
    $main::screenY = 23;
    $main::sep = '*' . '    -    +'x5 . '    -    *';
    @main::wday = ( "${SUN_COLOR}Sun${DEF_COLOR}",
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    "${SAT_COLOR}Sat${DEF_COLOR}"
    );
    $main::bar_pos_x = 2;

    &screen_clear();

    &pos_printf( 1, 12, "$main::sep\n" );

    &pos_printf( 1, 16, "$main::sep\n" );

    my $label_w = 5;
    my $myY = 18;
    &pos_printf( 1, $myY++, qq{ %${label_w}s: '%s' (%s, %s)\n}, 'HOST', ( uname() )[ 1, 4, 0 ] );
    my $user_name = getpwuid( $< ); ## "$<": プロセスの実ユーザーID
    &pos_printf( 1, $myY++, qq{ %${label_w}s: '%s', USER: '%s'\n}, 'LOGIN', getlogin(), $user_name );
    &pos_printf( 1, $myY++, qq{ %${label_w}s: '%s'\n}, 'DIR', getcwd() );
    &pos_printf( 1, $myY++, qq{ %${label_w}s: WIDTH='%d', HEIGHT='%d'\n}, 'TERM', $main::termX, $main::termY );
}

sub setup_clock_use_large_font()
{
    $main::screenY = 23;
    @main::wday = ( "Sun",
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    "Sat"
    );
    ## 6x10
    %main::font = (
        ' ' => [ q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      } ],
       q{'} => [ q{      },
                 q{  @@  },
                 q{   @  },
                 q{  @   },
                 q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      } ],
        '(' => [ q{      },
                 q{   @  },
                 q{  @   },
                 q{ @    },
                 q{ @    },
                 q{ @    },
                 q{  @   },
                 q{   @  },
                 q{      },
                 q{      } ],
        ')' => [ q{      },
                 q{  @   },
                 q{   @  },
                 q{    @ },
                 q{    @ },
                 q{    @ },
                 q{   @  },
                 q{  @   },
                 q{      },
                 q{      } ],
        ',' => [ q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{ @@   },
                 q{  @   },
                 q{ @    },
                 q{      } ],
        '-' => [ q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{ @@@  },
                 q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      } ],
        '.' => [ q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{      },
                 q{ @@   },
                 q{      },
                 q{      },
                 q{      } ],
        '/' => [ q{      },
                 q{    @ },
                 q{    @ },
                 q{   @  },
                 q{  @   },
                 q{  @   },
                 q{ @    },
                 q{ @    },
                 q{      },
                 q{      } ],
        '0' => [ q{      },
                 q{ @@@  },
                 q{@   @ },
                 q{@   @ },
                 q{@   @ },
                 q{@   @ },
                 q{@   @ },
                 q{ @@@  },
                 q{      },
                 q{      } ],
        '1' => [ q{      },
                 q{  @   },
                 q{ @@   },
                 q{  @   },
                 q{  @   },
                 q{  @   },
                 q{  @   },
                 q{ @@@  },
                 q{      },
                 q{      } ],
        '2' => [ q{      },
                 q{ @@@  },
                 q{@   @ },
                 q{    @ },
                 q{  @@  },
                 q{ @    },
                 q{@     },
                 q{@@@@@ },
                 q{      },
                 q{      } ],
        '3' => [ q{      },
                 q{ @@@  },
                 q{@   @ },
                 q{    @ },
                 q{  @@  },
                 q{    @ },
                 q{@   @ },
                 q{ @@@  },
                 q{      },
                 q{      } ],
        '4' => [ q{      },
                 q{   @  },
                 q{  @@  },
                 q{ @ @  },
                 q{ @ @  },
                 q{@  @  },
                 q{@@@@@ },
                 q{   @  },
                 q{      },
                 q{      } ],
        '5' => [ q{      },
                 q{@@@@@ },
                 q{@     },
                 q{@     },
                 q{@@@@  },
                 q{    @ },
                 q{@   @ },
                 q{ @@@  },
                 q{      },
                 q{      } ],
        '6' => [ q{      },
                 q{ @@@  },
                 q{@     },
                 q{@     },
                 q{@@@@  },
                 q{@   @ },
                 q{@   @ },
                 q{ @@@  },
                 q{      },
                 q{      } ],
        '7' => [ q{      },
                 q{@@@@@ },
                 q{@   @ },
                 q{    @ },
                 q{   @  },
                 q{   @  },
                 q{  @   },
                 q{  @   },
                 q{      },
                 q{      } ],
        '8' => [ q{      },
                 q{ @@@  },
                 q{@   @ },
                 q{@   @ },
                 q{ @@@  },
                 q{@   @ },
                 q{@   @ },
                 q{ @@@  },
                 q{      },
                 q{      } ],
        '9' => [ q{      },
                 q{ @@@  },
                 q{@   @ },
                 q{@   @ },
                 q{ @@@@ },
                 q{    @ },
                 q{    @ },
                 q{ @@@  },
                 q{      },
                 q{      } ],
        ':' => [ q{      },
                 q{      },
                 q{      },
                 q{  @   },
                 q{      },
                 q{      },
                 q{  @   },
                 q{      },
                 q{      },
                 q{      } ],
        'F' => [ q{      },
                 q{@@@@@ },
                 q{@     },
                 q{@     },
                 q{@@@@  },
                 q{@     },
                 q{@     },
                 q{@     },
                 q{      },
                 q{      } ],
        'M' => [ q{      },
                 q{@   @ },
                 q{@   @ },
                 q{@@ @@ },
                 q{@@ @@ },
                 q{@ @ @ },
                 q{@ @ @ },
                 q{@   @ },
                 q{      },
                 q{      } ],
        'S' => [ q{      },
                 q{ @@@  },
                 q{@   @ },
                 q{@     },
                 q{ @@@  },
                 q{    @ },
                 q{@   @ },
                 q{ @@@  },
                 q{      },
                 q{      } ],
        'T' => [ q{      },
                 q{@@@@@ },
                 q{  @   },
                 q{  @   },
                 q{  @   },
                 q{  @   },
                 q{  @   },
                 q{  @   },
                 q{      },
                 q{      } ],
        'W' => [ q{      },
                 q{@ @ @ },
                 q{@ @ @ },
                 q{@ @ @ },
                 q{@ @ @ },
                 q{ @ @  },
                 q{ @ @  },
                 q{ @ @  },
                 q{      },
                 q{      } ],
        'a' => [ q{      },
                 q{      },
                 q{ @@@  },
                 q{    @ },
                 q{ @@@@ },
                 q{@   @ },
                 q{@  @@ },
                 q{ @@ @ },
                 q{      },
                 q{      } ],
        'd' => [ q{      },
                 q{    @ },
                 q{    @ },
                 q{ @@ @ },
                 q{@  @@ },
                 q{@   @ },
                 q{@  @@ },
                 q{ @@ @ },
                 q{      },
                 q{      } ],
        'e' => [ q{      },
                 q{      },
                 q{      },
                 q{ @@@  },
                 q{@   @ },
                 q{@@@@@ },
                 q{@     },
                 q{ @@@  },
                 q{      },
                 q{      } ],
        'h' => [ q{      },
                 q{@     },
                 q{@     },
                 q{@ @@  },
                 q{@@  @ },
                 q{@   @ },
                 q{@   @ },
                 q{@   @ },
                 q{      },
                 q{      } ],
        'i' => [ q{      },
                 q{      },
                 q{  @   },
                 q{      },
                 q{  @   },
                 q{  @   },
                 q{  @   },
                 q{  @   },
                 q{      },
                 q{      } ],
        'n' => [ q{      },
                 q{      },
                 q{      },
                 q{@ @@  },
                 q{@@  @ },
                 q{@   @ },
                 q{@   @ },
                 q{@   @ },
                 q{      },
                 q{      } ],
        'o' => [ q{      },
                 q{      },
                 q{      },
                 q{ @@@  },
                 q{@   @ },
                 q{@   @ },
                 q{@   @ },
                 q{ @@@  },
                 q{      },
                 q{      } ],
        'r' => [ q{      },
                 q{      },
                 q{      },
                 q{ @ @@ },
                 q{ @@   },
                 q{ @    },
                 q{ @    },
                 q{ @    },
                 q{      },
                 q{      } ],
        't' => [ q{      },
                 q{      },
                 q{  @   },
                 q{@@@@@ },
                 q{  @   },
                 q{  @   },
                 q{  @   },
                 q{  @@  },
                 q{      },
                 q{      } ],
        'u' => [ q{      },
                 q{      },
                 q{      },
                 q{@   @ },
                 q{@   @ },
                 q{@   @ },
                 q{@  @@ },
                 q{ @@ @ },
                 q{      },
                 q{      } ],
    );

    &screen_clear();
}

sub sleep_until_boundary( $ )
{
    my $second = shift( @_ );
    my $now_epoch = &Time::HiRes::time();
    my $extra_time = $now_epoch - int( $now_epoch );

#    my $wait_usec = ( $second - $extra_time +0.1 ) * 1_000_000;
#    &Time::HiRes::usleep( $wait_usec );

    my $wait_sec = ( $second - $extra_time + 0.1 );
    # vec(ビットベクトル)を作成して STDIN(ファイル記述子0)をセット
    my $rin = '';
    vec( $rin, fileno( STDIN ), 1 ) = 1;
    # select(読込待ちベクトル, 書込待ち, 例外待ち, タイムアウト秒)
    my $line = '';
    my $nfound = select( my $rout = $rin, undef, undef, $wait_sec );
    if( $nfound > 0 ){
        # 入力があった場合、内容を確認
        $line = <STDIN>;
        $line =~ s/\r?\n$//o;
        my $op = lc( $line );
        if( $op eq 'n' ){
            $main::use_large_font = 0;
        }elsif( $op eq 'l' ){
            $main::use_large_font = 1;
        }elsif( &is_interval_sec( $op ) ){
            $main::interval = $op;
        }
        &update_moon_age_timing( -1 );
        &setup_clock();
    }
}

sub read_holiday()
{
    my $myholiday = "$main::apppath/$main::appname.holiday";

    return 1 if( ! -f "$myholiday" );
    return 1 if( ! -r "$myholiday" );

    open( HOLIDAY, "<$myholiday" ) || die( "$myholiday: Can not open: $!\n" );
    my $line = 0;
    while( <HOLIDAY> ){
        $line++;
        my $buff = $_;  chomp( $buff );
        $buff =~ s/#.*$//o;
        $buff =~ s/^\s*//o;
        $buff =~ s/\s*$//o;
        next if( $buff eq '' );

        if( !( $buff =~ m!^((?:19|20)[0-9]{2}[/\-\.][0-9]{1,2}[/\-\.][0-9]{1,2})$! ) ){
            die( "$myholiday: line $line: $buff: format error\n" );
        }
        my( $myY, $myM, $myD ) = split( /[\/\-\.]/, $1 );
        $myY += 0;  $myM += 0;  $myD += 0;

        if( $myM < 1 || 12 < $myM ){
            die( "$myholiday: line $line: $buff: $myM: out of range\n" );
        }

        if( $myD < 1 || 31 < $myD ){
            die( "$myholiday: line $line: $buff: $myD: out of range\n" );
        }

        $main::holiday{timelocal( 0, 0, 0, $myD, $myM-1, $myY-1900 )} = 1;
    }
    close( HOLIDAY );

    return 0;
}

sub print_cal( $ )
{
    my $epoch = shift( @_ );
    my $line_no = shift( @_ );
    my( $month, $year ) = ( localtime( $epoch ) )[ 4, 5 ];

    my $year_prev = $year;
    my $month_prev = $month - 1;
    if( $month_prev < 0 ){
        $month_prev = 11;
        $year_prev--;
    }

    my $year_next = $year;
    my $month_next = $month + 1;
    if( $month_next > 11 ){
        $month_next = 0;
        $year_next++;
    }

    &p_cal( $month_prev, $year_prev, 1     , $line_no );
    &p_cal( $month,      $year     , 1 + 22, $line_no );
    &p_cal( $month_next, $year_next, 1 + 44, $line_no );
}

#####
## 第1引数 : 出力するカレンダーの`月(0-12)'
## 第2引数 : 出力するカレンダーの`年'
## 第3引数 : カレンダーの出力位置(x)
## 第4引数 : カレンダーの出力位置(y)
sub p_cal( $$$$ )
{
    local *getFinalDay = sub( $$ ){
        my $myMonth = shift( @_ );
        my $myYear  = shift( @_ );
        $myMonth += 1;
        $myYear  += 1900;
        if( $myMonth == 1 || $myMonth == 3 || $myMonth == 5 || $myMonth == 7 ||
                $myMonth == 8 || $myMonth == 10 || $myMonth == 12 ){
            return 31;
        }elsif( $myMonth == 2 ){
            return ( &is_leap_year( $myYear ) ? 29 : 28 );
        }elsif( $myMonth==4 || $myMonth==6 || $myMonth==9 || $myMonth==11 ){
            return 30;
        }
    };

    my $myMo = shift( @_ );
    my $myYe = shift( @_ );
    my $myX  = shift( @_ );
    my $myY  = shift( @_ );

    my $lastDay = &getFinalDay( $myMo, $myYe );
    my $firstWDay = ( localtime( timelocal( 0, 0, 0, 1, $myMo, $myYe ) ) )[ 6 ];
    my( $nowDa, $nowMo, $nowYe ) = ( localtime( time() ) )[ 3, 4, 5 ];

    &pos_printf( $myX, $myY, "%12s %s", $main::month[$myMo], $myYe+1900 );
    &pos_printf( $myX, $myY+1, "Su Mo Tu We Th Fr Sa" );

    my $myDay = 0;
    my $myFlag = 0;
    for( my $i=1; $i<=6; $i++ ){
        for( my $j=0; $j<7; $j++ ){
            my $line_buff = '';
            $myFlag = 1 if( $i == 1 && $j == $firstWDay );
            if( $myFlag ){
                $myDay++;
                my $myFlagClo = 0;
                if( $nowDa==$myDay && $nowMo==$myMo && $nowYe==$myYe ){
                    $line_buff .= $CUR_COLOR;
                    $myFlagClo = 1;
                }
                my $crnIdx = timelocal( 0, 0, 0, $myDay, $myMo, $myYe );
                if( defined( $main::holiday{$crnIdx} ) ){
                    $line_buff .= $HOL_COLOR;
                    $myFlagClo = 1;
                }elsif ($j == 0){
                    $line_buff .= $SUN_COLOR;
                    $myFlagClo = 1;
                }elsif($j == 6){
                    $line_buff .= $SAT_COLOR;
                    $myFlagClo = 1;
                }
                $myFlag = 0 if( $myDay >= $lastDay );
                $line_buff .= sprintf( "%2d", $myDay );
                $line_buff .= $DEF_COLOR if( $myFlagClo );
            }else{
                $line_buff .= "  ";
            }
            &pos_printf( $myX + ( 3 * $j ), $myY + $i + 1, $line_buff );
        }
    }
    print( "\n" );
}

sub print_clock( $ )
{
    my( $now_epoch ) = @_;

    my $bCursorPosSave = 0;
    if( $main::tm_last[ C_SEC ] >= 0 ){
        $bCursorPosSave = 1;
        print( "\e[s" );    # 現在のカーソル座標（行・列）を記録する
    }

    my @tm_now = localtime( $now_epoch );

    if( $main::use_large_font == 0 ){
        my $diff_M = $tm_now[ C_MIN ] - $main::tm_last[ C_MIN ];
        if( $diff_M >= 0 && $main::tm_last[ C_MIN ] >= 0 ){
            &bar_print( $main::bar_pos_x + $main::tm_last[ C_MIN ], 13, $diff_M );
        }else{
            &bar_rewrite( $main::bar_pos_x, 13, $tm_now[ C_MIN ] );
        }
    }

    my $diff_S = $tm_now[ C_SEC ] - $main::tm_last[ C_SEC ];
    if( $diff_S > 0 && $main::tm_last[ C_SEC ] >= 0 ){
        my $sec = sprintf( "%02d", $tm_now[ C_SEC ] );
        if( $main::use_large_font == 0 ){
            &pos_printf( 24, 14, $sec );
            &bar_print( $main::bar_pos_x + $main::tm_last[ C_SEC ], 15, $diff_S );
        }else{
            &pos_print_in_large_font( ( FONT_W_LEN * 7 ) + 1, 3 + FONT_H_LEN, $sec );
        }
    }else{
        my $tm_str = &get_tm_str( @tm_now );
        if( $main::use_large_font == 0 ){
            ## 必要であれば、カレンダーを書き換える
            &print_cal( $now_epoch, 4 ) if( $main::tm_last[ C_DAY ] != $tm_now[ C_DAY ] );

            ## 日付時刻文字列を書き換える
            print( "\n" );      ## 端末ログを見易くする為改行しておく
            &pos_printf( 2, 14, $tm_str );

            &bar_rewrite( $main::bar_pos_x, 15, $tm_now[ C_SEC ] );
        }else{
            my( $Ymd, $HMS ) = split( /\n/, $tm_str );
            &pos_print_in_large_font( 1, 3, $Ymd );
            my $pos_line2 = 3 + FONT_H_LEN;
            &pos_print_in_large_font( 1, $pos_line2, $HMS );
            my $Y = $tm_now[ C_YEAR ];
            my $m = $tm_now[ C_MON ];
            ## 必要であれば、カレンダーを書き換える
            &p_cal( $m, $Y, 58, $pos_line2 + 2 ) if( $main::tm_last[ C_DAY ] != $tm_now[ C_DAY ] );
        }
    }

    my $next_moon_age_epoch = &update_moon_age_timing();
    if( $now_epoch >= $next_moon_age_epoch ){
        my $age = &age_of_moon( $now_epoch );

        if( $main::use_large_font == 0 ){
            &pos_printf( 28, 14, qq{[ Moon age: $age ]} );
        }else{
            my $pos_line2 = 3 + FONT_H_LEN;
            &pos_printf( 58, $pos_line2, qq{Moon age: $age} );
        }
    }

    &move_curs( 1, $main::screenY );
    if( $bCursorPosSave ){
        print( "\e[u" );    # 最後に保存した座標にカーソルを戻す
    }

    @main::tm_last = @tm_now;

    return;
}

sub bar_print( $$$ )
{
    my( $left, $top, $num ) = @_;
    my $bar = '#' x $num;
    &pos_printf( $left, $top, $bar );
}

sub bar_rewrite( $$$ )
{
    my( $left, $top, $num ) = @_;
    my $line_buff = ' ' x $main::screenX . "\n";
    &pos_printf( 1, $top, $line_buff );
    &bar_print( $left, $top, $num );
}

sub screen_clear()
{
    my $clear_cmd = '';
    $clear_cmd .= "\n" x $main::termY;  # 行送り
    $clear_cmd .= "\e[2J";              # 画面全体を消去
    $clear_cmd .= $DEF_COLOR;
    print( $clear_cmd );

    for( my $i=1; $i<=$main::screenY; $i++ ){
        &pos_printf( 1, $i, "\e[2K" );    # 現在行全体を削除
    }

    return 0;
}

sub cursor_pos( $$ )
{
    my( $left, $top ) = @_;
    my $ret_val = '';
    if( defined( $top ) ){
        ## \e[n;mH: 上からn、左からmの場所に移動
        $ret_val = qq{\e[${top};${left}H};
    }else{
        ## \e[mG: 左からmの場所に移動
        $ret_val = qq{\e[${left}G};
    }
}

sub move_curs( $$ )
{
    my( $left, $top ) = @_;
    print( &cursor_pos( $left, $top ) );
    return 0;
}

sub pos_printf( $$@ )
{
    my $left = shift( @_ );
    my $top  = shift( @_ );
    my @arg = @_;
    my $cur_l = &cursor_pos( $left );
    $arg[ 0 ] =~ s!\n!\n${cur_l}!go;
    $arg[ 0 ] = &cursor_pos( $left, $top ) . $arg[ 0 ];
    printf( @arg );
}

sub pos_print_in_large_font( $$$ )
{
    my $left = shift( @_ );
    my $top  = shift( @_ );
    my $str = shift( @_ );

    my $raster = &get_large_font_raster( $str );
    &pos_printf( $left, $top, $raster );
}

sub get_large_font_raster( $ )
{
    my $str = shift( @_ );
    my $len = length( $str );

    my @line = ();
    for( my $idx=0; $idx<FONT_H_LEN; $idx++ ){
        $line[ $idx ] = '';
        for( my $str_idx=0; $str_idx<$len; $str_idx++ ){
            my $c = substr( $str, $str_idx, 1 );
            $line[ $idx ] .= $main::font{ $c }[ $idx ];
        }
        #print( qq{$line[ $idx ]\n} );
    }

    return join( "\n", @line );
}

sub get_tm_str( @ )
{
    my( $S, $M, $H, $mday, $month, $year, $wday ) = @_;
    $year += 1900;
    $month += 1;

    my $ret_str = '';
    if( $main::use_large_font == 0 ){
        $ret_str = sprintf( "%04d/%02d/%02d(%s) %02d:%02d:%02d",
            $year, $month, $mday, $main::wday[ $wday ], $H, $M, $S );
    }else{
        $ret_str = sprintf( qq{'%02d-%02d-%02d %s\n %02d:%02d:%02d},
            $year-2000, $month, $mday, $main::wday[ $wday ], $H, $M, $S );
    }

    return $ret_str;
}

# 端末幅を取得するための Term::ReadKey は非コアモジュールで、
# インストール時に C コンパイラが必要となる環境もある。
# ビルド要件を増やしたくない場合にこのサブルーチンを使用するという前提。
## Revision: 1.4
sub GetTermSize()
{
    my( $width, $height ) = ( undef, undef );

    # Try stty
    if( -t STDOUT ){
        #my( $trm_columns, $trm_lines,
        #    $trm_width, $trm_height ) = &Term::ReadKey::GetTerminalSize();
        # ビルド要件を増やさない為に使用しない。

        my $stty_out = `stty size 2>/dev/null`;
        if( $stty_out =~ m/^\s*(\d+)\s+(\d+)/ ){
            $height = $1;
            $width  = $2;
        }
    }else{
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
    }

    return ( $width, $height );
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

sub age_of_moon_instant( $ )
{
    my $epoch = shift( @_ );

    my( $sec, $min, $hour, $mday, $mon, $year ) = gmtime( $epoch );
    my $y = $year + 1900;
    my $m = $mon + 1;

    # 時・分・秒を日に換算
    my $d = $mday + ( $hour / 24 ) + ( $min / 1440 ) + ( $sec / 86400 );

    # 1月、2月を前年の13月、14月として処理（ツェラーの公式等の定石）
    if( $m <= 2 ){
        $y--;
        $m += 12;
    }

    # 完全整数処理による「修正ユリウス日 (MJD)」の算出
    my $mjd = int( 365.25 * $y ) + int( $y / 400 ) - int( $y / 100 )
            + int( ( 153 * $m - 162 ) / 5 ) + $d - 678912;

    # 上記の整数日数変換に100%適合させた「新月基準点 (Epoch)」
    my $diff_days = $mjd - 51549.1;

    # 天文学における平均朔望月（月の満ち欠けの平均周期）
    my $synodic_month = 29.530588853;

    # 経過日数から現在の月齢を算出
    my $age = $diff_days / $synodic_month;
    $age = ( $age - int( $age ) ) * $synodic_month;

    # マイナス値になった場合の補正
    $age += $synodic_month if( $age < 0 );

    # コア用途のため丸めずに返す
    return $age;
}

use POSIX qw(ceil);

use constant SAKUBOU => 29.530588853;

sub age_of_moon( $ )
{
    my( $epoch ) = @_;

    my $age_raw = &age_of_moon_instant( $epoch );
    #print( qq{\$age_raw=$age_raw\n} );

    # 確実に切り捨てにする
    my $age_rounded = sprintf( '%6.3f', int( $age_raw * 1000 ) / 1000 );
    #print( qq{\$age_rounded=$age_rounded\n} );

    my $next_threshold = $age_rounded + 0.001;
    if( $next_threshold >= SAKUBOU ){
        $next_threshold = 0.001;
    }
    #print( qq{\$next_threshold=$next_threshold\n} );

    my $age_diff = $next_threshold - $age_raw;
    # もし誤差でマイナスになったら、すでに次の区間に入っているので即時更新（最低1秒）
    $age_diff = 0.00001 if( $age_diff <= 0 );
    #print( qq{\$age_diff=$age_diff\n} );

    # 月齢の 1日（＝86400秒） を 秒数 に変換
    my $seconds_to_wait = &POSIX::ceil( $age_diff * 86400 );
    &update_moon_age_timing( $seconds_to_wait + $epoch );

    return $age_rounded;
}
__END__

=pod

=encoding utf8

=head1 NAME

CL - CLOCK PROGRAM

=head1 DESCRIPTION

This is a clock script.

A clock script created to act as a Keep-Alive mechanism,
preventing TCP session timeouts during remote work.

=head2 Supports two display modes:

=over 8

=item Normal Mode:

Displays time in plain text. (default)

=item Large Font Mode (C<-l>):

Displays time in large ASCII art, similar to the C<banner> command.

=back

=head2 Interactive Commands (during execution):

=over 8

=item  C<Ctrl> + C<C>

Exit

=item C<L> + C<Enter>

Switch to Large Font Mode

=item C<N> + C<Enter>

Switch to Normal Mode

=item C<INTERVAL> + C<Enter>

Update interval in seconds (1-60)

=item C<Enter>

Refresh the display immediately

=back

=head1 SYNOPSIS

$ cl [I<OPTIONS...>] [I<ARGUMENTS>]

=head1 OPTIONS

=over 4

=item -l

Enable Large Font Mode (ASCII art).

=item -v, --version

Display script version, Perl version, and exit.

=item -h, --help

Display simple help and exit.

=back

=head1 ARGUMENTS

=over 4

=item INTERVAL

Update interval in seconds (1-60). Default is 1.

=back

=head1 DEPENDENCIES

This script uses only B<core Perl modules>. No external modules from CPAN are required.

=head2 Core Modules Used

=over 4

=item * L<constant> — first included in perl 5.004

=item * L<File::Basename> — first included in perl 5

=item * L<POSIX> — first included in perl 5

=item * L<strict> — first included in perl 5

=item * L<Time::HiRes> - first included in perl v5.7.3

=item * L<Time::Local> - first included in perl 5

=item * L<warnings> — first included in perl v5.6.0

=back

=head2 Survey methodology

=over 4

=item 1. Preparation

Define the script name:

  $ target_script=cl

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

=back

=head1 AUTHOR

2005-2026, tomyama

=head1 LICENSE

Copyright (c) 2005-2026, tomyama

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
