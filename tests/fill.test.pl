#!/usr/bin/perl -w

use strict;
use warnings;

## Test::More was first released with perl v5.6.2
use Test::More;     # subtest()

#use lib '.';
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Command;

use Cwd 'getcwd';   # getcwd()

&tests::Command::TestPreProc( $0, @ARGV );

my $proj_root = getcwd();
my $apppath = $proj_root . '/tests';

subtest qq{debug mode} => sub{
    my $t;

    $t = tests::Command->new( "./fill -d -1 123" );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill --debug -1 123" );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -dh -1 123" );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
    $t->stdout_like( qr/usage: fill /, "usage output" );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    ## テストは通せるがキャプチャできないのでSTDOUTの評価ができない。その為やる意味が無い。
##    $t = tests::Command->new( "./fill -1 '123-%%01:1%%' >/proc/self/fd/1" );
#    $t = tests::Command->new( "./fill -1 '123-%%01:1%%' >/dev/pty1" );
#    $t->exit_is( 0, "exit status is 0" );
#    $t->stdout_is( qq{}, qq{Capture not possible} );
#    $t->stderr_is( qq{}, "stderr is silent" );
#    undef( $t );
    $t = tests::Command->new( "./fill --test-force-tty -2 a- 1:1 -b " );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{a-\033[1m1\033[0m-b\na-\033[1m2\033[0m-b\n}, qq{ANSI escape sequence} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );
};

subtest qq{"Usage" test} => sub{
    my $t;

    $t = tests::Command->new( "./fill" );
    $t->exit_isnt( 0, "Treat it as an error." );
    $t->stdout_is( "", "Does not output anything." );
    $t->stderr_like( qr/fill: An argument must be specified./, "usage output" );
    undef( $t );

    $t = tests::Command->new( "./fill -h" );
    $t->exit_is( 0, "Do not treat it as an error." );
    $t->stdout_like( qr/^usage: fill /, "usage output" );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill --help" );
    $t->exit_is( 0, "Do not treat it as an error." );
    $t->stdout_like( qr/^usage: fill /, "usage output" );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -h 123" );
    $t->exit_is( 0, "Do not treat it as an error." );
    $t->stdout_like( qr/^usage: fill /, qq{Only "help" is displayed.} );
    $t->stdout_unlike( qr/123/, qq{Arguments are ignored when displaying "help".} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );
};

subtest qq{"-v", "--version" option} => sub{
    my $t;

    $t = tests::Command->new( qq{./fill --version} );
    $t->exit_is( 0, qq{./fill --version} );
    $t->stdout_like( qr/^Version: \d/ );
    $t->stderr_is( qq{}, qq{STDERR is silent} );
    undef( $t );

    $t = tests::Command->new( qq{./fill -v} );
    $t->exit_is( 0, qq{./fill -v} );
    $t->stdout_like( qr/^Version: \d/ );
    $t->stderr_is( qq{}, qq{STDERR is silent} );
    undef( $t );

};

subtest qq{Counter format} => sub{
    subtest qq{Counter format: counter} => sub{
        my $t;

        $t = tests::Command->new( "./fill 1:1" );
        $t->exit_is( 0, "exit status is 0" );
        $t->stdout_is( "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n", "basic test" );
        $t->stderr_is( "", "stderr is silent" );
        undef( $t );

        $t = tests::Command->new( "./fill 01:1" );
        $t->exit_is( 0, "exit status is 0" );
        $t->stdout_is( "01\n02\n03\n04\n05\n06\n07\n08\n09\n10\n", "basic test" );
        $t->stderr_is( "", "stderr is silent" );
        undef( $t );

        $t = tests::Command->new( "./fill -1:-1" );
        $t->exit_is( 0, "exit status is 0" );
        $t->stdout_is( "-1\n-2\n-3\n-4\n-5\n-6\n-7\n-8\n-9\n-10\n", "basic test" );
        $t->stderr_is( "", "stderr is silent" );
        undef( $t );

        $t = tests::Command->new( "./fill -01:-1" );
        $t->exit_is( 0, "exit status is 0" );
        $t->stdout_is( "-01\n-02\n-03\n-04\n-05\n-06\n-07\n-08\n-09\n-10\n", "basic test" );
        $t->stderr_is( "", "stderr is silent" );
        undef( $t );
    };

    subtest qq{Counter format: step} => sub{
        my $t;

        $t = tests::Command->new( "./fill -3 001:1" );
        $t->exit_is( 0, "Always terminates normally." );
        $t->stdout_is( "001\n002\n003\n", qq{Basic test for step value.} );
        $t->stderr_is( qq{}, "stderr is silent" );
        undef( $t );

        $t = tests::Command->new( "./fill -3 001:0" );
        $t->exit_is( 0, "Always terminates normally." );
        $t->stdout_is( "001\n001\n001\n", qq{Allow step "0".} );
        $t->stderr_is( qq{}, "stderr is silent" );
        undef( $t );

        $t = tests::Command->new( "./fill -3 010:-1" );
        $t->exit_is( 0, "Always terminates normally." );
        $t->stdout_is( "010\n009\n008\n", qq{Negative step values ​​are allowed.} );
        $t->stderr_is( qq{}, "stderr is silent" );
        undef( $t );
    };

    subtest qq{Counter format: General: "0" Boundary Test} => sub{
        my $t;

        $t = tests::Command->new( "./fill -5 002:-1" );
        $t->exit_is( 0, "Always terminates normally." );
        $t->stdout_is( "002\n001\n000\n-01\n-02\n", qq{Allows sign changes.} );
        $t->stderr_is( qq{fill: "0:-1": The sign changes across 0.\n}, "Show warning" );
        undef( $t );

        $t = tests::Command->new( "./fill -3 002:-1" );
        $t->exit_is( 0, "Always terminates normally." );
        $t->stdout_is( "002\n001\n000\n", qq{Allows sign changes.} );
        $t->stderr_is( qq{}, "stderr is silent" );
        undef( $t );

        $t = tests::Command->new( "./fill -5 -02:1" );
        $t->exit_is( 0, "Always terminates normally." );
        $t->stdout_is( "-02\n-01\n000\n001\n002\n", qq{Allows sign changes.} );
        $t->stderr_is( qq{fill: "-1:1": The sign changes across 0.\n}, "Show warning" );
        undef( $t );

        $t = tests::Command->new( "./fill -3 -02:1" );
        $t->exit_is( 0, "Always terminates normally." );
        $t->stdout_is( "-02\n-01\n000\n", qq{Allows sign changes.} );
        $t->stderr_is( qq{fill: "-1:1": The sign changes across 0.\n}, "Show warning" );
        undef( $t );
    };
};

subtest qq{"-N" option switch} => sub{
    my $t;

    $t = tests::Command->new( "./fill -3 10:2" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_is( "10\n12\n14\n", qq{"-N" option switch} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -9 1:1" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_is( "1\n2\n3\n4\n5\n6\n7\n8\n9\n", "Single digit counter" );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -10 1:1" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_is( "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n", "double-digit counter" );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -10d3 1:1" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_like( qr/1\n2\n3\n$/, "Use the last specified value." );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -0 -" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_is( "", qq{"-0" is also allowed} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "echo 123 | ./fill -2 -" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_is( "123\n", "Outputs the number of lines in STDIN instead of the default 10 lines." );
    $t->stderr_like( qr/^fill: STDIN=1, specified_cycle=2: /, "Show warning" );
    undef( $t );

    $t = tests::Command->new( "echo 123 | ./fill -1 -" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_is( "123\n", "Outputs the number of lines in STDIN instead of the default 10 lines." );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "echo 123 | ./fill -0 -" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_is( "", "stdout is silent" );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );
};

subtest qq{"-w" option switch} => sub{
    my $t;

    $t = tests::Command->new( "./fill -2 -w 1 1:1" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_is( "1\n2\n", qq{"-w" <N>} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -2 -w 1:1" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_is( "1\n2\n", qq{"-w"} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -w10d 10:10" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_like( qr/\n\$main::wait_sec = 10\n/, qq{The value 10 is recognized} );
    $t->stdout_like( qr/10\n20\n30\n40\n50\n60\n70\n80\n90\n100/, qq{"-w10d"} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -dw10 10:10" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_like( qr/\n\$main::wait_sec = 10\n/, qq{The value 10 is recognized} );
    $t->stdout_like( qr/10\n20\n30\n40\n50\n60\n70\n80\n90\n100/, qq{"-w10d"} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -2 1:1 -w" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_is( "1\n2\n", qq{"-w" <none>} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -dw -180 179:-1" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_like( qr/\n\$main::cycle = 180\n/, qq{The specified value is used} );
    $t->stdout_like( qr/\n\$main::wait_sec = 1\n/, qq{The default value is used} );
    $t->stdout_like( qr/\n002\n001\n000$/, qq{Counting down to 0} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -dw2 -90 178:-2" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_like( qr/\n\$main::cycle = 90\n/, qq{The specified value is used} );
    $t->stdout_like( qr/\n\$main::wait_sec = 2\n/, qq{The specified value is used} );
    $t->stdout_like( qr/\n004\n002\n000$/, qq{Counting down to 0} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -wd -180 179:-1" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_like( qr/\n\$main::cycle = 180\n/, qq{The specified value is used} );
    $t->stdout_like( qr/\n\$main::wait_sec = 1\n/, qq{The default value is used} );
    $t->stdout_like( qr/\n002\n001\n000$/, qq{Counting down to 0} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -w20d50 0980:-20" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_like( qr/\n\$main::cycle = 50\n/, qq{The specified value is used} );
    $t->stdout_like( qr/\n\$main::wait_sec = 20\n/, qq{The specified value is used} );
    $t->stdout_like( qr/\n0040\n0020\n0000$/, qq{Counting down to 0} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -d -5w2 2:2" );
    $t->exit_is( 0, "Always terminates normally." );
    $t->stdout_like( qr/\n\$main::cycle = 5\n/, qq{The specified value is used} );
    $t->stdout_like( qr/\n\$main::wait_sec = 2\n/, qq{The specified value is used} );
    $t->stdout_like( qr/\n6\n8\n10$/, qq{Counting up to 10} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );
};

subtest qq{Replacing data from STDIN} => sub{
    my $t;

    $t = tests::Command->new( "echo 123 | ./fill -" );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( "123\n", "Outputs the number of lines in STDIN instead of the default 10 lines." );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( "./fill -" );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( "-\n-\n-\n-\n-\n-\n-\n-\n-\n-\n", "10 lines of output" );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt 'a.txt\nb.txt\nc.txt' | ./fill -3 'mv "%%-%%" "newname_%%01:1%%.txt"'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "a.txt" "newname_01.txt"\nmv "b.txt" "newname_02.txt"\nmv "c.txt" "newname_03.txt"\n}, "Replace with data from STDIN." );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{./fill -3 'mv "%%-%%" "newname_%%01:1%%.txt"'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "%%-%%" "newname_01.txt"\nmv "%%-%%" "newname_02.txt"\nmv "%%-%%" "newname_03.txt"\n}, qq{Output as "%%-%%".} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{echo '1>i<N>p<U>t<9' | ./fill 8 - 2 -d} );
    $t->exit_is( 0, "Internal Special Tokens" );
    $t->stdout_like( qr/\n\$main::prt_fmt = "8>i<N>p<U>t<2"\n/, qq{"prt_fmt" is recognized correctly} );
    $t->stdout_like( qr/\n81>i<N>p<U>t<92\n/, qq{Correct output} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{echo '1>I<n>n<P>N<u>T<s>U<b>9' | ./fill 8 - 2 -d} );
    $t->exit_is( 0, "Internal Special Tokens" );
    $t->stdout_like( qr/\n\$main::prt_fmt = "8>i<N>p<U>t<2"\n/, qq{"prt_fmt" is recognized correctly} );
    $t->stdout_like( qr/\n81>I<n>n<P>N<u>T<s>U<b>92\n/, qq{Correct output} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{echo '1>I<n>n<P>N<u>T<g>S<u>B<9' | ./fill 8 - 2 -d} );
    $t->exit_is( 0, "Internal Special Tokens" );
    $t->stdout_like( qr/\n\$main::prt_fmt = "8>i<N>p<U>t<2"\n/, qq{"prt_fmt" is recognized correctly} );
    $t->stdout_like( qr/\n81>I<n>n<P>N<u>T<g>S<u>B<92\n/, qq{Correct output} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );
};

subtest qq{Control characters} => sub{
    my $t;

    $t = tests::Command->new( qq{./fill } . q{-3 1:1 '\n' 11:1} );
    $t->exit_is( 0, qq{"\\n" is support (New Line)} );
    $t->stdout_is( "1\n11\n2\n12\n3\n13\n", qq{Supports "\\n"} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{./fill } . q{-3 1:1 '\t' 21:1} );
    $t->exit_is( 0, qq{"\\t" is support (Tab)} );
    $t->stdout_is( "1\t21\n2\t22\n3\t23\n", qq{Supports "\\t"} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{./fill } . q{-3 1:1 '\r' 31:1} );
    $t->exit_is( 0, qq{"\\r" is NOT support (Carriage Return)} );
    $t->stdout_is( "1\\r31\n2\\r32\n3\\r33\n", qq{"\\r" is not support} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{./fill } . q{-3 1:1 '\f' 41:1} );
    $t->exit_is( 0, qq{"\\f" is NOT support (Form Feed)} );
    $t->stdout_is( "1\\f41\n2\\f42\n3\\f43\n", qq{"\\f" is not support} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{./fill } . q{-3 1:1 '\a ' 51:1} );
    $t->exit_is( 0, qq{"\\a" is support (Alarm)} );
    $t->stdout_is( "1\a 51\n2\a 52\n3\a 53\n", qq{Supports "\\a"} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{./fill } . q{-3 1:1 '\e' 61:1} );
    $t->exit_is( 0, qq{"\\e" is NOT support (Escape)} );
    $t->stdout_is( "1\\e61\n2\\e62\n3\\e63\n", qq{"\\e" is not support} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );
};

subtest qq{Escaping the "%" symbol} => sub{
    my $t;

    $t = tests::Command->new( qq{./fill -3 'usage rate: %%0:1%%%.'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( "usage rate: 0%.\nusage rate: 1%.\nusage rate: 2%.\n", qq{Escaping the "%" symbol} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt "123\n456" | ./fill 01:1 '-%%-%%-%%-' 101:1} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( "01-123-%%-101\n02-456-%%-102\n", "Replace the first match." );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt "123\n456" | ./fill '%%01:1%%-%%-' - '-%%101:1%%'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( "01-%%-123-101\n02-%%-456-102\n", "Replace the first match." );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );
};

subtest qq{<<SUB<..%..>SUB>>} => sub{
    my $t;

    $t = tests::Command->new( qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | ./fill } . q{'mv "%%-%%" "<<SUB<\.[^\.]+$>%<.%%01:1%%>SUB>>"'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "20170930141640_0774.MP4" "20170930141640_0774.01"\nmv "20170930141640_0775.MP4" "20170930141640_0775.02"\nmv "20170930141640_0776.MP4" "20170930141640_0776.03"\n}, qq{The counter can be inserted.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | ./fill } . q{'mv "%%-%%" "<<SUB<\.([^\.]+)$>%<_%%01:1%%.$1>SUB>>"'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "20170930141640_0774.MP4" "20170930141640_0774_01.MP4"\nmv "20170930141640_0775.MP4" "20170930141640_0775_02.MP4"\nmv "20170930141640_0776.MP4" "20170930141640_0776_03.MP4"\n}, qq{The counter can be inserted.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | ./fill } . q{'<<SUB<^((.+)\.([^\.]+))$>%<mv "$1" "$2_%%01:1%%.$3">SUB>>'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "20170930141640_0774.MP4" "20170930141640_0774_01.MP4"\nmv "20170930141640_0775.MP4" "20170930141640_0775_02.MP4"\nmv "20170930141640_0776.MP4" "20170930141640_0776_03.MP4"\n}, qq{The counter can be inserted.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | ./fill } . q{'mv "' - '<<SUB<^(\d{4})(\d{2})(\d{2})(.*)\.([^\.]+)$>%<" "$1-$2-$3_$4_%%01:1%%.$5">SUB>>'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "20170930141640_0774.MP4" "2017-09-30_141640_0774_01.MP4"\nmv "20170930141640_0775.MP4" "2017-09-30_141640_0775_02.MP4"\nmv "20170930141640_0776.MP4" "2017-09-30_141640_0776_03.MP4"\n}, qq{The counter can be inserted.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | ./fill } . q{'mv "' - '<<SUB<^\d{4}\d{2}\d{2}.*\.[^\.]+$>%<" "$1-$2-$3_$4_%%01:1%%.$5">SUB>>'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "20170930141640_0774.MP4" "\$1-\$2-\$3_\$4_01.\$5"\nmv "20170930141640_0775.MP4" "\$1-\$2-\$3_\$4_02.\$5"\nmv "20170930141640_0776.MP4" "\$1-\$2-\$3_\$4_03.\$5"\n}, q{"$N" definition forgotten. Cannot be expanded.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | ./fill } . q{'<<SUB<^(\d{4})(\d{2})(\d{2})(.*)\.([^\.]+)$>%<"$1-$2-$3_$4_%%01:1%%.$5" "%%01:1%%_$1-$2-$3_$4.$5">SUB>>'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{"2017-09-30_141640_0774_01.MP4" "01_\$1-\$2-\$3_\$4.\$5"\n"2017-09-30_141640_0775_02.MP4" "02_\$1-\$2-\$3_\$4.\$5"\n"2017-09-30_141640_0776_03.MP4" "03_\$1-\$2-\$3_\$4.\$5"\n}, q{No global match} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt 'Makefile\nREADME.md\nauth-cram-md5\ncheck_header_file_dependencies.sh' | ./fill } . q{'mv "%%-%%" "<<SUB<\.([^\.]+)$>%<_%%01:1%%.$1>SUB>>"'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "Makefile" "Makefile"\nmv "README.md" "README_02.md"\nmv "auth-cram-md5" "auth-cram-md5"\nmv "check_header_file_dependencies.sh" "check_header_file_dependencies_04.sh"\n}, qq{Counters are added only to files with extensions.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt 'Makefile\nREADME.md\nauth-cram-md5\ncheck_header_file_dependencies.sh' | ./fill } . q{'<<SUB<(e)>%<E$1E>SUB>>'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{MakEeEfile\nREADME.md\nauth-cram-md5\nchEeEck_header_file_dependencies.sh\n}, qq{Only the first matched part is replaced.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{echo 'OPQRSTUOPQRSTU' | ./fill '9<<SUB<P>%<u>SUB>>1'} );
    $t->exit_is( 0, "Ability to recognize delimiters within macros" );
    $t->stdout_is( "9OuQRSTUOPQRSTU1\n", qq{The SUB() macro is successful.} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );
};

subtest qq{<<GSUB<..%..>GSUB>>} => sub{
    my $t;

    $t = tests::Command->new( qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | ./fill } . q{'mv "%%-%%" "<<GSUB<\.[^\.]+$>%<.%%01:1%%>GSUB>>"'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "20170930141640_0774.MP4" "20170930141640_0774.01"\nmv "20170930141640_0775.MP4" "20170930141640_0775.02"\nmv "20170930141640_0776.MP4" "20170930141640_0776.03"\n}, qq{The counter can be inserted.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | ./fill } . q{'mv "%%-%%" "<<GSUB<\.([^\.]+)$>%<_%%01:1%%.$1>GSUB>>"'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "20170930141640_0774.MP4" "20170930141640_0774_01.MP4"\nmv "20170930141640_0775.MP4" "20170930141640_0775_02.MP4"\nmv "20170930141640_0776.MP4" "20170930141640_0776_03.MP4"\n}, qq{The counter can be inserted.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | ./fill } . q{'<<GSUB<^((.+)\.([^\.]+))$>%<mv "$1" "$2_%%01:1%%.$3">GSUB>>'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "20170930141640_0774.MP4" "20170930141640_0774_01.MP4"\nmv "20170930141640_0775.MP4" "20170930141640_0775_02.MP4"\nmv "20170930141640_0776.MP4" "20170930141640_0776_03.MP4"\n}, qq{The counter can be inserted.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | ./fill } . q{'mv "' - '<<GSUB<^(\d{4})(\d{2})(\d{2})(.*)\.([^\.]+)$>%<" "$1-$2-$3_$4_%%01:1%%.$5">GSUB>>'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "20170930141640_0774.MP4" "2017-09-30_141640_0774_01.MP4"\nmv "20170930141640_0775.MP4" "2017-09-30_141640_0775_02.MP4"\nmv "20170930141640_0776.MP4" "2017-09-30_141640_0776_03.MP4"\n}, qq{The counter can be inserted.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | ./fill } . q{'mv "' - '<<GSUB<^\d{4}\d{2}\d{2}.*\.[^\.]+$>%<" "$1-$2-$3_$4_%%01:1%%.$5">GSUB>>'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "20170930141640_0774.MP4" "\$1-\$2-\$3_\$4_01.\$5"\nmv "20170930141640_0775.MP4" "\$1-\$2-\$3_\$4_02.\$5"\nmv "20170930141640_0776.MP4" "\$1-\$2-\$3_\$4_03.\$5"\n}, q{"$N" definition forgotten. Cannot be expanded.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | ./fill } . q{'<<GSUB<^(\d{4})(\d{2})(\d{2})(.*)\.([^\.]+)$>%<"$1-$2-$3_$4_%%01:1%%.$5" "%%01:1%%_$1-$2-$3_$4.$5">GSUB>>'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{"2017-09-30_141640_0774_01.MP4" "01_2017-09-30_141640_0774.MP4"\n"2017-09-30_141640_0775_02.MP4" "02_2017-09-30_141640_0775.MP4"\n"2017-09-30_141640_0776_03.MP4" "03_2017-09-30_141640_0776.MP4"\n}, q{Global match} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt 'Makefile\nREADME.md\nauth-cram-md5\ncheck_header_file_dependencies.sh' | ./fill } . q{'mv "%%-%%" "<<GSUB<\.([^\.]+)$>%<_%%01:1%%.$1>GSUB>>"'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{mv "Makefile" "Makefile"\nmv "README.md" "README_02.md"\nmv "auth-cram-md5" "auth-cram-md5"\nmv "check_header_file_dependencies.sh" "check_header_file_dependencies_04.sh"\n}, qq{Counters are added only to files with extensions.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt 'Makefile\nREADME.md\nauth-cram-md5\ncheck_header_file_dependencies.sh' | ./fill } . q{'<<GSUB<(e)>%<E$1E>GSUB>>'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( qq{MakEeEfilEeE\nREADME.md\nauth-cram-md5\nchEeEck_hEeEadEeEr_filEeE_dEeEpEeEndEeEnciEeEs.sh\n}, qq{All matches are replaced.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{echo 'OPQRSTUOPQRSTU' | ./fill '9<<GSUB<P>%<u>GSUB>>1'} );
    $t->exit_is( 0, "Ability to recognize delimiters within macros" );
    $t->stdout_is( "9OuQRSTUOuQRSTU1\n", qq{The GSUB() macro is successful.} );
    $t->stderr_is( "", "stderr is silent" );
    undef( $t );
};

subtest qq{complicated} => sub{
    my $t;

    $t = tests::Command->new( qq{./fill -d3 '-%%1:1%%%%-%%-' - '-%%10:-1%%%%01:1%%'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
    $t->stdout_like( qr/-1%%-%%---1001\n-2%%-%%---0902\n-3%%-%%---0803\n/, qq{Escaping the "%" symbol} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{$apppath/prt "123\n456" | ./fill -d3 '-%%1:1%%%%-%%-' - '-%%10:-1%%%%01:1%%'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
    $t->stdout_like( qr/-1123-123-1001\n-2456-456-0902\n/, qq{Escaping the "%" symbol} );
    $t->stderr_like( qr/^fill: STDIN=2, specified_cycle=3: /, "Show warning" );
    undef( $t );

    $t = tests::Command->new( qq{./fill -3 '%d%%1:3%%%d'} );
    $t->exit_is( 0, "exit status is 0" );
    $t->stdout_is( "%d1%d\n%d4%d\n%d7%d\n", qq{Don't be fooled by "%d"} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );

    $t = tests::Command->new( qq{cat "$proj_root/fill" | ./fill 0001:1 ' ' -} );
    $t->exit_is( 0, "A file containing special tokens." );
    $t->stdout_like( qr/ =cut$/, qq{It can be displayed to the end.} );
    $t->stderr_is( qq{}, "stderr is silent" );
    undef( $t );
};

&tests::Command::TestPostProc( $ENV{TEST_TARGET_CMD} );
