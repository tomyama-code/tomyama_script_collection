#!/usr/bin/env perl
use strict;
use warnings;

#use lib '.';
use FindBin;            # first released with perl 5.00307
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Tester;

my $expect_hdr_s = qr/SDT    SDT    Lat, Lon               IANA TZ id  +Country Code\n/;
my $expect_hdr_l = qr/SDT    SDT    DST    DST    Lat, Lon               IANA TZ id  +"Embedded comments"  "Notes"  Country Code  Country Name\n/;

subtest 'In-Proc Test' => sub{
    require './timezone_id';

    my $t;
    my $status;

    subtest 'BASIC-TEST' => sub{

        $t = tests::Tester->run_blk( sub{
            $status = pl_main();
        } );
        equal( $status, 0, q{./timezone_id} );
        $t->has_no_exception( '引数無しで呼び出す' );
        $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
        $t->stdout_like( qr/\n\−12:00 \-12    0, \-180                Etc\/GMT\+12                        \n/, qq{最初のレコード} );
        $t->stdout_like( qr/\n\+14:00 \+14    1\.87213, \-157\.42781    Pacific\/Kiritimati                KI\n/, qq{最後のレコード} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( 'JST' );
        } );
        equal( $status, 0, q{./timezone_id JST} );
        $t->has_no_exception( 'シンプルなフィルター' );
        $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
        $t->stdout_like( qr/\n\+09:00 JST    35\.67642, 139\.65002    Asia\/Tokyo  JP; AU\n/, qq{最初のレコード} );
        $t->stdout_like( qr/\n\+09:00 JST    34\.64938, 135\.00147    Japan       JP\n/, qq{最後のレコード} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( 'America/', 'Fr' );
        } );
        equal( $status, 0, q{./timezone_id 'America/' 'Fr'} );
        $t->has_no_exception( '複数のフィルター' );
        $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
        $t->stdout_like( qr/\n\−04:00 AST    18\.22083, \-66\.59014    America\/Puerto_Rico  PR; AG; CA; AI; AW; BL; BQ; CW; DM; GD; GP; KN; LC; MF; MS; SX; TT; VC; VG; VI\n/, qq{最初のレコード} );
        $t->stdout_like( qr/\n\−03:00 \-3     4\.93797, \-52\.33543     America\/Cayenne      GF\n/, qq{最後のレコード} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( 'France|French' );
        } );
        equal( $status, 0, q{./timezone_id 'France|French'} );
        $t->has_no_exception( 'ORフィルター' );
        $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
        $t->stdout_like( qr/\n\−10:00 \-10    \-17\.65091, \-149\.42604  Pacific\/Tahiti       PF\n/, qq{最初のレコード} );
        $t->stdout_like( qr/\n\+05:00 \+5     \-55\.19908, 76\.10015    Indian\/Kerguelen     TF\n/, qq{最後のレコード} );
        $t->stderr_is( qq{} );

    };

    subtest q{Option Switch Test} => sub{

        subtest q{Option Switch: --debug, -d} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--debug' );
            } );
            equal( $status, 0, q{./timezone_id --debug} );
            $t->has_no_exception( 'ロング形式' );
            $t->stdout_like( qr/^dbg: Parameter Print\n/, qq{デバッグ出力} );
            $t->stdout_like( qr/\n     \$main::debug = 1\n/, qq{デバッグ出力} );
            $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
            $t->stdout_like( qr/\n\−12:00 \-12    0, \-180                Etc\/GMT\+12                        \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14    1\.87213, \-157\.42781    Pacific\/Kiritimati                KI\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-d' );
            } );
            equal( $status, 0, q{./timezone_id -d} );
            $t->has_no_exception( 'ショート形式' );
            $t->stdout_like( qr/^dbg: Parameter Print\n/, qq{デバッグ出力} );
            $t->stdout_like( qr/\n     \$main::debug = 1\n/, qq{デバッグ出力} );
            $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
            $t->stdout_like( qr/\n\−12:00 \-12    0, \-180                Etc\/GMT\+12                        \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14    1\.87213, \-157\.42781    Pacific\/Kiritimati                KI\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: --verbose, -v} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--verbose' );
            } );
            equal( $status, 0, q{./timezone_id --verbose} );
            $t->has_no_exception( 'ロング形式' );
            $t->stdout_like( $expect_hdr_l, qq{ヘッダ（verbose版）} );
            $t->stdout_like( qr/\n\−12:00 \-12    \−12:00 \-12    0, \-180                Etc\/GMT\+12                        ""  "Sign is intentionally inverted\. See the Etc area description\."    \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14    \+14:00 \+14    1\.87213, \-157\.42781    Pacific\/Kiritimati                "Line Islands"  ""  KI  Kiribati\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-v' );
            } );
            equal( $status, 0, q{./timezone_id -v} );
            $t->has_no_exception( 'ショート形式' );
            $t->stdout_like( $expect_hdr_l, qq{ヘッダ（verbose版）} );
            $t->stdout_like( qr/\n\−12:00 \-12    \−12:00 \-12    0, \-180                Etc\/GMT\+12                        ""  "Sign is intentionally inverted\. See the Etc area description\."    \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14    \+14:00 \+14    1\.87213, \-157\.42781    Pacific\/Kiritimati                "Line Islands"  ""  KI  Kiribati\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: --version} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--version' );
            } );
            equal( $status, 0, q{./timezone_id --version} );
            $t->has_no_exception( 'ロング形式' );
            $t->stdout_like( qr/^Version: \d/ );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: --help, -h} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--help' );
            } );
            equal( $status, 0, q{./timezone_id --help} );
            $t->has_no_exception( 'ロング形式' );
            $t->stdout_like( qr/^usage: timezone_id \[ <OPTIONS> \] \[ <PATTERN>... \]\n/, qq{最初の行} );
            $t->stdout_like( qr/ for more information\.\n/, qq{最後の行} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-h' );
            } );
            equal( $status, 0, q{./timezone_id -h} );
            $t->has_no_exception( 'ショート形式' );
            $t->stdout_like( qr/^usage: timezone_id \[ <OPTIONS> \] \[ <PATTERN>... \]\n/, qq{最初の行} );
            $t->stdout_like( qr/ for more information\.\n/, qq{最後の行} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--help', '--verbose', 'JST' );
            } );
            equal( $status, 0, q{./timezone_id --help --verbose JST} );
            $t->has_no_exception( 'ヘルプのみを出力' );
            $t->stdout_like( qr/^usage: timezone_id \[ <OPTIONS> \] \[ <PATTERN>... \]\n/, qq{最初の行} );
            $t->stdout_like( qr/ for more information\.\n/, qq{最後の行} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: --datafile} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--datafile=Non-existent-file' );
            } );
            equal( $status, 0, q{./timezone_id --datafile=Non-existent-file} );
            $t->has_exception( 'データファイルのオープンに失敗させる' );
            $t->exception_like( qr/^Non\-existent\-file: could not open file: No such file or directory at / );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--datafile', './timezone_id.tab' );
            } );
            equal( $status, 0, q{./timezone_id --datafile ./timezone_id.tab} );
            $t->has_no_exception( 'データファイルを指定する' );
            $t->stdout_like( $expect_hdr_s, qq{ヘッダ} );
            $t->stdout_like( qr/\n\−12:00 \-12    0, \-180                Etc\/GMT\+12                        \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14    1\.87213, \-157\.42781    Pacific\/Kiritimati                KI\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

        };

        subtest q{Option Switch: composite} => sub{

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--debug', '--verbose' );
            } );
            equal( $status, 0, q{./timezone_id --debug --verbose} );
            $t->has_no_exception( 'ロング形式' );
            $t->stdout_like( qr/^dbg: Parameter Print\n/, qq{デバッグ出力} );
            $t->stdout_like( qr/\n     \$main::debug = 1\n/, qq{デバッグ出力} );
            $t->stdout_like( $expect_hdr_l, qq{ヘッダ（verbose版）} );
            $t->stdout_like( qr/\n\−12:00 \-12    \−12:00 \-12    0, \-180                Etc\/GMT\+12                        ""  "Sign is intentionally inverted\. See the Etc area description\."    \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14    \+14:00 \+14    1\.87213, \-157\.42781    Pacific\/Kiritimati                "Line Islands"  ""  KI  Kiribati\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-dv' );
            } );
            equal( $status, 0, q{./timezone_id -dv} );
            $t->has_no_exception( 'ショート形式' );
            $t->stdout_like( qr/^dbg: Parameter Print\n/, qq{デバッグ出力} );
            $t->stdout_like( qr/\n     \$main::debug = 1\n/, qq{デバッグ出力} );
            $t->stdout_like( $expect_hdr_l, qq{ヘッダ（verbose版）} );
            $t->stdout_like( qr/\n\−12:00 \-12    \−12:00 \-12    0, \-180                Etc\/GMT\+12                        ""  "Sign is intentionally inverted\. See the Etc area description\."    \n/, qq{最初のレコード} );
            $t->stdout_like( qr/\n\+14:00 \+14    \+14:00 \+14    1\.87213, \-157\.42781    Pacific\/Kiritimati                "Line Islands"  ""  KI  Kiribati\n/, qq{最後のレコード} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--non-existent-option' );
            } );
            equal( $status, 0, q{./timezone_id --non-existent-option} );
            $t->has_exception( '存在しないオプション（ロング形式）' );
            $t->exception_is( qq{parse_arg(): error: Failed to parse option switches.\n} );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{Unknown option: non-existent-option\n} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-z' );
            } );
            equal( $status, 0, q{./timezone_id -z} );
            $t->has_exception( '存在しないオプション（ショート形式）' );
            $t->exception_is( qq{parse_arg(): error: Failed to parse option switches.\n} );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{Unknown option: z\n} );

        };

    };

};

done_testing();
