#!/usr/bin/env perl
################################################################################
## - $Revision: 1.10 $
################################################################################

use strict;                     # first released with perl 5
use warnings;                   # first released with perl v5.6.0

#use lib '.';
use FindBin;                    # first released with perl 5.00307
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Tester;

my %phrase = tests::Tester::get_phrase();
#my $apppath = $phrase{apppath};
#my $proj_root = $phrase{proj_root};

subtest qq{In-Proc Test} => sub{

    require './mark';

    subtest qq{"Usage" test} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = pl_main();
        } );
        $t->has_no_exception( qq{./mark} );
        ok( $status != 0 );
        $t->stdout_is( qq{} );
        $t->stderr_like( qr/mark: error: Please specify <PATTERN>./, qq{Usage explanation} );
        $t->stderr_like( qr/\nUsage:\n/, qq{Usage explanation} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( '--help' );
        } );
        $t->has_no_exception( qq{./mark --help} );
        ok( $status == 0 );
        $t->stdout_like( qr/^Usage:\n/, qq{Usage explanation} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( '--help', '123' );
        } );
        $t->has_no_exception( qq{./mark --help 123} );
        ok( $status == 0 );
        $t->stdout_like( qr/^Usage:\n/, qq{Usage explanation} );
        $t->stdout_unlike( qr/123/, qq{Arguments are ignored when displaying "help".} );
        $t->stderr_is( qq{} );

    };

    subtest qq{function test: read_one_line()} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( '-i', '\b(a|the)\b', 'LICENSE', '--syscall-act=0x01' );
        } );
        $t->has_exception( qq{./mark -i '\b(a|the)\b' LICENSE --syscall-act=0x01} );
        $t->exception_like( qr/^fcntl F_GETFL failure: / );
        $t->stdout_is( qq{} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( '-i', '\b(a|the)\b', 'LICENSE', '--syscall-act=0x02' );
        } );
        $t->has_exception( qq{./mark -i '\b(a|the)\b' LICENSE --syscall-act=0x02} );
        $t->exception_like( qr/^error: select\(\): / );
        $t->stdout_is( qq{} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( '-i', '\b(a|the)\b', 'LICENSE', '--syscall-act=0x04' );
        } );
        $t->has_no_exception( qq{./mark -i '\b(a|the)\b' LICENSE --syscall-act=0x04} );
        ok( $status == 0 );
        $t->stdout_like( qr/^BSD 2-Clause License\n/ );
        $t->stdout_like( qr/\nOF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n$/ );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( '-i', '\b(a|the)\b', 'LICENSE', '--syscall-act=0x08' );
        } );
        $t->has_exception( qq{./mark -i '\b(a|the)\b' LICENSE --syscall-act=0x08} );
        $t->exception_like( qr/^fcntl F_SETFL: Failed to set NONBLOCK: / );
        $t->stdout_is( qq{} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( '-i', '\b(a|the)\b', 'LICENSE', '--syscall-act=0x10' );
        } );
        $t->has_exception( qq{./mark -i '\b(a|the)\b' LICENSE --syscall-act=0x10} );
        $t->exception_like( qr/^fcntl F_SETFL: Failed to restore the original mode: / );
        $t->stdout_is( qq{} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( '-i', '\b(a|the)\b', 'LICENSE', '--syscall-act=0x20' );
        } );
        $t->has_exception( qq{./mark -i '\b(a|the)\b' LICENSE --syscall-act=0x20} );
        $t->exception_like( qr/^error: sysread\(\): / );
        $t->stdout_is( qq{} );
        $t->stderr_is( qq{} );

    };

    subtest qq{<FILE> Test} => sub{
        my $t;
        my $status;

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( 'mark', "./mark" );
        } );
        $t->has_no_exception( qq{./mark mark ./mark} );
        ok( $status == 0 );
        $t->stdout_like( qr/^#!\/usr\/bin\/env perl\n/, qq{Display from the beginning} );
        $t->stdout_like( qr/=cut$/, qq{Display to the end} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( '^#!/usr', "./mark" );
        } );
        $t->has_no_exception( qq{./mark '^#!/usr' ./mark} );
        ok( $status == 0 );
        $t->stdout_like( qr/^#!\/usr\/bin\/env perl\n/, qq{Display from the beginning} );
        $t->stdout_like( qr/=cut$/, qq{Display to the end} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( 'c', "./mark", "./mark" );
        } );
        $t->has_no_exception( qq{./mark perl ./mark ./mark} );
        ok( $status == 0, "Allows duplicates of existing files." );
        $t->stdout_like( qr/#!\/usr\/bin\/env perl\n/, qq{Display from the beginning} );
        $t->stdout_like( qr/=cut$/, qq{Display to the end} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_blk( sub{
            $status = pl_main( 'pattern', "--NON-EXISTENT-FILE" );
        } );
        $t->has_exception( qq{./mark pattern --NON-EXISTENT-FILE} );
        $t->exception_like( qr/^mark: error: "NON\-EXISTENT\-FILE": could not open file: /, qq{Correct error message.} );
        $t->stdout_is( qq{} );
        $t->stderr_is( qq{} );

    };

    subtest qq{Option Switch Test} => sub{

        subtest qq{Option Switch: '-d', '--debug'} => sub{
            my $t;
            my $status;

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-d', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -d '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/^0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLM$/, qq{Display to the correct point} );
            $t->stderr_like( qr/\n\$main::debug = 1\n/, qq{Prints debugging information.} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--debug', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark --debug '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/^0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJKLM$/, qq{Display to the correct point} );
            $t->stderr_like( qr/\n\$main::debug = 1\n/, qq{Prints debugging information.} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--debug', '--version' );
            } );
            $t->has_no_exception( qq{./mark --debug --version} );
            ok( $status == 0 );
            $t->stdout_like( qr/^Version: / );
            $t->stderr_like( qr/\n\$main::prt_fname = undef\n/, q{!defined( $main::prt_fname )} );
            $t->stderr_like( qr/\n\$main::re = undef\n/, q{!defined( $main::re )} );

        };

        subtest qq{Option Switch: '-f'} => sub{
            my $t;
            my $status;

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\njklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghi\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\ntuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrs\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '3', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 3 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nlmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopq\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '0,4', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 0,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '2,4', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 2,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '2,0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 2,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '0,22', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 0,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '11,22', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 11,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '11,0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 11,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f3', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f3 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nlmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopq\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0,4', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f2,4', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f2,4 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqr\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f2,0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f2,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0,22', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f11,22', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f11,22 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxygABCDEFGHIJ$/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f11,0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f11,0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\ndefghijklmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0,1,', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0,1, '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status != 0, "Incorrect parameter specification." );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{mark: error: "0,1,": <PATTERN> has already been specified as "^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$".\n}, qq{The right warning.} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0', 'rstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0 'rstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0, qq{Do not display redundant messages.} );
            $t->stdout_like( qr/\*\nlmnopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijk\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/\nrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopq\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f' );
            } );
            $t->has_no_exception( qq{./mark -f} );
            ok( $status != 0, qq{An error occurs.} );
            $t->stdout_is( qq{} );
            $t->stderr_like( qr/^mark: error: Please specify <PATTERN>.\n/, qq{Prompt for corrective action.} );

        };

        subtest qq{Option Switch: '--head-tail'} => sub{
            my $t;
            my $status;

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--head-tail', 'LICENSE' );
            } );
            $t->has_no_exception( qq{./mark --head-tail LICENSE} );
            ok( $status == 0 );
            $t->stdout_like( qr/\n\n        \*\*\* \(filtered\) \*\*\*\nDAMAGES \(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR\n/, qq{headの最後とtailの最初} );
            $t->stderr_is( qq{} );

        };

        subtest qq{Option Switch: '-h', '--no-filename'} => sub{
            my $t;
            my $status;

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt", "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\n\.\/tests\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-hf0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt", "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -hf0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_is(
                qq{ ***** [ ./tests/testdata_uniq_line.txt ] *****\n} .
                qq{        *** (filtered) ***\n} .
                qq{opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n} .
                qq{        *** (filtered) ***\n} .
                qq{ ***** [ ./tests/testdata_uniq_line.txt ] *****\n} .
                qq{        *** (filtered) ***\n} .
                qq{opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n} .
                qq{        *** (filtered) ***\n},
                qq{The effect of '--no-filename'} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0', '--no-filename', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt", "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0 --no-filename '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_is(
                qq{ ***** [ ./tests/testdata_uniq_line.txt ] *****\n} .
                qq{        *** (filtered) ***\n} .
                qq{opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n} .
                qq{        *** (filtered) ***\n} .
                qq{ ***** [ ./tests/testdata_uniq_line.txt ] *****\n} .
                qq{        *** (filtered) ***\n} .
                qq{opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n} .
                qq{        *** (filtered) ***\n},
                qq{The effect of '--no-filename'} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--no-filename', '-f0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt", "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark --no-filename -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_is(
                qq{ ***** [ ./tests/testdata_uniq_line.txt ] *****\n} .
                qq{        *** (filtered) ***\n} .
                qq{opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n} .
                qq{        *** (filtered) ***\n} .
                qq{ ***** [ ./tests/testdata_uniq_line.txt ] *****\n} .
                qq{        *** (filtered) ***\n} .
                qq{opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n} .
                qq{        *** (filtered) ***\n},
                qq{The effect of '--no-filename'} );
            $t->stderr_is( qq{} );

        };

        subtest qq{Option Switch: '-H', '--with-filename'} => sub{
            my $t;
            my $status;

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_unlike( qr/\/testdata_uniq_line.txt/, qq{The file name is not displayed.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0', '-H', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0 -H '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0', '-H', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt", "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0 -H '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-Hf0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -Hf0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0', '--with-filename', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0 --with-filename '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--with-filename', '-f0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark --with-filename -f0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f1', '-H', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f1 -H '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\/testdata_uniq_line.txt/, qq{The file name is displayed.} );
            $t->stdout_like( qr/:nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklm\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/:pqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmno\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

        };

        subtest qq{Option Switch: '-v', '--version'} => sub{
            my $t;
            my $status;

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--version' );
            } );
            $t->has_no_exception( qq{./mark --version} );
            ok( $status == 0 );
            $t->stdout_like( qr/^Version: \d/ );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-v' );
            } );
            $t->has_no_exception( qq{./mark -v} );
            ok( $status == 0 );
            $t->stdout_like( qr/^Version: \d/ );
            $t->stderr_is( qq{} );

        };

        subtest qq{Option Switch: '-i', '--ignore-case'} => sub{
            my $t;
            my $status;

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0', '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_is( qq{        *** (filtered) ***\n}, qq{No lines match.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0', '-i', '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0 -i '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n        \*\*\* \(filtered\) \*\*\*\n$/, qq{Match with optional effects.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-if0', '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -if0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n        \*\*\* \(filtered\) \*\*\*\n$/, qq{Match with optional effects.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f0', '--ignore-case', '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f0 --ignore-case '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n        \*\*\* \(filtered\) \*\*\*\n$/, qq{Match with optional effects.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--ignore-case', '-f0', '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark --ignore-case -f0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n        \*\*\* \(filtered\) \*\*\*\n$/, qq{Match with optional effects.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--ignore-case', '--force-color', '-f0', '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark --ignore-case --force-color -f0 '^opqrstuvwxygabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\033\[34m\*\*\* \(filtered\) \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m\n        \033\[34m\*\*\* \(filtered\) \*\*\*\033\[0m\n$/, qq{It will be highlighted.} );
            $t->stderr_is( qq{} );

        };

        subtest qq{Option Switch: '-n', '--line-number'} => sub{
            my $t;
            my $status;

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_unlike( qr/25/, qq{Line numbers are not displayed.} );
            $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '0', '-n', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 0 -n '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{The line number is displayed.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-n', '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -n -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{The line number is displayed.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '0', '--line-number', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 0 --line-number '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{The line number is displayed.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--line-number', '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark --line-number -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\*\n     25:opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n/, qq{The line number is displayed.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-nf1', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -nf1 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/24:nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklm\n/, qq{Display from the correct point} );
            $t->stdout_like( qr/26:pqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmno\n/, qq{Display to the correct point} );
            $t->stderr_is( qq{} );

        };

        subtest qq{Option Switch: '-c', '--force-color'} => sub{
            my $t;
            my $status;

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_unlike( qr/\033\[34m\*\*\* \(filtered\) \*\*\*\033\[0m\n/, qq{Not highlighted.} );
            $t->stdout_like( qr/\*\nopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\n        \*\*\* \(filtered\) \*\*\*\n$/, qq{Not highlighted.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '0', '-c', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 0 -c '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\033\[34m\*\*\* \(filtered\) \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m\n        \033\[34m\*\*\* \(filtered\) \*\*\*\033\[0m\n$/, qq{It will be highlighted.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-c', '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -c -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\033\[34m\*\*\* \(filtered\) \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m\n        \033\[34m\*\*\* \(filtered\) \*\*\*\033\[0m\n$/, qq{It will be highlighted.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-f', '0', '--force-color', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark -f 0 --force-color '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\033\[34m\*\*\* \(filtered\) \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m\n        \033\[34m\*\*\* \(filtered\) \*\*\*\033\[0m\n$/, qq{It will be highlighted.} );
            $t->stderr_is( qq{} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--force-color', '-f', '0', '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn$', "./tests/testdata_uniq_line.txt" );
            } );
            $t->has_no_exception( qq{./mark --force-color -f 0 '^opqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\$' ./tests/testdata_uniq_line.txt} );
            ok( $status == 0 );
            $t->stdout_like( qr/\033\[34m\*\*\* \(filtered\) \*\*\*\033\[0m\n\033\[1mopqrstuvwxygABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmn\033\[0m\n        \033\[34m\*\*\* \(filtered\) \*\*\*\033\[0m\n$/, qq{It will be highlighted.} );
            $t->stderr_is( qq{} );

        };

        subtest qq{Option Switch: composite} => sub{
            my $t;
            my $status;

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '--non-existent-option' );
            } );
            $t->has_exception( q{./mark --non-existent-option} );
            $t->exception_is( qq{parse_arg(): error: Failed to parse option switches.\n}, '存在しないオプション（ロング形式）' );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{Unknown option: non-existent-option\n} );

            $t = tests::Tester->run_blk( sub{
                $status = pl_main( '-z' );
            } );
            $t->has_exception( q{./mark -z} );
            $t->exception_is( qq{parse_arg(): error: Failed to parse option switches.\n}, '存在しないオプション（ショート形式）' );
            $t->stdout_is( qq{} );
            $t->stderr_is( qq{Unknown option: z\n} );

        };

    };

};

subtest qq{Ex-Proc Test} => sub{

    subtest qq{<FILE> Test} => sub{
        my $t;

        $t = tests::Tester->run_cmd( qq{echo "123" | ./mark -d mark -} );
        $t->exit_is( 0, "normal termination" );
        $t->stdout_is( "123\n", qq{Only "123"} );
        $t->stderr_like( qr/\n\@main::fi_in = \( '\-' \)\n/, qq{Hyphens(-) must be completed.} );
        undef( $t );

        $t = tests::Tester->run_cmd( qq{echo "123" | ./mark -d mark} );
        $t->exit_is( 0, qq{Omit the hyphen(-).} );
        $t->stdout_is( "123\n", qq{Only "123"} );
        $t->stderr_like( qr/\n\@main::fi_in = \( '\-' \)\n/, qq{Hyphens(-) must be completed.} );
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

        $t = tests::Tester->run_cmd( qq{echo "123" | ./mark c ./mark -} );
        $t->exit_is( 0, "Allows duplicates of existing files." );
        $t->stdout_like( qr/#!\/usr\/bin\/env perl\n/, qq{Display from the beginning} );
        $t->stdout_like( qr/:123$/, qq{Display to the end} );
        $t->stderr_is( qq{}, qq{stderr is silent} );
        undef( $t );

    };

    subtest qq{function test: read_one_line()} => sub{
        my $t;

        $t = tests::Tester->run_cmd( q{./tests/output_slowly_and_gradually.pl | ./mark  -i '\b0?\d+\b' -} );
        $t->exit_is( 0, q{./tests/output_slowly_and_gradually.pl | ./mark  -i '\b0?\d+\b' -} );
        $t->stdout_is(
            qq{001: 01: 0123456789abcdef\n} .
            qq{002: 02: 123456789abcdef0\n} .
            qq{003: 03: 23456789abcdef01\n} .
            qq{004: 04: 3456789abcdef012\n} .
            qq{005: 05: 456789abcdef0123\n} .
            qq{006: 06: 56789abcdef01234\n} .
            qq{007: 07: 6789abcdef012345\n} .
            qq{008: 08: 789abcdef0123456\n} .
            qq{009: 01: 89abcdef01234567\n} .
            qq{010: 02: 9abcdef012345678\n} .
            qq{011: 03: abcdef0123456789\n} .
            qq{012: 04: bcdef0123456789a\n} .
            qq{013: 05: cdef0123456789ab\n} .
            qq{014: 06: def0123456789abc\n} .
            qq{015: 07: ef0123456789abcd\n} .
            qq{016: 08: f0123456789abcde\n},
            qq{漏れなく出力できること} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_cmd( q{./tests/output_slowly_and_gradually.pl --use-cr | ./mark  -i '\b0?\d+\b' -} );
        $t->exit_is( 0, q{./tests/output_slowly_and_gradually.pl --use-cr | ./mark  -i '\b0?\d+\b' -} );
        $t->stdout_is(
            qq{001: 01: 0123456789abcdef\n} .
            qq{002: 02: 123456789abcdef0\n} .
            qq{003: 03: 23456789abcdef01\n} .
            qq{004: 04: 3456789abcdef012\n} .
            qq{005: 05: 456789abcdef0123\n} .
            qq{006: 06: 56789abcdef01234\n} .
            qq{007: 07: 6789abcdef012345\n} .
            qq{008: 08: 789abcdef0123456\n} .
            qq{009: 01: 89abcdef01234567\n} .
            qq{010: 02: 9abcdef012345678\n} .
            qq{011: 03: abcdef0123456789\n} .
            qq{012: 04: bcdef0123456789a\n} .
            qq{013: 05: cdef0123456789ab\n} .
            qq{014: 06: def0123456789abc\n} .
            qq{015: 07: ef0123456789abcd\n} .
            qq{016: 08: f0123456789abcde\n},
            qq{キャリッジリターン（CR）を除去できていること} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_cmd( qq{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail} );
        $t->exit_is( 0, q{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail} );
        $t->stdout_is(
            qq{001: 01: 0123456789abcdef\n} .
            qq{002: 02: 123456789abcdef0\n} .
            qq{003: 03: 23456789abcdef01\n} .
            qq{004: 04: 3456789abcdef012\n} .
            qq{005: 05: 456789abcdef0123\n} .
            qq{006: 06: 56789abcdef01234\n} .
            qq{007: 07: 6789abcdef012345\n} .
            qq{008: 08: 789abcdef0123456\n} .
            qq{009: 01: 89abcdef01234567\n} .
            qq{010: 02: 9abcdef012345678\n} .
            qq{011: 03: abcdef0123456789\n} .
            qq{012: 04: bcdef0123456789a\n} .
            qq{013: 05: cdef0123456789ab\n} .
            qq{014: 06: def0123456789abc\n} .
            qq{015: 07: ef0123456789abcd\n} .
            qq{016: 08: f0123456789abcde\n},
            qq{漏れなく出力できること} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_cmd( qq{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail -f 3} );
        $t->exit_is( 0, q{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail -f 3} );
        $t->stdout_is(
            qq{001: 01: 0123456789abcdef\n} .
            qq{002: 02: 123456789abcdef0\n} .
            qq{003: 03: 23456789abcdef01\n} .
            qq{        *** (filtered) ***\n} .
            qq{006: 06: 56789abcdef01234\n} .
            qq{007: 07: 6789abcdef012345\n} .
            qq{008: 08: 789abcdef0123456\n} .
            qq{009: 01: 89abcdef01234567\n} .
            qq{010: 02: 9abcdef012345678\n} .
            qq{011: 03: abcdef0123456789\n} .
            qq{012: 04: bcdef0123456789a\n} .
            qq{013: 05: cdef0123456789ab\n} .
            qq{014: 06: def0123456789abc\n} .
            qq{015: 07: ef0123456789abcd\n} .
            qq{016: 08: f0123456789abcde\n},
            qq{4-5行目が間引かれていること} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_cmd( qq{./tests/output_slowly_and_gradually.pl --row 4 | ./mark --head-tail} );
        $t->exit_is( 0, q{./tests/output_slowly_and_gradually.pl --row 4 | ./mark --head-tail} );
        $t->stdout_is(
            qq{001: 01: 0123456789abcdef\n} .
            qq{002: 02: 123456789abcdef0\n} .
            qq{003: 03: 23456789abcdef01\n} .
            qq{004: 04: 3456789abcdef012\n} .
            qq{005: 01: 456789abcdef0123\n} .
            qq{006: 02: 56789abcdef01234\n} .
            qq{007: 03: 6789abcdef012345\n} .
            qq{008: 04: 789abcdef0123456\n} .
            qq{009: 01: 89abcdef01234567\n} .
            qq{010: 02: 9abcdef012345678\n} .
            qq{011: 03: abcdef0123456789\n} .
            qq{012: 04: bcdef0123456789a\n} .
            qq{013: 01: cdef0123456789ab\n} .
            qq{014: 02: def0123456789abc\n} .
            qq{015: 03: ef0123456789abcd\n} .
            qq{016: 04: f0123456789abcde\n},
            q{漏れなく出力できること: if( scalar( @main::pre_buffer ) )} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_cmd( qq{./tests/output_slowly_and_gradually.pl | ./mark '0123456789' -f 2 --head-tail} );
        $t->exit_is( 0, q{./tests/output_slowly_and_gradually.pl | ./mark '0123456789' -f 2 --head-tail} );
        $t->stdout_is(
            qq{001: 01: 0123456789abcdef\n} .
            qq{002: 02: 123456789abcdef0\n} .
            qq{003: 03: 23456789abcdef01\n} .
            qq{        *** (filtered) ***\n} .
            qq{007: 07: 6789abcdef012345\n} .
            qq{008: 08: 789abcdef0123456\n} .
            qq{009: 01: 89abcdef01234567\n} .
            qq{010: 02: 9abcdef012345678\n} .
            qq{011: 03: abcdef0123456789\n} .
            qq{012: 04: bcdef0123456789a\n} .
            qq{013: 05: cdef0123456789ab\n} .
            qq{014: 06: def0123456789abc\n} .
            qq{015: 07: ef0123456789abcd\n} .
            qq{016: 08: f0123456789abcde\n},
            q{3行目が出力できること} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_cmd( qq{./tests/output_slowly_and_gradually.pl | ./mark 'abcdef0123456' -f 2 --head-tail} );
        $t->exit_is( 0, q{./tests/output_slowly_and_gradually.pl | ./mark 'abcdef0123456' -f 2 --head-tail} );
        $t->stdout_is(
            qq{001: 01: 0123456789abcdef\n} .
            qq{002: 02: 123456789abcdef0\n} .
            qq{        *** (filtered) ***\n} .
            qq{006: 06: 56789abcdef01234\n} .
            qq{007: 07: 6789abcdef012345\n} .
            qq{008: 08: 789abcdef0123456\n} .
            qq{009: 01: 89abcdef01234567\n} .
            qq{010: 02: 9abcdef012345678\n} .
            qq{011: 03: abcdef0123456789\n} .
            qq{012: 04: bcdef0123456789a\n} .
            qq{013: 05: cdef0123456789ab\n} .
            qq{014: 06: def0123456789abc\n} .
            qq{015: 07: ef0123456789abcd\n} .
            qq{016: 08: f0123456789abcde\n},
            q{6行目が出力できること} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_cmd( qq{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail --line-number} );
        $t->exit_is( 0, q{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail --line-number} );
        $t->stdout_is(
            qq{      1:001: 01: 0123456789abcdef\n} .
            qq{      2:002: 02: 123456789abcdef0\n} .
            qq{      3:003: 03: 23456789abcdef01\n} .
            qq{      4:004: 04: 3456789abcdef012\n} .
            qq{      5:005: 05: 456789abcdef0123\n} .
            qq{      6:006: 06: 56789abcdef01234\n} .
            qq{      7:007: 07: 6789abcdef012345\n} .
            qq{      8:008: 08: 789abcdef0123456\n} .
            qq{      9:009: 01: 89abcdef01234567\n} .
            qq{     10:010: 02: 9abcdef012345678\n} .
            qq{     11:011: 03: abcdef0123456789\n} .
            qq{     12:012: 04: bcdef0123456789a\n} .
            qq{     13:013: 05: cdef0123456789ab\n} .
            qq{     14:014: 06: def0123456789abc\n} .
            qq{     15:015: 07: ef0123456789abcd\n} .
            qq{     16:016: 08: f0123456789abcde\n},
            q{行番号のカウントが正しいこと（漏れなく出力できていること）} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_cmd( qq{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail --line-number -f 2} );
        $t->exit_is( 0, q{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail --line-number -f 2} );
        $t->stdout_is(
            qq{      1:001: 01: 0123456789abcdef\n} .
            qq{      2:002: 02: 123456789abcdef0\n} .
            qq{        *** (filtered) ***\n} .
            qq{      7:007: 07: 6789abcdef012345\n} .
            qq{      8:008: 08: 789abcdef0123456\n} .
            qq{      9:009: 01: 89abcdef01234567\n} .
            qq{     10:010: 02: 9abcdef012345678\n} .
            qq{     11:011: 03: abcdef0123456789\n} .
            qq{     12:012: 04: bcdef0123456789a\n} .
            qq{     13:013: 05: cdef0123456789ab\n} .
            qq{     14:014: 06: def0123456789abc\n} .
            qq{     15:015: 07: ef0123456789abcd\n} .
            qq{     16:016: 08: f0123456789abcde\n},
            q{行番号のカウントが正しいこと（漏れなく出力できていること）} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_cmd( qq{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail --line-number -f 2 - LICENSE} );
        $t->exit_is( 0, q{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail --line-number -f 2 - LICENSE} );
        $t->stdout_is(
            qq{ ***** [ - ] *****\n} .
            qq{-      :      1:001: 01: 0123456789abcdef\n} .
            qq{-      :      2:002: 02: 123456789abcdef0\n} .
            qq{        *** (filtered) ***\n} .
            qq{-      :      7:007: 07: 6789abcdef012345\n} .
            qq{-      :      8:008: 08: 789abcdef0123456\n} .
            qq{-      :      9:009: 01: 89abcdef01234567\n} .
            qq{-      :     10:010: 02: 9abcdef012345678\n} .
            qq{-      :     11:011: 03: abcdef0123456789\n} .
            qq{-      :     12:012: 04: bcdef0123456789a\n} .
            qq{-      :     13:013: 05: cdef0123456789ab\n} .
            qq{-      :     14:014: 06: def0123456789abc\n} .
            qq{-      :     15:015: 07: ef0123456789abcd\n} .
            qq{-      :     16:016: 08: f0123456789abcde\n} .
            qq{ ***** [ LICENSE ] *****\n} .
            qq{LICENSE:      1:BSD 2-Clause License\n} .
            qq{LICENSE:      2:\n} .
            qq{        *** (filtered) ***\n} .
            qq{LICENSE:     24:OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE\n} .
            qq{LICENSE:     25:OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n},
            q{どちらのファイルもフィルターされていること} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_cmd( qq{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail --line-number -f 2 LICENSE -} );
        $t->exit_is( 0, q{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail --line-number -f 2 LICENSE -} );
        $t->stdout_is(
            qq{ ***** [ LICENSE ] *****\n} .
            qq{LICENSE:      1:BSD 2-Clause License\n} .
            qq{LICENSE:      2:\n} .
            qq{        *** (filtered) ***\n} .
            qq{LICENSE:     24:OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE\n} .
            qq{LICENSE:     25:OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n} .
            qq{ ***** [ - ] *****\n} .
            qq{-      :      1:001: 01: 0123456789abcdef\n} .
            qq{-      :      2:002: 02: 123456789abcdef0\n} .
            qq{        *** (filtered) ***\n} .
            qq{-      :      7:007: 07: 6789abcdef012345\n} .
            qq{-      :      8:008: 08: 789abcdef0123456\n} .
            qq{-      :      9:009: 01: 89abcdef01234567\n} .
            qq{-      :     10:010: 02: 9abcdef012345678\n} .
            qq{-      :     11:011: 03: abcdef0123456789\n} .
            qq{-      :     12:012: 04: bcdef0123456789a\n} .
            qq{-      :     13:013: 05: cdef0123456789ab\n} .
            qq{-      :     14:014: 06: def0123456789abc\n} .
            qq{-      :     15:015: 07: ef0123456789abcd\n} .
            qq{-      :     16:016: 08: f0123456789abcde\n},
            q{どちらのファイルもフィルターされていること} );
        $t->stderr_is( qq{} );

        $t = tests::Tester->run_cmd( q{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail --line-number -f 2 '\b(A|THE)\b' LICENSE -} );
        $t->exit_is( 0, q{./tests/output_slowly_and_gradually.pl --row 8 | ./mark --head-tail --line-number -f 2 '\b(A|THE)\b' LICENSE -} );
        $t->stdout_is(
            qq{ ***** [ LICENSE ] *****\n} .
            qq{LICENSE:      1:BSD 2-Clause License\n} .
            qq{LICENSE:      2:\n} .
            qq{        *** (filtered) ***\n} .
            qq{LICENSE:     14:   and/or other materials provided with the distribution.\n} .
            qq{LICENSE:     15:\n} .
            qq{LICENSE:     16:THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"\n} .
            qq{LICENSE:     17:AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE\n} .
            qq{LICENSE:     18:IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE\n} .
            qq{LICENSE:     19:DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE\n} .
            qq{LICENSE:     20:FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL\n} .
            qq{LICENSE:     21:DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR\n} .
            qq{LICENSE:     22:SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER\n} .
            qq{LICENSE:     23:CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,\n} .
            qq{LICENSE:     24:OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE\n} .
            qq{LICENSE:     25:OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n} .
            qq{ ***** [ - ] *****\n} .
            qq{-      :      1:001: 01: 0123456789abcdef\n} .
            qq{-      :      2:002: 02: 123456789abcdef0\n} .
            qq{        *** (filtered) ***\n} .
            qq{-      :      7:007: 07: 6789abcdef012345\n} .
            qq{-      :      8:008: 08: 789abcdef0123456\n} .
            qq{-      :      9:009: 01: 89abcdef01234567\n} .
            qq{-      :     10:010: 02: 9abcdef012345678\n} .
            qq{-      :     11:011: 03: abcdef0123456789\n} .
            qq{-      :     12:012: 04: bcdef0123456789a\n} .
            qq{-      :     13:013: 05: cdef0123456789ab\n} .
            qq{-      :     14:014: 06: def0123456789abc\n} .
            qq{-      :     15:015: 07: ef0123456789abcd\n} .
            qq{-      :     16:016: 08: f0123456789abcde\n},
            q{どちらのファイルもフィルターされていること} );
        $t->stderr_is( qq{} );

    };

};

done_testing();
