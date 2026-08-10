#!/usr/bin/env perl
################################################################################
## - $Revision: 1.4 $
################################################################################

use strict;
use warnings;

#use lib '.';
use FindBin;            # first released with perl 5.00307
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Tester;

my $TFILE = "./tests/address.tab";              # shell: TFILE="./tests/address.tab"
my $TF_FAKE_IP = "./tests/addr_fake_ip.txt";    # shell: TF_FAKE_IP="./tests/addr_fake_ip.txt"

subtest qq{In-Proc Test} => sub{

    require './domsort';

    subtest qq{Error path} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( 'NON-EXISTENT-FILES' );
        } );
        $t->has_exception( qq{./domsort "NON-EXISTENT-FILES} );
        $t->exception_like( qr/^domsort: NON-EXISTENT-FILES: cannot open file: /, q{Open Error} );
        $t->stdout_is( qq{} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( "$TFILE", '-k' );
        } );
        $t->has_exception( qq{./domsort "$TFILE" -k} );
        $t->exception_is( qq{Usage: domsort -k <column> <file...>\n} );
        $t->stdout_is( qq{} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-k', "$TFILE" );
        } );
        $t->has_exception( qq{./domsort -k "$TFILE"} );
        $t->exception_is( qq{"./tests/address.tab" is not a number.\n} );
        $t->stdout_is( qq{} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( "$TFILE", '-t' );
        } );
        $t->has_exception( qq{./domsort "$TFILE" -t} );
        $t->exception_is( qq{Usage: domsort -t <delimiter> <file...>\n} );
        $t->stdout_is( qq{} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( "$TFILE", '-k', '6' );
        } );
        $t->has_exception( qq{./domsort "$TFILE" -k 6} );
        $t->exception_is( qq{"1	12.34.56.90	w.x.y.z.co.jp	user1\@w.x.y.z.co.jp	03-1234-5678": There is no data in the 6 column.\n}, qq{Field specification is out of range} );
        $t->stdout_is( qq{} );
        $t->stderr_is( qq{} );

    };

    subtest qq{Normal} => sub{
        my $t;
        my $status;
        my $stdout = '';

        # $ ./domsort "./tests/address.tab"
        # 1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
        # 10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
        # 2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
        # 3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
        # 4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
        # 5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
        # 6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
        # 7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
        # 8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
        # 9   12.34.55.9   abc.com           user9@abc.com  044-1234-765
        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort "$TFILE"} );
        ok( $status == 0 );
        # 結果を直接編集する方式
        $t->{stdout} =~ s!^(\S+)\t.*$!$1!mgo;   # 第1フィールドだけ残す
        $t->stdout_is( qq{1\n10\n2\n3\n4\n5\n6\n7\n8\n9\n}, "Sort by number" );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-r', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -r "$TFILE"} );
        ok( $status == 0 );
        # 評価用の変数を用意する方式
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{9\n8\n7\n6\n5\n4\n3\n2\n10\n1\n}, "Sort by number (reverse order)" );
        $t->stderr_is( qq{} );

        # $ ./domsort -k 2 "$TFILE"
        # 10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
        # 6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
        # 5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
        # 4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
        # 9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
        # 8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
        # 7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
        # 3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
        # 2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
        # 1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-k', '2', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -k 2 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{10\n6\n5\n4\n9\n8\n7\n3\n2\n1\n}, "Sort by IP Address" );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-rk', '2', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -rk 2 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{1\n2\n3\n7\n8\n9\n4\n5\n6\n10\n}, "Sort by IP Address (reverse order)" );
        $t->stderr_is( qq{} );

        # $ ./domsort -k 3 "$TFILE"
        # 9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
        # 7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
        # 10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
        # 8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
        # 5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
        # 3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
        # 4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
        # 6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
        # 1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
        # 2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-k', '3', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -k 3 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{9\n7\n10\n8\n5\n3\n4\n6\n1\n2\n}, "Sort by Domain Name" );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-rk', '3', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -rk 3 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{2\n1\n6\n4\n3\n5\n8\n10\n7\n9\n}, "Sort by Domain Name (reverse order)" );
        $t->stderr_is( qq{} );

        # $ ./domsort -k 4 "$TFILE"
        # 9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
        # 7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
        # 10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
        # 8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
        # 5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
        # 3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
        # 4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
        # 6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
        # 1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
        # 2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-k', '4', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -k 4 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{9\n7\n10\n8\n5\n3\n4\n6\n1\n2\n}, "Sort by Mail Address" );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-rk', '4', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -rk 4 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{2\n1\n6\n4\n3\n5\n8\n10\n7\n9\n}, "Sort by Mail Address (reverse order)" );
        $t->stderr_is( qq{} );

        # $ ./domsort -k 5 "$TFILE"
        # 4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
        # 1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
        # 7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
        # 3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
        # 10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
        # 8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
        # 5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
        # 2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
        # 9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
        # 6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-k', '5', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -k 5 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{4\n1\n7\n3\n10\n8\n5\n2\n9\n6\n}, "Sort by phone number" );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-rk', '5', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -rk 5 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{6\n9\n2\n5\n8\n10\n3\n7\n1\n4\n}, "Sort by phone number (reverse order)" );
        $t->stderr_is( qq{} );

        #$ ./domsort -dk 5 "$TFILE"
        #4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
        #1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
        #7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
        #5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
        #3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
        #2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
        #9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
        #10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
        #8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
        #6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-dk', '5', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -dk 5 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{4\n1\n7\n5\n3\n2\n9\n10\n8\n6\n}, "Sort by phone number ( with -d option )" );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-drk', '5', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -drk 5 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{6\n8\n10\n9\n2\n3\n5\n7\n1\n4\n}, "Sort by phone number (reverse order) ( with -d option )" );
        $t->stderr_is( qq{} );

    };

    subtest qq{-f  Force case sensitivity.} => sub{
        my $t;
        my $status;
        my $stdout = '';

        # $ ./domsort -fk 3 "$TFILE"
        # 7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
        # 10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
        # 3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
        # 6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
        # 2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
        # 5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
        # 9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
        # 8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
        # 4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
        # 1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-fk', '3', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -fk 3 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{7\n10\n3\n6\n2\n5\n9\n8\n4\n1\n}, "Case-sensitive sorting by domain name" );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-rfk', '3', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -rfk 3 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{1\n4\n8\n9\n5\n2\n6\n3\n10\n7\n}, "Case-sensitive sorting by domain name (reverse order)" );
        $t->stderr_is( qq{} );

        # $ ./domsort -fk 4 "$TFILE"
        # 7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
        # 10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
        # 3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
        # 6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
        # 2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
        # 5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
        # 9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
        # 8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
        # 4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
        # 1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-fk', '4', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -fk 4 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{7\n10\n3\n6\n2\n5\n9\n8\n4\n1\n}, "Case-sensitive sorting by mail address" );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-rfk', '4', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -rfk 4 "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{1\n4\n8\n9\n5\n2\n6\n3\n10\n7\n}, "Case-sensitive sorting by mail address (reverse order)" );
        $t->stderr_is( qq{} );

        # $ ./domsort "$TF_FAKE_IP"
        # 1.2.256.4
        # 1.2.3.256
        # 1.256.3.4
        # 256.2.3.4
        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( "$TF_FAKE_IP" );
        } );
        $t->has_no_exception( qq{./domsort "$TF_FAKE_IP"} );
        ok( $status == 0 );
        $t->stdout_is( qq{1.2.256.4\n1.2.3.256\n1.256.3.4\n256.2.3.4\n} );
        $t->stderr_is( qq{} );

    };

    subtest qq{-t <SEP>} => sub{
        my $t;
        my $status;
        my $stdout = '';

        # $ ./domsort -t "\t" "./tests/address.tab"
        # 1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
        # 10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
        # 2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
        # 3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
        # 4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
        # 5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
        # 6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
        # 7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
        # 8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
        # 9   12.34.55.9   abc.com           user9@abc.com  044-1234-765
        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-t', '\t', "$TFILE" );
        } );
        $t->has_no_exception( qq{./domsort -t "\t" "$TFILE"} );
        ok( $status == 0 );
        $stdout = $t->get_stdout();
        $stdout =~ s!^(\S+)\t.*$!$1!mgo;    # 第1フィールドだけ残す
        equal( $stdout, qq{1\n10\n2\n3\n4\n5\n6\n7\n8\n9\n}, "Sort by number" );
        $t->stderr_is( qq{} );

    };

    subtest qq{-h, --help} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-h' );
        } );
        $t->has_no_exception( qq{./domsort -h} );
        ok( $status == 0 );
        $t->stdout_like( qr/^Usage: domsort / );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '--help' );
        } );
        $t->has_no_exception( qq{./domsort --help} );
        ok( $status == 0 );
        $t->stdout_like( qr/^Usage: domsort / );
        $t->stderr_is( qq{} );

    };

    subtest qq{-v, --version} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-v' );
        } );
        $t->has_no_exception( qq{./domsort -v} );
        ok( $status == 0 );
        $t->stdout_like( qr/^Version: \d/ );
        $t->stdout_like( qr/\n   Perl: v\d/ );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '--version' );
        } );
        $t->has_no_exception( qq{./domsort --version} );
        ok( $status == 0 );
        $t->stdout_like( qr/^Version: \d/ );
        $t->stdout_like( qr/\n   Perl: v\d/ );
        $t->stderr_is( qq{} );

    };

};
#done_testing();
#exit( 0 );

subtest qq{Input data from STDIN} => sub{
    my $t;

    #$ cat "$TFILE" | ./domsort -k 3
    #9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
    #7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
    #10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
    #8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
    #5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
    #3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
    #4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
    #6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
    #1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
    #2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
    $t = tests::Tester->run_cmd( qq{cat "$TFILE" | ./domsort -k 3 | awk '{print(\$1)}'} );
    $t->exit_is( 0, qq{cat "$TFILE" | ./domsort -k 3 | awk '{print(\$1)}'} );
    $t->stdout_is( qq{9\n7\n10\n8\n5\n3\n4\n6\n1\n2\n}, "Sort by Domain Name" );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

};

done_testing();
