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

$ENV{ 'TEST_TARGET_CMD' } = 'domsort';

#$ENV{WITH_PERL_COVERAGE} = 1;
$ENV{WITH_PERL_COVERAGE} = 1 if( scalar( @ARGV ) > 0 );

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
my $TFILE = "./tests/address.tab";              # shell: TFILE="./tests/address.tab"
my $TF_FAKE_IP = "./tests/addr_fake_ip.txt";    # shell: TF_FAKE_IP="./tests/addr_fake_ip.txt"

subtest qq{Error path} => sub{

    $cmd = Test::Command->new( cmd => qq{$TARGCMD "NON-EXISTENT-FILES"} );
    $cmd->exit_isnt_num( 0, qq{./domsort "NON-EXISTENT-FILES"} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_like( qr/^domsort: NON-EXISTENT-FILES: cannot open file: /, q{Open Error} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD "$TFILE" -k} );
    $cmd->exit_isnt_num( 0, qq{./domsort "$TFILE" -k} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_is_eq( qq{Usage: domsort -k <column> <file...>\n} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -k "$TFILE"} );
    $cmd->exit_isnt_num( 0, qq{./domsort -k "$TFILE"} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_is_eq( qq{"./tests/address.tab" is not a number.\n} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD "$TFILE" -t} );
    $cmd->exit_isnt_num( 0, qq{./domsort "$TFILE" -t} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_is_eq( qq{Usage: domsort -t <delimiter> <file...>\n} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD "$TFILE" -k 6} );
    $cmd->exit_isnt_num( 0, qq{./domsort "$TFILE" -k 6} );
    $cmd->stdout_is_eq( qq{}, qq{STDOUT is silent.} );
    $cmd->stderr_is_eq( qq{"1	12.34.56.90	w.x.y.z.co.jp	user1\@w.x.y.z.co.jp	03-1234-5678": There is no data in the 6 column.\n}, qq{Field specification is out of range} );
    undef( $cmd );

};

