#!/usr/bin/env perl
################################################################################
## - $Revision: 1.11 $
################################################################################

use strict;                         # first released with perl 5
use warnings;                       # first released with perl v5.6.0
use POSIX qw();                     # first released with perl 5

#use lib '.';
use FindBin;                        # first released with perl 5.00307
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Tester;

my $lc_ctype_def = POSIX::setlocale( POSIX::LC_CTYPE );
my $locale_is_available = 1;
$locale_is_available = 0 if( $lc_ctype_def ne 'ja_JP.UTF-8' );

my $expect_hdr_s = qr/SDT    SDT    Lat      ,  Lon        IANA TZ id  +Type       Country Code\n/;
my $expect_hdr_l = qr/SDT    SDT    DST    DST    Lat      ,  Lon        IANA TZ id  +Type       "Notes"  "Embedded comments"  "Country Code"  "Country Name"  "Countries"  ID\n/;

subtest 'In-Proc Test' => sub{
    require './timezone_id';

    my $t;
    my $status;

    subtest 'BASIC-TEST' => sub{

        $t = tests::Tester->run_blk( sub{
            $status = pl_main();
        } );
        $t->has_no_exception( q{./timezone_id} );
        is( $status, 0, '引数無しで呼び出す' );
        $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
        $t->stdout_like( qr/\n\−12:00 \-12      0      , \-180        Etc\/GMT\+12                        Canonical  \n/, qq{最初のレコード} );
        $t->stdout_like( qr/\n\+14:00 \+14     \+1\.87213, \-157\.42781  Pacific\/Kiritimati                Canonical  KI\n/, qq{最後のレコード} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( 'JST' );
        } );
        $t->has_no_exception( q{./timezone_id JST} );
        is( $status, 0, 'シンプルなフィルター' );
        $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
        $t->stdout_like( qr/\n\+09:00 JST    \+35\.67642, \+139\.65002  Asia\/Tokyo  Canonical  JP; AU\n/, qq{最初のレコード} );
        $t->stdout_like( qr/\n\+09:00 JST    \+34\.64938, \+135\.00147  Japan       Link       JP\n/, qq{最後のレコード} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( 'America/', 'Fr' );
        } );
        $t->has_no_exception( q{./timezone_id 'America/' 'Fr'} );
        is( $status, 0, '複数のフィルター' );
        $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
        $t->stdout_like( qr/\n\−04:00 AST    \+18\.22083,  \-66\.59014  America\/Puerto_Rico  Canonical  PR; AG; CA; AI; AW; BL; BQ; CW; DM; GD; GP; KN; LC; MF; MS; SX; TT; VC; VG; VI\n/, qq{最初のレコード} );
        $t->stdout_like( qr/\n\−03:00 \-3      \+4\.93797,  \-52\.33543  America\/Cayenne      Canonical  GF\n/, qq{最後のレコード} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( 'France|French' );
        } );
        $t->has_no_exception( q{./timezone_id 'France|French'} );
        is( $status, 0, 'ORフィルター' );
        $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
        $t->stdout_like( qr/\n\−10:00 \-10    \-17\.65091, \-149\.42604  Pacific\/Tahiti       Canonical  PF\n/, qq{最初のレコード} );
        $t->stdout_like( qr/\n\+05:00 \+5     \-55\.19908,  \+76\.10015  Indian\/Kerguelen     Link       TF\n/, qq{最後のレコード} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( 'パリ|ダカール' );
        } );
        $t->has_no_exception( q{./timezone_id 'パリ|ダカール'} );
        is( $status, 0, '日本語でフィルター（OR検索）' );
        $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
        $t->stdout_like( qr/\n\+00:00 GMT    \+14\.71667,  \-17\.46768  Africa\/Dakar  Link       SN\n/, qq{最初のレコード} );
        $t->stdout_like( qr/\n\+01:00 CET    \+48\.85754,   \+2\.35137  Europe\/Paris  Canonical  FR; MC\n/, qq{最後のレコード} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( '基地', 'AQ', '南極', 'Antarctica/' );
        } );
        $t->has_no_exception( q{./timezone_id 基地 AQ 南極 Antarctica/} );
        is( $status, 0, '日本語でフィルター（AND検索）' );
        $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
        $t->stdout_like( qr/\n\−03:00 \-3     \-64\.77425,  \-64\.05382  Antarctica\/Palmer          Canonical  AQ\n/, qq{最初のレコード} );
        $t->stdout_like( qr/\n\+12:00 NZST   \-77\.84551, \+166\.66976  Antarctica\/McMurdo         Link       AQ\n/, qq{最後のレコード} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( 'A[Q]', '南.大陸/' );
        } );
        $t->has_no_exception( q{./timezone_id 'A[Q]' '南.大陸/'} );
        is( $status, 0, '日本語の文字境界を認識できていること（1文字マッチ）' );
        $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
        $t->stdout_like( qr/\n\−03:00 \-3     \-64\.77425,  \-64\.05382  Antarctica\/Palmer          Canonical  AQ\n/, qq{最初のレコード} );
        $t->stdout_like( qr/\n\+12:00 NZST   \-77\.84551, \+166\.66976  Antarctica\/McMurdo         Link       AQ\n/, qq{最後のレコード} );
        $t->stderr_is( qq{} );

    };

    subtest q{Option Switch Test} => sub{

        subtest q{Option Switch: --banner, -b} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--banner' );
            } );
            $t->has_no_exception( q{./timezone_id --banner} );
            is( $status, 0, 'ロング形式' );
            $t->stdout_like( qr/^--------------------------------------------------\n/, q{バナー表示} );
            $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
            $t->stdout_like( qr/\n\−12:00 \-12      0      , \-180        Etc\/GMT\+12                        Canonical  \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14     \+1\.87213, \-157\.42781  Pacific\/Kiritimati                Canonical  KI\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-b' );
            } );
            $t->has_no_exception( q{./timezone_id -b} );
            is( $status, 0, 'ショート形式' );
            $t->stdout_like( qr/^--------------------------------------------------\n/, q{バナー表示} );
            $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
            $t->stdout_like( qr/\n\−12:00 \-12      0      , \-180        Etc\/GMT\+12                        Canonical  \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14     \+1\.87213, \-157\.42781  Pacific\/Kiritimati                Canonical  KI\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: --datafile} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--datafile=Non-existent-file' );
            } );
            $t->has_exception( q{./timezone_id --datafile=Non-existent-file} );
            $t->exception_like( qr/^Non\-existent\-file: could not open file: No such file or directory at /, 'データファイルのオープンに失敗させる' );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--datafile', './timezone_id.tab' );
            } );
            $t->has_no_exception( q{./timezone_id --datafile ./timezone_id.tab} );
            is( $status, 0, 'データファイルを指定する' );
            $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
            $t->stdout_like( qr/\n\−12:00 \-12      0      , \-180        Etc\/GMT\+12                        Canonical  \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14     \+1\.87213, \-157\.42781  Pacific\/Kiritimati                Canonical  KI\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: --datafile-loc} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--datafile-loc=Non-existent-file' );
            } );
            $t->has_exception( q{./timezone_id --datafile-loc=Non-existent-file} );
            $t->exception_like( qr/^Non\-existent\-file: could not open file: No such file or directory at /, 'データファイルのオープンに失敗させる' );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: --debug, -d} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--debug' );
            } );
            $t->has_no_exception( q{./timezone_id --debug} );
            is( $status, 0, 'ロング形式' );
            $t->stdout_like( qr/^dbg: Parameter Print\n/, qq{デバッグ出力} );
            $t->stdout_like( qr/\n     \$main::debug = 1\n/, qq{デバッグ出力} );
            $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
            $t->stdout_like( qr/\n\−12:00 \-12      0      , \-180        Etc\/GMT\+12                        Canonical  \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14     \+1\.87213, \-157\.42781  Pacific\/Kiritimati                Canonical  KI\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-d' );
            } );
            $t->has_no_exception( q{./timezone_id -d} );
            is( $status, 0, 'ショート形式' );
            $t->stdout_like( qr/^dbg: Parameter Print\n/, qq{デバッグ出力} );
            $t->stdout_like( qr/\n     \$main::debug = 1\n/, qq{デバッグ出力} );
            $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
            $t->stdout_like( qr/\n\−12:00 \-12      0      , \-180        Etc\/GMT\+12                        Canonical  \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14     \+1\.87213, \-157\.42781  Pacific\/Kiritimati                Canonical  KI\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: --help, -h} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--help' );
            } );
            $t->has_no_exception( q{./timezone_id --help} );
            is( $status, 0, 'ロング形式' );
            $t->stdout_like( qr/^usage: timezone_id \[ <OPTIONS> \] \[ <PATTERN>... \]\n/, qq{最初の行} );
            $t->stdout_like( qr/ for more information\.\n/, qq{最後の行} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-h' );
            } );
            $t->has_no_exception( q{./timezone_id -h} );
            is( $status, 0, 'ショート形式' );
            $t->stdout_like( qr/^usage: timezone_id \[ <OPTIONS> \] \[ <PATTERN>... \]\n/, qq{最初の行} );
            $t->stdout_like( qr/ for more information\.\n/, qq{最後の行} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--help', '--verbose', 'JST' );
            } );
            $t->has_no_exception( q{./timezone_id --help --verbose JST} );
            is( $status, 0, 'ヘルプのみを出力' );
            $t->stdout_like( qr/^usage: timezone_id \[ <OPTIONS> \] \[ <PATTERN>... \]\n/, qq{最初の行} );
            $t->stdout_like( qr/ for more information\.\n/, qq{最後の行} );
            $t->stdout_unlike( $expect_hdr_s, qq{ID は出力されないこと} );
            $t->stdout_unlike( $expect_hdr_l, qq{ID は出力されないこと} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: --ignorecase, -i} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( 'jst', '--ignorecase' );
            } );
            $t->has_no_exception( q{./timezone_id jst --ignorecase} );
            is( $status, 0, 'ロング形式' );
            $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
            $t->stdout_like( qr/\n\+09:00 JST    \+35\.67642, \+139\.65002  Asia\/Tokyo  Canonical  JP; AU\n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+09:00 JST    \+34\.64938, \+135\.00147  Japan       Link       JP\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( 'jst', '-i' );
            } );
            $t->has_no_exception( q{./timezone_id jst -i} );
            is( $status, 0, 'ショート形式' );
            $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
            $t->stdout_like( qr/\n\+09:00 JST    \+35\.67642, \+139\.65002  Asia\/Tokyo  Canonical  JP; AU\n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+09:00 JST    \+34\.64938, \+135\.00147  Japan       Link       JP\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( 'jst' );
            } );
            $t->has_no_exception( q{./timezone_id jst} );
            is( $status, 0, 'jst は見つからない' );
            $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
            $t->stdout_unlike( qr/\n\+09:00 JST    \+35\.67642, \+139\.65002  Asia\/Tokyo  Canonical  JP; AU\n/, qq{最初のレコード} );
            $t->stdout_unlike( qr/\n\+09:00 JST    \+34\.64938, \+135\.00147  Japan       Link       JP\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: --set-locale} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--set-locale', 'en_US.utf9' );
            } );
            $t->has_exception( q{./timezone_id --set-locale en_US.utf9} );
            $t->exception_is( qq{set_locale(): error: specified_value="en_US.utf9": LC_CTYPE="$lc_ctype_def": failure.\n}, 'set_locale() が例外' );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( 'JST', '--set-locale', '', '--debug' );
            } );
            $t->has_no_exception( q{./timezone_id JST --set-locale '' --debug} );
            is( $status, 0, 'LC_CTYPE がシステムデフォルトに変わること' );
            $t->stdout_like( qr/\n     \$main::datafile_loc = "\.\/timezone_id\.tab\.C"\n/, qq{\$main::datafile_loc} );
            $t->stdout_like( qr/\n     \$main::LC_CTYPE = "C"\n/, qq{\$main::LC_CTYPE} );
            $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
            $t->stdout_like( qr/\n\+09:00 JST    \+35\.67642, \+139\.65002  Asia\/Tokyo  Canonical  JP; AU\n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+09:00 JST    \+34\.64938, \+135\.00147  Japan       Link       JP\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );
            # LANG を戻しておく
            $ENV{LANG} = $lc_ctype_def if( !defined( $ENV{LANG} ) );

            if( $locale_is_available ){

                # LANG を消しておく
                delete( $ENV{LANG} ) if( defined( $ENV{LANG} ) );

                $t = tests::Tester->run_blk( sub{
                    $status = pl_main( 'JST', '--set-locale', 'C.UTF-8', '--debug' );
                } );
                $t->has_no_exception( q{./timezone_id JST --set-locale C.UTF-8 --debug} );
                is( $status, 0, 'LC_CTYPE が指定した値に変わること' );
                $t->stdout_like( qr/\n     \$main::datafile_loc = "\.\/timezone_id\.tab\.C"\n/, qq{\$main::datafile_loc} );
                $t->stdout_like( qr/\n     \$main::LC_CTYPE = "C\.UTF-8"\n/, qq{\$main::LC_CTYPE} );
                $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
                $t->stdout_like( qr/\n\+09:00 JST    \+35\.67642, \+139\.65002  Asia\/Tokyo  Canonical  JP; AU\n/, qq{最初のレコード} );
                $t->stdout_like( qr/\n\+09:00 JST    \+34\.64938, \+135\.00147  Japan       Link       JP\n/, qq{最後のレコード} );
                $t->stderr_is( qq{} );

                # LANG を戻しておく
                $ENV{LANG} = $lc_ctype_def if( !defined( $ENV{LANG} ) );

                $t = tests::Tester->run_blk( sub{
                    $status = pl_main( 'JST', '--set-locale', 'C.UTF-8', '--debug' );
                } );
                $t->has_no_exception( q{./timezone_id JST --set-locale C.UTF-8 --debug} );
                is( $status, 0, 'Android Termux 環境用の救済コードが効くこと（ LANGを参照 ）' );
                $t->stdout_like( qr/\n     \$main::datafile_loc = "\.\/timezone_id\.tab\.ja_JP"\n/, qq{\$main::datafile_loc} );
                $t->stdout_like( qr/\n     \$main::LC_CTYPE = "ja_JP\.UTF-8"\n/, qq{\$main::LC_CTYPE} );
                $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
                $t->stdout_like( qr/\n\+09:00 JST    \+35\.67642, \+139\.65002  Asia\/Tokyo  Canonical  JP; AU\n/, qq{最初のレコード} );
                $t->stdout_like( qr/\n\+09:00 JST    \+34\.64938, \+135\.00147  Japan       Link       JP\n/, qq{最後のレコード} );
                $t->stderr_is( qq{} );

                # 初期値に戻しておく ( $lc_ctype_def = 'ja_JP.UTF-8' )
                $t = tests::Tester->run_blk( sub{
                    $status = pl_main( 'JST', '--set-locale', 'ja_JP.UTF-8', '--debug' );
                } );
                $t->has_no_exception( q{./timezone_id JST --set-locale ja_JP.UTF-8 --debug} );
                is( $status, 0, 'LC_CTYPE が指定した値に変わること' );
                $t->stdout_like( qr/\n     \$main::datafile_loc = "\.\/timezone_id\.tab\.ja_JP"\n/, qq{\$main::datafile_loc} );
                $t->stdout_like( qr/\n     \$main::LC_CTYPE = "ja_JP\.UTF-8"\n/, qq{\$main::LC_CTYPE} );
                $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
                $t->stdout_like( qr/\n\+09:00 JST    \+35\.67642, \+139\.65002  Asia\/Tokyo  Canonical  JP; AU\n/, qq{最初のレコード} );
                $t->stdout_like( qr/\n\+09:00 JST    \+34\.64938, \+135\.00147  Japan       Link       JP\n/, qq{最後のレコード} );
                $t->stderr_is( qq{} );

            }

        };

        subtest q{Option Switch: --sort-order-by} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( 'Antarctica/', 'Link' );
            } );
            $t->has_no_exception( q{./timezone_id 'Antarctica/' 'Link'} );
            is( $status, 0, '並べ替え無し' );
            $t->stdout_is( qq{} .
                           qq{SDT    SDT    Lat      ,  Lon        IANA TZ id                 Type       Country Code\n} .
                           qq{+03:00 +3     -69.00439,  +39.5822   Antarctica/Syowa           Link       AQ\n} .
                           qq{+10:00 +10    -66.66359, +140.00325  Antarctica/DumontDUrville  Link       AQ\n} .
                           qq{+12:00 NZST   -77.84551, +166.66976  Antarctica/McMurdo         Link       AQ\n} .
                           qq{+12:00 NZST   -90      ,    0        Antarctica/South_Pole      Link       AQ\n} .
                           qq{}, qq{並べ替えない（デフォルトでは時差のオフセット順）} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( 'Antarctica/', 'Link', '--sort-order-by' );
            } );
            $t->has_exception( q{./timezone_id 'Antarctica/' 'Link' --sort-order-by} );
            $t->exception_is( qq{parse_arg(): error: Failed to parse option switches.\n}, 'スクリプトが投げる例外' );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{Option sort-order-by requires an argument\n}, 'Getopt::Long のエラー出力' );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--sort-order-by', 'Antarctica/', 'Link' );
            } );
            $t->has_exception( q{./timezone_id --sort-order-by 'Antarctica/' 'Link'} );
            $t->exception_is( qq{timezone_id: --sort-order-by "Antarctica/": Unsupported field name.\n}, 'スクリプトが投げる例外' );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--sort-order-by', 'Lat', 'Antarctica/', 'Link' );
            } );
            $t->has_no_exception( q{./timezone_id --sort-order-by 'Lat' 'Antarctica/' 'Link'} );
            is( $status, 0, '並べ替え' );
            $t->stdout_is( qq{} .
                           qq{SDT    SDT    Lat      ,  Lon        IANA TZ id                 Type       Country Code\n} .
                           qq{+12:00 NZST   -90      ,    0        Antarctica/South_Pole      Link       AQ\n} .
                           qq{+12:00 NZST   -77.84551, +166.66976  Antarctica/McMurdo         Link       AQ\n} .
                           qq{+03:00 +3     -69.00439,  +39.5822   Antarctica/Syowa           Link       AQ\n} .
                           qq{+10:00 +10    -66.66359, +140.00325  Antarctica/DumontDUrville  Link       AQ\n} .
                           qq{}, qq{緯度フィールドで並べ替えられていること} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--sort-order-by', 'Lon', 'Antarctica/', 'Link' );
            } );
            $t->has_no_exception( q{./timezone_id --sort-order-by 'Lon' 'Antarctica/' 'Link'} );
            is( $status, 0, '並べ替え' );
            $t->stdout_is( qq{} .
                           qq{SDT    SDT    Lat      ,  Lon        IANA TZ id                 Type       Country Code\n} .
                           qq{+12:00 NZST   -90      ,    0        Antarctica/South_Pole      Link       AQ\n} .
                           qq{+03:00 +3     -69.00439,  +39.5822   Antarctica/Syowa           Link       AQ\n} .
                           qq{+10:00 +10    -66.66359, +140.00325  Antarctica/DumontDUrville  Link       AQ\n} .
                           qq{+12:00 NZST   -77.84551, +166.66976  Antarctica/McMurdo         Link       AQ\n} .
                           qq{}, qq{経度フィールドで並べ替えられていること} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--sort-order-by', 'ID', 'Antarctica/', 'Link' );
            } );
            $t->has_no_exception( q{./timezone_id --sort-order-by 'ID' 'Antarctica/' 'Link'} );
            is( $status, 0, '並べ替え' );
            $t->stdout_is( qq{} .
                           qq{SDT    SDT    Lat      ,  Lon        IANA TZ id                 Type       Country Code\n} .
                           qq{+10:00 +10    -66.66359, +140.00325  Antarctica/DumontDUrville  Link       AQ\n} .
                           qq{+12:00 NZST   -77.84551, +166.66976  Antarctica/McMurdo         Link       AQ\n} .
                           qq{+12:00 NZST   -90      ,    0        Antarctica/South_Pole      Link       AQ\n} .
                           qq{+03:00 +3     -69.00439,  +39.5822   Antarctica/Syowa           Link       AQ\n} .
                           qq{}, qq{IDフィールドで並べ替えられていること} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: --verbose, -v} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--verbose' );
            } );
            $t->has_no_exception( q{./timezone_id --verbose} );
            is( $status, 0, 'ロング形式' );
            $t->stdout_like( $expect_hdr_l, qq{ヘッダ（verbose版）} );
            $t->stdout_like( qr/\n\−12:00 \-12    \−12:00 \-12      0      , \-180        Etc\/GMT\+12                        Canonical  "Sign is intentionally inverted\. See the Etc area description\."  ""  ""  ""  ""  \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14    \+14:00 \+14     \+1\.87213, \-157\.42781  Pacific\/Kiritimati                Canonical  ""  "Line Islands"  "KI"  "Kiribati"  "キリバス"  太平洋\/ライン諸島 キリスィマスィ島\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-v' );
            } );
            $t->has_no_exception( q{./timezone_id -v} );
            is( $status, 0, 'ショート形式' );
            $t->stdout_like( $expect_hdr_l, qq{ヘッダ（verbose版）} );
            $t->stdout_like( qr/\n\−12:00 \-12    \−12:00 \-12      0      , \-180        Etc\/GMT\+12                        Canonical  "Sign is intentionally inverted\. See the Etc area description\."  ""  ""  ""  ""  \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14    \+14:00 \+14     \+1\.87213, \-157\.42781  Pacific\/Kiritimati                Canonical  ""  "Line Islands"  "KI"  "Kiribati"  "キリバス"  太平洋\/ライン諸島 キリスィマスィ島\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: --version} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--version' );
            } );
            $t->has_no_exception( q{./timezone_id --version} );
            is( $status, 0, 'ロング形式' );
            $t->stdout_like( qr/^Version: \d/ );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--version', 'JST' );
            } );
            $t->has_no_exception( q{./timezone_id --version JST} );
            is( $status, 0, 'バージョンのみを出力' );
            $t->stdout_like( qr/^Version: \d/ );
            $t->stdout_unlike( $expect_hdr_s, qq{ID は出力されないこと} );
            $t->stdout_unlike( $expect_hdr_l, qq{ID は出力されないこと} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: composite} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--debug', '--verbose' );
            } );
            $t->has_no_exception( q{./timezone_id --debug --verbose} );
            is( $status, 0, 'ロング形式' );
            $t->stdout_like( qr/^dbg: Parameter Print\n/, qq{デバッグ出力} );
            $t->stdout_like( qr/\n     \$main::debug = 1\n/, qq{デバッグ出力} );
            $t->stdout_like( $expect_hdr_l, qq{ヘッダ（verbose版）} );
            $t->stdout_like( qr/\n\−12:00 \-12    \−12:00 \-12      0      , \-180        Etc\/GMT\+12                        Canonical  "Sign is intentionally inverted\. See the Etc area description\."  ""  ""  ""  ""  \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14    \+14:00 \+14     \+1\.87213, \-157\.42781  Pacific\/Kiritimati                Canonical  ""  "Line Islands"  "KI"  "Kiribati"  "キリバス"  太平洋\/ライン諸島 キリスィマスィ島\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-dv' );
            } );
            $t->has_no_exception( q{./timezone_id -dv} );
            is( $status, 0, 'ショート形式' );
            $t->stdout_like( qr/^dbg: Parameter Print\n/, qq{デバッグ出力} );
            $t->stdout_like( qr/\n     \$main::debug = 1\n/, qq{デバッグ出力} );
            $t->stdout_like( $expect_hdr_l, qq{ヘッダ（verbose版）} );
            $t->stdout_like( qr/\n\−12:00 \-12    \−12:00 \-12      0      , \-180        Etc\/GMT\+12                        Canonical  "Sign is intentionally inverted\. See the Etc area description\."  ""  ""  ""  ""  \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14    \+14:00 \+14     \+1\.87213, \-157\.42781  Pacific\/Kiritimati                Canonical  ""  "Line Islands"  "KI"  "Kiribati"  "キリバス"  太平洋\/ライン諸島 キリスィマスィ島\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--non-existent-option' );
            } );
            $t->has_exception( q{./timezone_id --non-existent-option} );
            $t->exception_is( qq{parse_arg(): error: Failed to parse option switches.\n}, '存在しないオプション（ロング形式）' );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{Unknown option: non-existent-option\n} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-z' );
            } );
            $t->has_exception( q{./timezone_id -z} );
            $t->exception_is( qq{parse_arg(): error: Failed to parse option switches.\n}, '存在しないオプション（ショート形式）' );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{Unknown option: z\n} );

        };

    };

};

done_testing();
