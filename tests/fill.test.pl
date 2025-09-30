#!/usr/bin/perl -w

use strict;
use warnings 'all';
use File::Basename ;

use constant MODULE_NOT_FOUND_STATUS => 0;

BEGIN {
  ## https://perldoc.jp/docs/modules/Test-Simple-0.96/lib/Test/More.pod
  eval{use Test::More};     # subtest(), done_testing()
  if( $@ ){
    print STDERR ( qq{Test::More: not found\n} );
    exit( MODULE_NOT_FOUND_STATUS );
  }
}

BEGIN {
  ## https://metacpan.org/pod/Test::Command
  eval{use Test::Command};
  if( $@ ){
    print STDERR ( qq{Test::Command: not found\n} );
    exit( MODULE_NOT_FOUND_STATUS );
  }
}

#$ENV{WITH_PERL_COVERAGE} = 1;

if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    `which cover 2>/dev/null`;
    my $bUnavailableCover = $?;
    #printf( qq{\$bUnavailableCover=$bUnavailableCover\n} );
    if( $bUnavailableCover ){
        print STDERR ( qq{$0: "cover" command not found: \$ENV{WITH_PERL_COVERAGE}: ignore\n} );
        delete( $ENV{WITH_PERL_COVERAGE} );
    }
}

my $develCoverStatus = -1;
if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    $develCoverStatus=`cover -delete`;
}

my $apppath = dirname( $0 );
my $FILLCMD = "$apppath/fill_wrapper.pl";
my $cmd;

subtest qq{debug mode} => sub{
    $cmd = Test::Command->new( cmd => "$FILLCMD -d -1 123" );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD --debug -1 123" );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -dh -1 123" );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
    $cmd->stdout_like( qr/usage: fill /, "usage output" );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    ## テストは通せるがキャプチャできないのでSTDOUTの評価ができない。その為やる意味が無い。
