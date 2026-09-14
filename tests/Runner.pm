package tests::Runner;
################################################################################
## - $Revision: 1.5 $
################################################################################

use strict;                         # first released with perl 5
use warnings;                       # first released with perl v5.6.0

use File::Basename qw();            # first released with perl 5
use POSIX qw();                     # first released with perl 5

my $test_beg_epoch = 0;
my $test_end_epoch = 0;

sub _SetTargetCommand( $ )
{
    my( $testfilename ) = @_;

    # カレントディレクトリを project root に強制する
    my $apppath = File::Basename::dirname( $testfilename );
    chdir( "$apppath/../" );

    my $cmd = $testfilename;
    $cmd =~ s!^.*/(.+)\.test\.pl$!$1!o;
    if( $cmd =~ m!^(.*)\.pm$!o ){
        $ENV{TEST_TARGET_MDL} = $cmd;
        my $mod_name = $1;
        $ENV{TEST_TARGET_NAME} = $ENV{TEST_TARGET_MDL};

        my $mod_ver = '';
        {
            require "./$ENV{TEST_TARGET_NAME}";
            $mod_ver = $mod_name->GetVersion();
        }
        $ENV{TEST_TARGET_VER} = $mod_ver;

    }else{
        $ENV{TEST_TARGET_CMD} = $cmd;
        $ENV{TEST_TARGET_NAME} = $ENV{TEST_TARGET_CMD};

        my $mod_ver = '';
        open( VERSION_STR, '-|', "./$ENV{TEST_TARGET_CMD}", '--version' ) ||
            die( qq{$ENV{TEST_TARGET_CMD}: could not execute: $!} );
        my @version_str = <VERSION_STR>;
        close( VERSION_STR );
        for my $line( @version_str ){
            $line =~ s/\r?\n$//o;
            if( $line =~ m/^Version: (.*)$/o ){
                $mod_ver = $1;
                last;
            }
        }
        $ENV{TEST_TARGET_VER} = $mod_ver;

    }
    #print( qq{\$ENV{TEST_TARGET_NAME} = "$ENV{TEST_TARGET_NAME}"\n} );
}

sub get_time_zone()
{
    return $ENV{TZ} if( defined( $ENV{TZ} ) );
    return undef;
}

sub change_tz_and_locale( ;$$ )
{
    my( $time_zone, $locale ) = @_;

    if( !defined( $time_zone ) ){
        delete( $ENV{TZ} );
    }else{
        $ENV{TZ} = $time_zone;
    }

    # PerlにTZ環境変数の変更を認識させるための命令
    # OSのCライブラリのタイムゾーンキャッシュをリフレッシュ
    POSIX::tzset();

    if( !defined( $locale ) ){
        $locale = 'C';
    }
    $ENV{LANG} = $locale;
    POSIX::setlocale( POSIX::LC_ALL, $locale );
}

sub TestPreProc( $@ )
{
    my( $testfilename, @args ) = @_;

    $test_beg_epoch = time();

    ## IANAタイムゾーンID
    ##   - https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
    ##   - $ timedatectl list-timezones --no-pager
    change_tz_and_locale( 'Asia/Tokyo', 'ja_JP.UTF-8' );
#    change_tz_and_locale();

    _SetTargetCommand( $testfilename );

    _PrintTime( $ENV{TEST_TARGET_NAME}, 'Begin', _FormatTime( $test_beg_epoch ) );

    print( qq{Perl Version: $^V, Test Target: $ENV{TEST_TARGET_VER}\n} );

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

        my $targ_path = "\Q$ENV{TEST_TARGET_NAME}\E";
        my $develcover_opt = "-MDevel::Cover=-silent,1,-ignore,.,-select,^$targ_path\$";
        $ENV{PERL5OPT} = $develcover_opt;
        print( qq{\$ENV{PERL5OPT}="$ENV{PERL5OPT}"\n} );
    }
}

sub TestPostProc( $ )
{
    my( $name ) = @_;

    if( defined( $ENV{WITH_PERL_COVERAGE} ) ){
        delete( $ENV{PERL5OPT} );

        if( $ENV{WITH_PERL_COVERAGE_OWNER} eq $$ ){
            print( `cover` );
        }
    }

    if( defined( $ENV{TEST_TARGET_MDL} ) ){
        delete( $ENV{TEST_TARGET_MDL} );
    }
    if( defined( $ENV{TEST_TARGET_CMD} ) ){
        delete( $ENV{TEST_TARGET_CMD} );
    }
    if( defined( $ENV{TEST_TARGET_NAME} ) ){
        delete( $ENV{TEST_TARGET_NAME} );
    }

    $test_end_epoch = time();
    _ShowElapsed( $test_beg_epoch, $test_end_epoch, $name );
}

sub _ShowElapsed( $$$ )
{
    my( $beg_epoch, $end_epoch, $name ) = @_;
    _PrintTime( $name, 'Begin', _FormatTime( $beg_epoch ) );
    _PrintTime( $name, '  End', _FormatTime( $end_epoch ) );
    my $elaps = $end_epoch - $beg_epoch;
    my $sec = $elaps % 60;
    my $remain = $elaps - $sec;
    my $minute = ( $remain % 3600 ) / 60;
    $remain -= ( $minute * 60 );
    my $hour = $remain / 3600;
    _PrintTime( $name, 'Elaps',
        sprintf( qq{           %02d:%02d:%02d}, $hour, $minute, $sec ) );
}

sub _PrintTime( $$$ )
{
    my( $name, $label, $dt ) = @_;
    printf( qq{$name test: $label: %s\n}, $dt );
}

sub _FormatTime( $ )
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