subtest qq{Normal} => sub{

    #$ ./domsort "./tests/address.tab"
    #1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
    #10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
    #2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
    #3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
    #4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
    #5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
    #6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
    #7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
    #8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
    #9   12.34.55.9   abc.com           user9@abc.com  044-1234-765
    $cmd = Test::Command->new( cmd => qq{$TARGCMD "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{1\n10\n2\n3\n4\n5\n6\n7\n8\n9\n}, "Sort by number" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    #$ ./domsort -k 2 "$TFILE"
    #10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
    #6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
    #5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
    #4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
    #9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
    #8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
    #7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
    #3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
    #2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
    #1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -k 2 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -k 2 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{10\n6\n5\n4\n9\n8\n7\n3\n2\n1\n}, "Sort by IP Address" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    #$ ./domsort -k 3 "$TFILE"
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
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -k 3 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -k 3 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{9\n7\n10\n8\n5\n3\n4\n6\n1\n2\n}, "Sort by Domain Name" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    #$ ./domsort -k 4 "$TFILE"
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
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -k 4 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -k 4 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{9\n7\n10\n8\n5\n3\n4\n6\n1\n2\n}, "Sort by Mail Address" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    #$ ./domsort -k 5 "$TFILE"
    #4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
    #1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
    #7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
    #3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
    #10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
    #8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
    #5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
    #2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
    #9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
    #6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -k 5 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -k 5 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{4\n1\n7\n3\n10\n8\n5\n2\n9\n6\n}, "Sort by phone number" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

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
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -dk 5 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -dk 5 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{4\n1\n7\n5\n3\n2\n9\n10\n8\n6\n}, "Sort by phone number ( with -d option )" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{-f  Force case sensitivity.} => sub{

    #$ ./domsort -fk 3 "$TFILE"
    #7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
    #10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
    #3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
    #6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
    #2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
    #5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
    #9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
    #8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
    #4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
    #1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -fk 3 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -fk 3 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{7\n10\n3\n6\n2\n5\n9\n8\n4\n1\n}, "Case-sensitive sorting by domain name" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -rfk 3 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -rfk 3 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{1\n4\n8\n9\n5\n2\n6\n3\n10\n7\n}, "Case-sensitive sorting by domain name (reverse order)" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    #$ ./domsort -fk 4 "$TFILE"
    #7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
    #10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
    #3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
    #6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
    #2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
    #5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
    #9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
    #8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
    #4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
    #1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -fk 4 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -fk 4 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{7\n10\n3\n6\n2\n5\n9\n8\n4\n1\n}, "Case-sensitive sorting by mail address" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -rfk 4 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -rfk 4 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{1\n4\n8\n9\n5\n2\n6\n3\n10\n7\n}, "Case-sensitive sorting by mail address (reverse order)" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD "$TF_FAKE_IP"} );
    $cmd->exit_is_num( 0, qq{./domsort "$TF_FAKE_IP"} );
    $cmd->stdout_is_eq( qq{1.2.256.4\n1.2.3.256\n1.256.3.4\n256.2.3.4\n}, qq{STDOUT is silent.} );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{-r  Reverse the result of comparisons.} => sub{

    #$ ./domsort -r "./tests/address.tab"
    #9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
    #8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
    #7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
    #6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
    #5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
    #4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
    #3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
    #2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
    #10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
    #1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -r "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -r "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{9\n8\n7\n6\n5\n4\n3\n2\n10\n1\n}, "Sort by number (reverse order)" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    #$ ./domsort -rk 2 "$TFILE"
    #1       12.34.56.90     w.x.y.z.co.jp   user1@w.x.y.z.co.jp     03-1234-5678
    #2       12.34.56.78     W.X.Y.Z.CO.JP   user2@W.X.Y.Z.CO.JP     044-1234-568
    #3       12.34.56.9      W.X.Y.Z.COM     user3@W.X.Y.Z.COM       044-123-4567
    #7       12.34.55.90     FREEMAIL.ABC.COM        user7@FREEMAIL.ABC.COM  03-1234-8765
    #8       12.34.55.78     mail1.abc.com   user8@mail1.abc.com     044-123-7654
    #9       12.34.55.9      abc.com user9@abc.com   044-1234-765
    #4       12.34.8.90      x.y.z.co.jp     user4@x.y.z.co.jp       0123-111-222
    #5       12.34.8.78      X.Y.Z.com       user5@X.Y.Z.com 044-1234-566
    #6       12.34.8.9       X.Y.Z.CO.JP     user6@X.Y.Z.CO.JP       08-03-1234-5678
    #10      12.34.6.100     MAIL1.ABC.COM   USER10@MAIL1.ABC.COM    044-123-5678
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -rk 2 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -rk 2 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{1\n2\n3\n7\n8\n9\n4\n5\n6\n10\n}, "Sort by IP Address (reverse order)" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    #$ ./domsort -rk 3 "$TFILE"
    #2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
    #1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
    #6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
    #4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
    #3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
    #5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
    #8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
    #10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
    #7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
    #9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -rk 3 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -rk 3 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{2\n1\n6\n4\n3\n5\n8\n10\n7\n9\n}, "Sort by Domain Name (reverse order)" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    #$ ./domsort -rk 4 "$TFILE"
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
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -rk 4 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -rk 4 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{2\n1\n6\n4\n3\n5\n8\n10\n7\n9\n}, "Sort by Mail Address (reverse order)" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    #$ ./domsort -rk 5 "$TFILE"
    #6       12.34.8.9       X.Y.Z.CO.JP     user6@X.Y.Z.CO.JP       08-03-1234-5678
    #9       12.34.55.9      abc.com user9@abc.com   044-1234-765
    #2       12.34.56.78     W.X.Y.Z.CO.JP   user2@W.X.Y.Z.CO.JP     044-1234-568
    #5       12.34.8.78      X.Y.Z.com       user5@X.Y.Z.com 044-1234-566
    #8       12.34.55.78     mail1.abc.com   user8@mail1.abc.com     044-123-7654
    #10      12.34.6.100     MAIL1.ABC.COM   USER10@MAIL1.ABC.COM    044-123-5678
    #3       12.34.56.9      W.X.Y.Z.COM     user3@W.X.Y.Z.COM       044-123-4567
    #7       12.34.55.90     FREEMAIL.ABC.COM        user7@FREEMAIL.ABC.COM  03-1234-8765
    #1       12.34.56.90     w.x.y.z.co.jp   user1@w.x.y.z.co.jp     03-1234-5678
    #4       12.34.8.90      x.y.z.co.jp     user4@x.y.z.co.jp       0123-111-222
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -rk 5 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -rk 5 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{6\n9\n2\n5\n8\n10\n3\n7\n1\n4\n}, "Sort by phone number (reverse order)" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    #$ ./domsort -drk 5 "$TFILE"
    #6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
    #8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
    #10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
    #9   12.34.55.9   abc.com           user9@abc.com           044-1234-765
    #2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
    #3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
    #5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
    #7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
    #1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
    #4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -drk 5 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -drk 5 "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{6\n8\n10\n9\n2\n3\n5\n7\n1\n4\n}, "Sort by phone number (reverse order) ( with -d option )" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{-t <SEP>} => sub{

    #$ ./domsort -t "\t" "./tests/address.tab"
    #1   12.34.56.90  w.x.y.z.co.jp     user1@w.x.y.z.co.jp     03-1234-5678
    #10  12.34.6.100  MAIL1.ABC.COM     USER10@MAIL1.ABC.COM    044-123-5678
    #2   12.34.56.78  W.X.Y.Z.CO.JP     user2@W.X.Y.Z.CO.JP     044-1234-568
    #3   12.34.56.9   W.X.Y.Z.COM       user3@W.X.Y.Z.COM       044-123-4567
    #4   12.34.8.90   x.y.z.co.jp       user4@x.y.z.co.jp       0123-111-222
    #5   12.34.8.78   X.Y.Z.com         user5@X.Y.Z.com         044-1234-566
    #6   12.34.8.9    X.Y.Z.CO.JP       user6@X.Y.Z.CO.JP       08-03-1234-5678
    #7   12.34.55.90  FREEMAIL.ABC.COM  user7@FREEMAIL.ABC.COM  03-1234-8765
    #8   12.34.55.78  mail1.abc.com     user8@mail1.abc.com     044-123-7654
    #9   12.34.55.9   abc.com           user9@abc.com  044-1234-765
    $cmd = Test::Command->new( cmd => qq{$TARGCMD -t "\t" "$TFILE" | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{./domsort -t "\t" "$TFILE" | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{1\n10\n2\n3\n4\n5\n6\n7\n8\n9\n}, "Sort by number" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{Input data from STDIN} => sub{

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
    $cmd = Test::Command->new( cmd => qq{cat "$TFILE" | $TARGCMD -k 3 | awk '{print(\$1)}'} );
    $cmd->exit_is_num( 0, qq{cat "$TFILE" | ./domsort -k 3 | awk '{print(\$1)}'} );
    $cmd->stdout_is_eq( qq{9\n7\n10\n8\n5\n3\n4\n6\n1\n2\n}, "Sort by Domain Name" );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{-h, --help} => sub{

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -h} );
    $cmd->exit_is_num( 0, qq{./domsort -h} );
    $cmd->stdout_like( qr/^Usage: domsort / );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --help} );
    $cmd->exit_is_num( 0, qq{./domsort --help} );
    $cmd->stdout_like( qr/^Usage: domsort / );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

subtest qq{-v, --version} => sub{

    $cmd = Test::Command->new( cmd => qq{$TARGCMD -v} );
    $cmd->exit_is_num( 0, qq{./domsort -v} );
    $cmd->stdout_like( qr/^Version: \d/ );
    $cmd->stdout_like( qr/\n   Perl: v\d/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

    $cmd = Test::Command->new( cmd => qq{$TARGCMD --version} );
    $cmd->exit_is_num( 0, qq{./domsort --version} );
    $cmd->stdout_like( qr/^Version: \d/ );
    $cmd->stdout_like( qr/\n   Perl: v\d/ );
    $cmd->stderr_is_eq( qq{}, qq{STDERR is silent.} );
    undef( $cmd );

};

done_testing();

if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
    if( $ENV{WITH_PERL_COVERAGE_OWNER} eq $$ ){
        $develCoverStatus=`cover`;
    }
}