##    $cmd = Test::Command->new( cmd => "$FILLCMD -1 '123-%%01:1%%' >/proc/self/fd/1" );
#    $cmd = Test::Command->new( cmd => "$FILLCMD -1 '123-%%01:1%%' >/dev/pty1" );
#    $cmd->exit_is_num( 0, "exit status is 0" );
#    $cmd->stdout_is_eq( qq{}, qq{Capture not possible} );
#    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
#    undef( $cmd );
    $cmd = Test::Command->new( cmd => "$FILLCMD --test-force-tty -2 a- 1:1 -b " );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{a-\033[1m1\033[0m-b\na-\033[1m2\033[0m-b\n}, qq{ANSI escape sequence} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );
};

subtest qq{"Usage" test} => sub{
    $cmd = Test::Command->new( cmd => "$FILLCMD" );
    $cmd->exit_isnt_num( 0, "Treat it as an error." );
    $cmd->stdout_is_eq( "", "Does not output anything." );
    $cmd->stderr_like( qr/fill: An argument must be specified./, "usage output" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -h" );
    $cmd->exit_is_num( 0, "Do not treat it as an error." );
    $cmd->stdout_like( qr/^usage: fill /, "usage output" );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD --help" );
    $cmd->exit_is_num( 0, "Do not treat it as an error." );
    $cmd->stdout_like( qr/^usage: fill /, "usage output" );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -h 123" );
    $cmd->exit_is_num( 0, "Do not treat it as an error." );
    $cmd->stdout_like( qr/^usage: fill /, qq{Only "help" is displayed.} );
    $cmd->stdout_unlike( qr/123/, qq{Arguments are ignored when displaying "help".} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );
};

subtest qq{Counter format} => sub{
    subtest qq{Counter format: counter} => sub{
        $cmd = Test::Command->new( cmd => "$FILLCMD 1:1" );
        $cmd->exit_is_num( 0, "exit status is 0" );
        $cmd->stdout_is_eq( "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n", "basic test" );
        $cmd->stderr_is_eq( "", "stderr is silent" );
        undef( $cmd );

        $cmd = Test::Command->new( cmd => "$FILLCMD 01:1" );
        $cmd->exit_is_num( 0, "exit status is 0" );
        $cmd->stdout_is_eq( "01\n02\n03\n04\n05\n06\n07\n08\n09\n10\n", "basic test" );
        $cmd->stderr_is_eq( "", "stderr is silent" );
        undef( $cmd );

        $cmd = Test::Command->new( cmd => "$FILLCMD -1:-1" );
        $cmd->exit_is_num( 0, "exit status is 0" );
        $cmd->stdout_is_eq( "-1\n-2\n-3\n-4\n-5\n-6\n-7\n-8\n-9\n-10\n", "basic test" );
        $cmd->stderr_is_eq( "", "stderr is silent" );
        undef( $cmd );

        $cmd = Test::Command->new( cmd => "$FILLCMD -01:-1" );
        $cmd->exit_is_num( 0, "exit status is 0" );
        $cmd->stdout_is_eq( "-01\n-02\n-03\n-04\n-05\n-06\n-07\n-08\n-09\n-10\n", "basic test" );
        $cmd->stderr_is_eq( "", "stderr is silent" );
        undef( $cmd );
    };

    subtest qq{Counter format: step} => sub{
        $cmd = Test::Command->new( cmd => "$FILLCMD -3 001:1" );
        $cmd->exit_is_num( 0, "Always terminates normally." );
        $cmd->stdout_is_eq( "001\n002\n003\n", qq{Basic test for step value.} );
        $cmd->stderr_is_eq( qq{}, "stderr is silent" );
        undef( $cmd );

        $cmd = Test::Command->new( cmd => "$FILLCMD -3 001:0" );
        $cmd->exit_is_num( 0, "Always terminates normally." );
        $cmd->stdout_is_eq( "001\n001\n001\n", qq{Allow step "0".} );
        $cmd->stderr_is_eq( qq{}, "stderr is silent" );
        undef( $cmd );

        $cmd = Test::Command->new( cmd => "$FILLCMD -3 010:-1" );
        $cmd->exit_is_num( 0, "Always terminates normally." );
        $cmd->stdout_is_eq( "010\n009\n008\n", qq{Negative step values ​​are allowed.} );
        $cmd->stderr_is_eq( qq{}, "stderr is silent" );
        undef( $cmd );
    };

    subtest qq{Counter format: General: "0" Boundary Test} => sub{
        $cmd = Test::Command->new( cmd => "$FILLCMD -5 002:-1" );
        $cmd->exit_is_num( 0, "Always terminates normally." );
        $cmd->stdout_is_eq( "002\n001\n000\n-01\n-02\n", qq{Allows sign changes.} );
        $cmd->stderr_is_eq( qq{fill: "0:-1": The sign changes across 0.\n}, "Show warning" );
        undef( $cmd );

        $cmd = Test::Command->new( cmd => "$FILLCMD -3 002:-1" );
        $cmd->exit_is_num( 0, "Always terminates normally." );
        $cmd->stdout_is_eq( "002\n001\n000\n", qq{Allows sign changes.} );
        $cmd->stderr_is_eq( qq{}, "stderr is silent" );
        undef( $cmd );

        $cmd = Test::Command->new( cmd => "$FILLCMD -5 -02:1" );
        $cmd->exit_is_num( 0, "Always terminates normally." );
        $cmd->stdout_is_eq( "-02\n-01\n000\n001\n002\n", qq{Allows sign changes.} );
        $cmd->stderr_is_eq( qq{fill: "-1:1": The sign changes across 0.\n}, "Show warning" );
        undef( $cmd );

        $cmd = Test::Command->new( cmd => "$FILLCMD -3 -02:1" );
        $cmd->exit_is_num( 0, "Always terminates normally." );
        $cmd->stdout_is_eq( "-02\n-01\n000\n", qq{Allows sign changes.} );
        $cmd->stderr_is_eq( qq{fill: "-1:1": The sign changes across 0.\n}, "Show warning" );
        undef( $cmd );
    };
};

subtest qq{"-N" option switch} => sub{
    $cmd = Test::Command->new( cmd => "$FILLCMD -3 10:2" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_is_eq( "10\n12\n14\n", qq{"-N" option switch} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -9 1:1" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_is_eq( "1\n2\n3\n4\n5\n6\n7\n8\n9\n", "Single digit counter" );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -10 1:1" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_is_eq( "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n", "double-digit counter" );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -10d3 1:1" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_like( qr/1\n2\n3\n$/, "Use the last specified value." );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -0 -" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_is_eq( "", qq{"-0" is also allowed} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "echo 123 | $FILLCMD -2 -" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_is_eq( "123\n", "Outputs the number of lines in STDIN instead of the default 10 lines." );
    $cmd->stderr_like( qr/^fill: STDIN=1, specified_cycle=2: /, "Show warning" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "echo 123 | $FILLCMD -1 -" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_is_eq( "123\n", "Outputs the number of lines in STDIN instead of the default 10 lines." );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "echo 123 | $FILLCMD -0 -" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_is_eq( "", "stdout is silent" );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );
};

subtest qq{"-w" option switch} => sub{
    $cmd = Test::Command->new( cmd => "$FILLCMD -2 -w 1 1:1" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_is_eq( "1\n2\n", qq{"-w" <N>} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -2 -w 1:1" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_is_eq( "1\n2\n", qq{"-w"} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -w10d 10:10" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_like( qr/\n\$main::wait_sec = 10\n/, qq{The value 10 is recognized} );
    $cmd->stdout_like( qr/10\n20\n30\n40\n50\n60\n70\n80\n90\n100/, qq{"-w10d"} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -dw10 10:10" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_like( qr/\n\$main::wait_sec = 10\n/, qq{The value 10 is recognized} );
    $cmd->stdout_like( qr/10\n20\n30\n40\n50\n60\n70\n80\n90\n100/, qq{"-w10d"} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -2 1:1 -w" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_is_eq( "1\n2\n", qq{"-w" <none>} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -dw -180 179:-1" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_like( qr/\n\$main::cycle = 180\n/, qq{The specified value is used} );
    $cmd->stdout_like( qr/\n\$main::wait_sec = 1\n/, qq{The default value is used} );
    $cmd->stdout_like( qr/\n002\n001\n000$/, qq{Counting down to 0} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -dw2 -90 178:-2" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_like( qr/\n\$main::cycle = 90\n/, qq{The specified value is used} );
    $cmd->stdout_like( qr/\n\$main::wait_sec = 2\n/, qq{The specified value is used} );
    $cmd->stdout_like( qr/\n004\n002\n000$/, qq{Counting down to 0} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -wd -180 179:-1" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_like( qr/\n\$main::cycle = 180\n/, qq{The specified value is used} );
    $cmd->stdout_like( qr/\n\$main::wait_sec = 1\n/, qq{The default value is used} );
    $cmd->stdout_like( qr/\n002\n001\n000$/, qq{Counting down to 0} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -w20d50 0980:-20" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_like( qr/\n\$main::cycle = 50\n/, qq{The specified value is used} );
    $cmd->stdout_like( qr/\n\$main::wait_sec = 20\n/, qq{The specified value is used} );
    $cmd->stdout_like( qr/\n0040\n0020\n0000$/, qq{Counting down to 0} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -d -5w2 2:2" );
    $cmd->exit_is_num( 0, "Always terminates normally." );
    $cmd->stdout_like( qr/\n\$main::cycle = 5\n/, qq{The specified value is used} );
    $cmd->stdout_like( qr/\n\$main::wait_sec = 2\n/, qq{The specified value is used} );
    $cmd->stdout_like( qr/\n6\n8\n10$/, qq{Counting up to 10} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );
};

subtest qq{Replacing data from STDIN} => sub{
    $cmd = Test::Command->new( cmd => "echo 123 | $FILLCMD -" );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( "123\n", "Outputs the number of lines in STDIN instead of the default 10 lines." );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => "$FILLCMD -" );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( "-\n-\n-\n-\n-\n-\n-\n-\n-\n-\n", "10 lines of output" );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt 'a.txt\nb.txt\nc.txt' | $FILLCMD -3 'mv "%%-%%" "newname_%%01:1%%.txt"'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "a.txt" "newname_01.txt"\nmv "b.txt" "newname_02.txt"\nmv "c.txt" "newname_03.txt"\n}, "Replace with data from STDIN." );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$FILLCMD -3 'mv "%%-%%" "newname_%%01:1%%.txt"'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "%%-%%" "newname_01.txt"\nmv "%%-%%" "newname_02.txt"\nmv "%%-%%" "newname_03.txt"\n}, qq{Output as "%%-%%".} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '1>i<N>p<U>t<9' | $FILLCMD 8 - 2 -d} );
    $cmd->exit_is_num( 0, "Internal Special Tokens" );
    $cmd->stdout_like( qr/\n\$main::prt_fmt = "8>i<N>p<U>t<2"\n/, qq{"prt_fmt" is recognized correctly} );
    $cmd->stdout_like( qr/\n81>i<N>p<U>t<92\n/, qq{Correct output} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '1>I<n>n<P>N<u>T<s>U<b>9' | $FILLCMD 8 - 2 -d} );
    $cmd->exit_is_num( 0, "Internal Special Tokens" );
    $cmd->stdout_like( qr/\n\$main::prt_fmt = "8>i<N>p<U>t<2"\n/, qq{"prt_fmt" is recognized correctly} );
    $cmd->stdout_like( qr/\n81>I<n>n<P>N<u>T<s>U<b>92\n/, qq{Correct output} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo '1>I<n>n<P>N<u>T<g>S<u>B<9' | $FILLCMD 8 - 2 -d} );
    $cmd->exit_is_num( 0, "Internal Special Tokens" );
    $cmd->stdout_like( qr/\n\$main::prt_fmt = "8>i<N>p<U>t<2"\n/, qq{"prt_fmt" is recognized correctly} );
    $cmd->stdout_like( qr/\n81>I<n>n<P>N<u>T<g>S<u>B<92\n/, qq{Correct output} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );
};

subtest qq{Control characters} => sub{
    $cmd = Test::Command->new( cmd => qq{$FILLCMD } . q{-3 1:1 '\n' 11:1} );
    $cmd->exit_is_num( 0, qq{"\\n" is support (New Line)} );
    $cmd->stdout_is_eq( "1\n11\n2\n12\n3\n13\n", qq{Supports "\\n"} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$FILLCMD } . q{-3 1:1 '\t' 21:1} );
    $cmd->exit_is_num( 0, qq{"\\t" is support (Tab)} );
    $cmd->stdout_is_eq( "1\t21\n2\t22\n3\t23\n", qq{Supports "\\t"} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$FILLCMD } . q{-3 1:1 '\r' 31:1} );
    $cmd->exit_is_num( 0, qq{"\\r" is NOT support (Carriage Return)} );
    $cmd->stdout_is_eq( "1\\r31\n2\\r32\n3\\r33\n", qq{"\\r" is not support} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$FILLCMD } . q{-3 1:1 '\f' 41:1} );
    $cmd->exit_is_num( 0, qq{"\\f" is NOT support (Form Feed)} );
    $cmd->stdout_is_eq( "1\\f41\n2\\f42\n3\\f43\n", qq{"\\f" is not support} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$FILLCMD } . q{-3 1:1 '\a ' 51:1} );
    $cmd->exit_is_num( 0, qq{"\\a" is support (Alarm)} );
    $cmd->stdout_is_eq( "1\a 51\n2\a 52\n3\a 53\n", qq{Supports "\\a"} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$FILLCMD } . q{-3 1:1 '\e' 61:1} );
    $cmd->exit_is_num( 0, qq{"\\e" is NOT support (Escape)} );
    $cmd->stdout_is_eq( "1\\e61\n2\\e62\n3\\e63\n", qq{"\\e" is not support} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );
};

subtest qq{Escaping the "%" symbol} => sub{
    $cmd = Test::Command->new( cmd => qq{$FILLCMD -3 'usage rate: %%0:1%%%.'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( "usage rate: 0%.\nusage rate: 1%.\nusage rate: 2%.\n", qq{Escaping the "%" symbol} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt "123\n456" | $FILLCMD 01:1 '-%%-%%-%%-' 101:1} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( "01-123-%%-101\n02-456-%%-102\n", "Replace the first match." );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt "123\n456" | $FILLCMD '%%01:1%%-%%-' - '-%%101:1%%'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( "01-%%-123-101\n02-%%-456-102\n", "Replace the first match." );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );
};

subtest qq{<<SUB<..%..>SUB>>} => sub{
    $cmd = Test::Command->new( cmd => qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | $FILLCMD } . q{'mv "%%-%%" "<<SUB<\.[^\.]+$>%<.%%01:1%%>SUB>>"'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "20170930141640_0774.MP4" "20170930141640_0774.01"\nmv "20170930141640_0775.MP4" "20170930141640_0775.02"\nmv "20170930141640_0776.MP4" "20170930141640_0776.03"\n}, qq{The counter can be inserted.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | $FILLCMD } . q{'mv "%%-%%" "<<SUB<\.([^\.]+)$>%<_%%01:1%%.$1>SUB>>"'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "20170930141640_0774.MP4" "20170930141640_0774_01.MP4"\nmv "20170930141640_0775.MP4" "20170930141640_0775_02.MP4"\nmv "20170930141640_0776.MP4" "20170930141640_0776_03.MP4"\n}, qq{The counter can be inserted.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | $FILLCMD } . q{'<<SUB<^((.+)\.([^\.]+))$>%<mv "$1" "$2_%%01:1%%.$3">SUB>>'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "20170930141640_0774.MP4" "20170930141640_0774_01.MP4"\nmv "20170930141640_0775.MP4" "20170930141640_0775_02.MP4"\nmv "20170930141640_0776.MP4" "20170930141640_0776_03.MP4"\n}, qq{The counter can be inserted.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | $FILLCMD } . q{'mv "' - '<<SUB<^(\d{4})(\d{2})(\d{2})(.*)\.([^\.]+)$>%<" "$1-$2-$3_$4_%%01:1%%.$5">SUB>>'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "20170930141640_0774.MP4" "2017-09-30_141640_0774_01.MP4"\nmv "20170930141640_0775.MP4" "2017-09-30_141640_0775_02.MP4"\nmv "20170930141640_0776.MP4" "2017-09-30_141640_0776_03.MP4"\n}, qq{The counter can be inserted.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | $FILLCMD } . q{'mv "' - '<<SUB<^\d{4}\d{2}\d{2}.*\.[^\.]+$>%<" "$1-$2-$3_$4_%%01:1%%.$5">SUB>>'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "20170930141640_0774.MP4" "\$1-\$2-\$3_\$4_01.\$5"\nmv "20170930141640_0775.MP4" "\$1-\$2-\$3_\$4_02.\$5"\nmv "20170930141640_0776.MP4" "\$1-\$2-\$3_\$4_03.\$5"\n}, q{"$N" definition forgotten. Cannot be expanded.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | $FILLCMD } . q{'<<SUB<^(\d{4})(\d{2})(\d{2})(.*)\.([^\.]+)$>%<"$1-$2-$3_$4_%%01:1%%.$5" "%%01:1%%_$1-$2-$3_$4.$5">SUB>>'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{"2017-09-30_141640_0774_01.MP4" "01_\$1-\$2-\$3_\$4.\$5"\n"2017-09-30_141640_0775_02.MP4" "02_\$1-\$2-\$3_\$4.\$5"\n"2017-09-30_141640_0776_03.MP4" "03_\$1-\$2-\$3_\$4.\$5"\n}, q{No global match} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt 'Makefile\nREADME.md\nauth-cram-md5\ncheck_header_file_dependencies.sh' | $FILLCMD } . q{'mv "%%-%%" "<<SUB<\.([^\.]+)$>%<_%%01:1%%.$1>SUB>>"'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "Makefile" "Makefile"\nmv "README.md" "README_02.md"\nmv "auth-cram-md5" "auth-cram-md5"\nmv "check_header_file_dependencies.sh" "check_header_file_dependencies_04.sh"\n}, qq{Counters are added only to files with extensions.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt 'Makefile\nREADME.md\nauth-cram-md5\ncheck_header_file_dependencies.sh' | $FILLCMD } . q{'<<SUB<(e)>%<E$1E>SUB>>'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{MakEeEfile\nREADME.md\nauth-cram-md5\nchEeEck_header_file_dependencies.sh\n}, qq{Only the first matched part is replaced.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo 'OPQRSTUOPQRSTU' | $FILLCMD '9<<SUB<P>%<u>SUB>>1'} );
    $cmd->exit_is_num( 0, "Ability to recognize delimiters within macros" );
    $cmd->stdout_is_eq( "9OuQRSTUOPQRSTU1\n", qq{The SUB() macro is successful.} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );
};

subtest qq{<<GSUB<..%..>GSUB>>} => sub{
    $cmd = Test::Command->new( cmd => qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | $FILLCMD } . q{'mv "%%-%%" "<<GSUB<\.[^\.]+$>%<.%%01:1%%>GSUB>>"'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "20170930141640_0774.MP4" "20170930141640_0774.01"\nmv "20170930141640_0775.MP4" "20170930141640_0775.02"\nmv "20170930141640_0776.MP4" "20170930141640_0776.03"\n}, qq{The counter can be inserted.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | $FILLCMD } . q{'mv "%%-%%" "<<GSUB<\.([^\.]+)$>%<_%%01:1%%.$1>GSUB>>"'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "20170930141640_0774.MP4" "20170930141640_0774_01.MP4"\nmv "20170930141640_0775.MP4" "20170930141640_0775_02.MP4"\nmv "20170930141640_0776.MP4" "20170930141640_0776_03.MP4"\n}, qq{The counter can be inserted.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | $FILLCMD } . q{'<<GSUB<^((.+)\.([^\.]+))$>%<mv "$1" "$2_%%01:1%%.$3">GSUB>>'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "20170930141640_0774.MP4" "20170930141640_0774_01.MP4"\nmv "20170930141640_0775.MP4" "20170930141640_0775_02.MP4"\nmv "20170930141640_0776.MP4" "20170930141640_0776_03.MP4"\n}, qq{The counter can be inserted.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | $FILLCMD } . q{'mv "' - '<<GSUB<^(\d{4})(\d{2})(\d{2})(.*)\.([^\.]+)$>%<" "$1-$2-$3_$4_%%01:1%%.$5">GSUB>>'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "20170930141640_0774.MP4" "2017-09-30_141640_0774_01.MP4"\nmv "20170930141640_0775.MP4" "2017-09-30_141640_0775_02.MP4"\nmv "20170930141640_0776.MP4" "2017-09-30_141640_0776_03.MP4"\n}, qq{The counter can be inserted.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | $FILLCMD } . q{'mv "' - '<<GSUB<^\d{4}\d{2}\d{2}.*\.[^\.]+$>%<" "$1-$2-$3_$4_%%01:1%%.$5">GSUB>>'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "20170930141640_0774.MP4" "\$1-\$2-\$3_\$4_01.\$5"\nmv "20170930141640_0775.MP4" "\$1-\$2-\$3_\$4_02.\$5"\nmv "20170930141640_0776.MP4" "\$1-\$2-\$3_\$4_03.\$5"\n}, q{"$N" definition forgotten. Cannot be expanded.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt '20170930141640_0774.MP4\n20170930141640_0775.MP4\n20170930141640_0776.MP4' | $FILLCMD } . q{'<<GSUB<^(\d{4})(\d{2})(\d{2})(.*)\.([^\.]+)$>%<"$1-$2-$3_$4_%%01:1%%.$5" "%%01:1%%_$1-$2-$3_$4.$5">GSUB>>'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{"2017-09-30_141640_0774_01.MP4" "01_2017-09-30_141640_0774.MP4"\n"2017-09-30_141640_0775_02.MP4" "02_2017-09-30_141640_0775.MP4"\n"2017-09-30_141640_0776_03.MP4" "03_2017-09-30_141640_0776.MP4"\n}, q{Global match} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt 'Makefile\nREADME.md\nauth-cram-md5\ncheck_header_file_dependencies.sh' | $FILLCMD } . q{'mv "%%-%%" "<<GSUB<\.([^\.]+)$>%<_%%01:1%%.$1>GSUB>>"'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{mv "Makefile" "Makefile"\nmv "README.md" "README_02.md"\nmv "auth-cram-md5" "auth-cram-md5"\nmv "check_header_file_dependencies.sh" "check_header_file_dependencies_04.sh"\n}, qq{Counters are added only to files with extensions.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt 'Makefile\nREADME.md\nauth-cram-md5\ncheck_header_file_dependencies.sh' | $FILLCMD } . q{'<<GSUB<(e)>%<E$1E>GSUB>>'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( qq{MakEeEfilEeE\nREADME.md\nauth-cram-md5\nchEeEck_hEeEadEeEr_filEeE_dEeEpEeEndEeEnciEeEs.sh\n}, qq{All matches are replaced.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{echo 'OPQRSTUOPQRSTU' | $FILLCMD '9<<GSUB<P>%<u>GSUB>>1'} );
    $cmd->exit_is_num( 0, "Ability to recognize delimiters within macros" );
    $cmd->stdout_is_eq( "9OuQRSTUOuQRSTU1\n", qq{The GSUB() macro is successful.} );
    $cmd->stderr_is_eq( "", "stderr is silent" );
    undef( $cmd );
};

subtest qq{complicated} => sub{
    $cmd = Test::Command->new( cmd => qq{$FILLCMD -d3 '-%%1:1%%%%-%%-' - '-%%10:-1%%%%01:1%%'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
    $cmd->stdout_like( qr/-1%%-%%---1001\n-2%%-%%---0902\n-3%%-%%---0803\n/, qq{Escaping the "%" symbol} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$apppath/prt "123\n456" | $FILLCMD -d3 '-%%1:1%%%%-%%-' - '-%%10:-1%%%%01:1%%'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_like( qr/dbg:/, qq{"dPrint()", "dPrintf()" function} );
    $cmd->stdout_like( qr/-1123-123-1001\n-2456-456-0902\n/, qq{Escaping the "%" symbol} );
    $cmd->stderr_like( qr/^fill: STDIN=2, specified_cycle=3: /, "Show warning" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$FILLCMD -3 '%d%%1:3%%%d'} );
    $cmd->exit_is_num( 0, "exit status is 0" );
    $cmd->stdout_is_eq( "%d1%d\n%d4%d\n%d7%d\n", qq{Don't be fooled by "%d"} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{cat "$apppath/../fill" | $FILLCMD 0001:1 ' ' -} );
    $cmd->exit_is_num( 0, "A file containing special tokens." );
    $cmd->stdout_like( qr/ =cut$/, qq{It can be displayed to the end.} );
    $cmd->stderr_is_eq( qq{}, "stderr is silent" );
    undef( $cmd );
};

done_testing;

if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    $develCoverStatus=`cover`;
}
