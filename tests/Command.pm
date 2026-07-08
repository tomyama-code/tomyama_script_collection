package tests::Command;
use strict;
use warnings;

use File::Basename; # dirname()
use Cwd 'getcwd';   # getcwd()

## Test::More was first released with perl v5.6.2
use Test::More;     # subtest(), done_testing()
### Test2::V0 was first released with perl v5.39.4
#use Test2::V0 -no_utf8 => 1;    # テストフレームワークとUTF-8プラグインの読み込み

## not in CORE: Begin
use Capture::Tiny qw(capture);
## not in CORE: End

my $test_beg_epoch = 0;
my $test_end_epoch = 0;

sub new( $$ )
{
    my( $class, $cmd ) = @_;
    #printf( qq{\$cmd="$cmd"\n} );

    if( !defined( $ENV{TEST_TARGET_CMD} ) ){
        die( qq{undefined \$ENV{TEST_TARGET_CMD}\n} );
    }

    my $pseudo_cmd = $cmd;
    $pseudo_cmd =~ s!\./$ENV{TEST_TARGET_CMD}!$ENV{PSEUDO_COMMAND}!go;
    if( $cmd eq $pseudo_cmd ){
        die( qq{The command to be tested is not included.\n} );
    }
    note( qq{$cmd\n} );

    my $exit_code = 0;
    my( $stdout, $stderr ) = capture{
        $exit_code = system( $pseudo_cmd );
        $exit_code >>= 8;
    };
#    printf( qq{STDOUT="%s"\n}, $stdout );
#    printf( qq{STDERR="%s"\n}, $stderr );
#    printf( qq{exit_code="%d"\n}, $exit_code );

    my $self = {
        cmd        => $cmd,
        pseudo_cmd => $pseudo_cmd,
        stdout => $stdout,
        stderr => $stderr,
        exit_code => $exit_code,
    };
    bless( $self, $class );     # クラス名を関連付け

    return $self;
}

sub dump( $ )
{
    my( $self ) = @_;
    printf( qq{cmd="%s"\n}, $self->{cmd} );
    printf( qq{STDOUT="%s"\n}, $self->{stdout} );
    printf( qq{STDERR="%s"\n}, $self->{stderr} );
    printf( qq{exit_code="%d"\n}, $self->{exit_code} );
}

sub exit_is( $$;$ )
{
    my( $self, $expected, $msg ) = @_;
    $msg = "exit code is $expected" if( !defined( $msg ) );
    is( $self->{exit_code}, $expected, $msg );
}

sub exit_isnt( $$;$ )
{
    my( $self, $expected, $msg ) = @_;
    $msg = "exit code is not $expected" if( !defined( $msg ) );
    isnt( $self->{exit_code}, $expected, $msg );
}

sub stdout_is( $$;$ )
{
    my( $self, $expected, $msg ) = @_;
    if( !defined( $msg ) ){
        $msg = "STDOUT matches";
        if( $expected eq '' ){
            $msg = "STDOUT is silent";
        }
    }
    is( $self->{stdout}, $expected, $msg );
}

sub stderr_is( $$;$ )
{
    my( $self, $expected, $msg ) = @_;
    if( !defined( $msg ) ){
        $msg = "STDERR matches";
        if( $expected eq '' ){
            $msg = "STDERR is silent";
        }
    }
    is( $self->{stderr}, $expected, $msg );
}

sub stdout_like( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "STDOUT matches pattern" if( !defined( $msg ) );
    like($self->{stdout}, $pattern, $msg );
}

sub stderr_like( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "STDERR matches pattern" if( !defined( $msg ) );
    like($self->{stderr}, $pattern, $msg );
}

sub _SetTargetCommand( $ )
{
    my( $testfilename ) = @_;
    my $cmd = $testfilename;
    $cmd =~ s!^.*/(.+)\.test\.pl$!$1!o;
    $ENV{TEST_TARGET_CMD} = $cmd;
    $ENV{PSEUDO_COMMAND} = './tests/cmd_wrapper';
    #print( qq{\$ENV{TEST_TARGET_CMD} = "$ENV{TEST_TARGET_CMD}"\n} );

    # カレントディレクトリを project root に強制する
    my $apppath = dirname( $testfilename );
    chdir( "$apppath/../" );
    my $cur_dir = getcwd();
    #print( qq{CHDIR: "$cur_dir"\n} );
}

sub TestPreProc( $@ )
{
    my( $testfilename, @args ) = @_;

    $test_beg_epoch = time();

    &_SetTargetCommand( $testfilename );

    $ENV{WITH_PERL_COVERAGE} = 1 if( scalar( @args ) > 0 );

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
                print( `cover -delete` );
            }
        }
    }
}

sub TestPostProc( $ )
{
    my( $name ) = @_;
    done_testing();

    if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
        if( $ENV{WITH_PERL_COVERAGE_OWNER} eq $$ ){
            print( `cover` );
        }
    }

    $test_end_epoch = time();
    &DisplayElaps( $test_beg_epoch, $test_end_epoch, $name );
}

sub DisplayElaps( $$$ )
{
    my( $beg_epoch, $end_epoch, $name ) = @_;
    &DisplayTheDateAndTime( $name, 'Begin', &StrDateAndTime( $beg_epoch ) );
    &DisplayTheDateAndTime( $name, '  End', &StrDateAndTime( $end_epoch ) );
    my $elaps = $end_epoch - $beg_epoch;
    my $sec = $elaps % 60;
    my $remain = $elaps - $sec;
    my $minute = ( $remain % 3600 ) / 60;
    $remain -= ( $minute * 60 );
    my $hour = $remain / 3600;
    &DisplayTheDateAndTime( $name, 'Elaps',
        sprintf( qq{           %02d:%02d:%02d}, $hour, $minute, $sec ) );
}

sub DisplayTheDateAndTime( $$$ )
{
    my( $name, $label, $dt ) = @_;
    printf( qq{$name test: $label: %s\n}, $dt );
}

sub StrDateAndTime( $ )
{
    my( $epoch ) = @_;
    my( $sec, $minute, $hour, $mday, $month, $year ) = localtime( $epoch );
    $year += 1900; # localtime/gmtimeは1900年からのオフセット。エポック秒のゼロは1970年。ANSI Cと同じ。
    $month += 1;
    sprintf( qq{%04d-%02d-%02d %02d:%02d:%02d},
        $year, $month, $mday, $hour, $minute, $sec );
}

1;

__END__

