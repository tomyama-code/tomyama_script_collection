package tests::Runner;
use strict;
use warnings;

use File::Basename; # dirname()
#use Cwd 'getcwd';   # getcwd()

my $test_beg_epoch = 0;
my $test_end_epoch = 0;

sub _SetTargetCommand( $ )
{
    my( $testfilename ) = @_;
    my $cmd = $testfilename;
    $cmd =~ s!^.*/(.+)\.test\.pl$!$1!o;
    if( $cmd =~ m!\.pm$!o ){
        $ENV{TEST_TARGET_MDL} = $cmd;
        $ENV{TEST_TARGET_NAME} = $ENV{TEST_TARGET_MDL};
    }else{
        $ENV{TEST_TARGET_CMD} = $cmd;
        $ENV{TEST_TARGET_NAME} = $ENV{TEST_TARGET_CMD};
    }
    #print( qq{\$ENV{TEST_TARGET_NAME} = "$ENV{TEST_TARGET_NAME}"\n} );

    # カレントディレクトリを project root に強制する
    my $apppath = dirname( $testfilename );
    chdir( "$apppath/../" );
    #my $cur_dir = getcwd();
    #print( qq{CHDIR: "$cur_dir"\n} );
}

sub TestPreProc( $@ )
{
    my( $testfilename, @args ) = @_;

    $test_beg_epoch = time();

    &_SetTargetCommand( $testfilename );

    &_PrintTime( $ENV{TEST_TARGET_NAME}, 'Begin', &_FormatTime( $test_beg_epoch ) );

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
    &_ShowElapsed( $test_beg_epoch, $test_end_epoch, $name );
}

sub _ShowElapsed( $$$ )
{
    my( $beg_epoch, $end_epoch, $name ) = @_;
    &_PrintTime( $name, 'Begin', &_FormatTime( $beg_epoch ) );
    &_PrintTime( $name, '  End', &_FormatTime( $end_epoch ) );
    my $elaps = $end_epoch - $beg_epoch;
    my $sec = $elaps % 60;
    my $remain = $elaps - $sec;
    my $minute = ( $remain % 3600 ) / 60;
    $remain -= ( $minute * 60 );
    my $hour = $remain / 3600;
    &_PrintTime( $name, 'Elaps',
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

