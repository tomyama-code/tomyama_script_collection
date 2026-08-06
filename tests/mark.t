#!/usr/bin/env perl
################################################################################
## - $Revision: 1.2 $
################################################################################

use strict;
use warnings;

#use lib '.';
use FindBin;            # first released with perl 5.00307
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Tester;

my %phrase = &tests::Tester::get_phrase();
my $apppath = $phrase{apppath};
my $proj_root = $phrase{proj_root};

subtest qq{In-Proc Test} => sub{

    require './mark';

    subtest qq{"Usage" test} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main();
        } );
        $t->has_no_exception( qq{./mark} );
        ok( $status != 0 );
        $t->stdout_is( qq{} );
        $t->stderr_like( qr/mark: error: Please specify the Regular Expressions./, qq{Usage explanation} );
        $t->stderr_like( qr/\nUsage: mark /, qq{Usage explanation} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '--help' );
        } );
        $t->has_no_exception( qq{./mark --help} );
        ok( $status == 0 );
        $t->stdout_like( qr/^Usage: mark /, qq{Usage explanation} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '--help', '123' );
        } );
        $t->has_no_exception( qq{./mark --help 123} );
        ok( $status == 0 );
        $t->stdout_like( qr/^Usage: mark /, qq{Usage explanation} );
        $t->stdout_unlike( qr/123/, qq{Arguments are ignored when displaying "help".} );
        $t->stderr_is( qq{} );

    };

    subtest qq{<FILE> Test} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( 'mark', "$proj_root/mark" );
        } );
        $t->has_no_exception( qq{./mark mark $proj_root/mark} );
        ok( $status == 0 );
        $t->stdout_like( qr/^#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
        $t->stdout_like( qr/=cut$/, qq{Display to the end} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '^#!/usr', "$proj_root/mark" );
        } );
        $t->has_no_exception( qq{./mark '^#!/usr' $proj_root/mark} );
        ok( $status == 0 );
        $t->stdout_like( qr/^#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
        $t->stdout_like( qr/=cut$/, qq{Display to the end} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( 'c', "$proj_root/mark", "$proj_root/mark" );
        } );
        $t->has_no_exception( qq{./mark c $proj_root/mark $proj_root/mark} );
        ok( $status == 0, "Allows duplicates of existing files." );
        $t->stdout_like( qr/#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
        $t->stdout_like( qr/=cut$/, qq{Display to the end} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( 'c', "NON-EXISTENT-FILE" );
        } );
        $t->has_no_exception( qq{./mark c NON-EXISTENT-FILE} );
        ok( $status != 0, "Non-existent files." );
        $t->stdout_is( qq{} );
        $t->stderr_like( qr/mark: error: "NON-EXISTENT-FILE": file not found.\n/, qq{Correct error message.} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( 'c', "A_FICTITIOUS_UNREADABLE_FILE_FOR_TESTING_PURPOSES" );
        } );
        $t->has_no_exception( qq{./mark c A_FICTITIOUS_UNREADABLE_FILE_FOR_TESTING_PURPOSES} );
        ok( $status != 0, "Files without read permission." );
        $t->stdout_is( qq{} );
        $t->stderr_like( qr/mark: error: "A_FICTITIOUS_UNREADABLE_FILE_FOR_TESTING_PURPOSES": permission denied.\n/, qq{Correct error message.} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( 'c', "A_FICTITIOUS_FILE_FOR_TESTING_PURPOSES" );
        } );
        $t->has_exception( qq{./mark c A_FICTITIOUS_FILE_FOR_TESTING_PURPOSES} );
        $t->exception_like( qr/mark: error: "A_FICTITIOUS_FILE_FOR_TESTING_PURPOSES": could not open file: /, qq{Correct error message.} );
        $t->stdout_is( qq{} );
        $t->stderr_is( qq{} );

    };

    subtest qq{'-d', '--debug' option switch} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-d', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -d '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/^0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLM$/, qq{Display to the correct point} );
        $t->stderr_like( qr/\n\$main::debug = 1\n/, qq{Prints debugging information.} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '--debug', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark --debug '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/^0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLM$/, qq{Display to the correct point} );
        $t->stderr_like( qr/\n\$main::debug = 1\n/, qq{Prints debugging information.} );

    };

    subtest qq{'-f' option switch} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\njklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghi\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\ntuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrs$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '3', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 3 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nlmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopq$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '0,4', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 0,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '2,4', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 2,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '2,0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 2,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '0,22', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 0,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '11,22', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 11,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '11,0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 11,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f3', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f3 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nlmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopq$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0,4', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f2,4', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f2,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f2,0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f2,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0,22', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f11,22', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f11,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f11,0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f11,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0,1,', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0,1, '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status != 0, "Incorrect parameter specification." );
        $t->stdout_is( qq{} );
        $t->stderr_like( qr/\nmark: error: You have specified "-0,1," for <PATTERN>.\n/, qq{The right warning.} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0', 'rstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0 'rstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0, qq{Do not display redundant "skip" messages.} );
        $t->stdout_like( qr/\*\nlmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopq$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f' );
        } );
        $t->has_no_exception( qq{./mark -f} );
        ok( $status != 0, qq{An error occurs.} );
        $t->stdout_is( qq{} );
        $t->stderr_like( qr/^mark: error: Please specify the Regular Expressions.\n/, qq{Prompt for corrective action.} );

    };

    subtest qq{'-h', '--no-filename' option switch} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt", "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0h', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt", "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0h '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-hf0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt", "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -hf0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0', '--no-filename', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt", "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0 --no-filename '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '--no-filename', '-f0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt", "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark --no-filename -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

    };

    subtest qq{'-H', '--with-filename' option switch} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0H', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0H '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0H', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt", "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0H '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-Hf0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -Hf0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0', '--with-filename', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0 --with-filename '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '--with-filename', '-f0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark --with-filename -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f1H', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f1H '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
        $t->stdout_like( qr/:nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklm\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/:pqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmno$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

    };

    subtest qq{'-v', '--version' option switch} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '--version' );
        } );
        $t->has_no_exception( qq{./mark --version} );
        ok( $status == 0 );
        $t->stdout_like( qr/^Version: \d/ );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-v' );
        } );
        $t->has_no_exception( qq{./mark -v} );
        ok( $status == 0 );
        $t->stdout_like( qr/^Version: \d/ );
        $t->stderr_is( qq{} );

    };

    subtest qq{'-i', '--ignore-case' option switch} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0', '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_is( qq{}, qq{No lines match.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0i', '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0i '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Match with optional effects.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-if0', '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -if0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Match with optional effects.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f0', '--ignore-case', '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f0 --ignore-case '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Match with optional effects.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '--ignore-case', '-f0', '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark --ignore-case -f0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Match with optional effects.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '--ignore-case', '--force-color', '-f0', '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark --ignore-case --force-color -f0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
        $t->stderr_is( qq{} );

    };

    subtest qq{'-n', '--line-number' option switch} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_unlike( qr/25/, qq{Line numbers are not displayed.} );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '0', '-n', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 0 -n '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{The line number is displayed.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-n', '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -n -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{The line number is displayed.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '0', '--line-number', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 0 --line-number '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{The line number is displayed.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '--line-number', '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark --line-number -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{The line number is displayed.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f1n', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f1n '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/24:nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklm\n/, qq{Display from the correct point} );
        $t->stdout_like( qr/26:pqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmno$/, qq{Display to the correct point} );
        $t->stderr_is( qq{} );

    };

    subtest qq{'-c', '--force-color' option switch} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_unlike( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n/, qq{Not highlighted.} );
        $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$/, qq{Not highlighted.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '0', '-c', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 0 -c '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-c', '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -c -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '-f', '0', '--force-color', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark -f 0 --force-color '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = &pl_main( '--force-color', '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "$apppath/testdata_uniq_line.txt" );
        } );
        $t->has_no_exception( qq{./mark --force-color -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' $apppath/testdata_uniq_line.txt} );
        ok( $status == 0 );
        $t->stdout_like( qr/\033\[34m\*\*\* skip \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m$/, qq{It will be highlighted.} );
        $t->stderr_is( qq{} );

    };

};

subtest qq{<FILE> Test} => sub{
    my $t;


    $t = tests::Tester->run_cmd( qq{echo "123" | ./mark -d mark -} );
    $t->exit_is( 0, "normal termination" );
    $t->stdout_is( "123\n", qq{Only "123"} );
    $t->stderr_like( qr/\n\@main::fi_in = 1\n/, qq{The number of input files is correct} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo "123" | ./mark -d mark} );
    $t->exit_is( 0, qq{Omit the hyphen(-).} );
    $t->stdout_is( "123\n", qq{Only "123"} );
    $t->stderr_like( qr/\n\@main::fi_in = 1\n/, qq{The number of input files is correct} );
    $t->stderr_like( qr/\n\$main::fi_in\[ 0 \] = "-"\n/, qq{Hyphens(-) must be completed.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo "123" | ./mark -d mark - -} );
    $t->exit_isnt( 0, "Returning an error" );
    $t->stdout_is( qq{}, qq{stdout is silent} );
    $t->stderr_like( qr/mark: error: "STDIN\(-\)" cannot be specified more than once.\n/, qq{The number of input files is correct} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{echo "123" | ./mark -d mark - ./mark -} );
    $t->exit_isnt( 0, "Returning an error" );
    $t->stdout_is( qq{}, qq{stdout is silent} );
    $t->stderr_like( qr/mark: error: "STDIN\(-\)" cannot be specified more than once.\n/, qq{The number of input files is correct} );
    undef( $t );


    $t = tests::Tester->run_cmd( qq{echo "123" | ./mark c $proj_root/mark -} );
    $t->exit_is( 0, "Allows duplicates of existing files." );
    $t->stdout_like( qr/#!\/usr\/bin\/perl -w\n/, qq{Display from the beginning} );
    $t->stdout_like( qr/:123$/, qq{Display to the end} );
    $t->stderr_is( qq{}, qq{stderr is silent} );
    undef( $t );

};

done_testing();
