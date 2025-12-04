#!/bin/sh

WITH_PERL_COVERAGE=1; export WITH_PERL_COVERAGE
test_summary='./test_summary.txt'

sh_main()
{
    sh_init "$@"

    beg=`sh_get_epoch`

    retval=0

    cd "$apppath/../"

    if [ "$WITH_PERL_COVERAGE" != '' ]; then
        if [ "$WITH_PERL_COVERAGE_OWNER" = '' ]; then
            WITH_PERL_COVERAGE_OWNER=$$; export WITH_PERL_COVERAGE_OWNER

            which cover 1>/dev/null 2>&1
            bUnavailableCover=$?;
            if [ $bUnavailableCover -ne 0 ]; then
                echo "$0: warn: \"cover\" command not found: \$WITH_PERL_COVERAGE: ignore" 1>&2
                unset WITH_PERL_COVERAGE
                unset WITH_PERL_COVERAGE_OWNER
            else
                cover -delete
            fi
        fi
    fi

    targets=''
    echo '' >"$test_summary"
    for fi in *; do
        if ! is_it_executable_file "$fi"; then
            continue
        fi
        bname="`basename \"$fi\"`"
        tname="tests/$bname.test.pl"
        if ! is_it_executable_file "$tname"; then
            continue
        fi
        #echo "F: $bname"
        targets="$targets $bname"

        #"$apppath/prt" -e "$bname: "
        printf '%-6s: ' "$bname"

        test_log="$tname.log"
        "./$tname" >"$test_log"
        exit_status=$?
        res='PASS'
        if [ $exit_status -ne 0 ]; then
            res='FAIL'
            retval=`expr "$retval" '+' '1'`
        fi
        echo "$res: exit_status=$exit_status: $test_log"
        printf "%-6s: $res: exit_status=$exit_status: $test_log\n" "$bname" >>"$test_summary"
    done

    if [ "$WITH_PERL_COVERAGE" != '' ]; then
        if [ "$WITH_PERL_COVERAGE_OWNER" = "$$" ]; then
            cover | sh_summary_cov_filter "$targets" | tee -a "$test_summary"
            sh_edit_coverage_html "$apppath" 'cover_db/coverage.html'
        fi
    fi

    end=`sh_get_epoch`
    sh_prt_timestamp "$beg" "$end" | tee -a "$test_summary"

    return $retval
}

## script setup
sh_init()
{
    di_work="`pwd`"
    appname="`basename \"$0\"`"
    di_tmp="`dirname  \"$0\"`"
    cd "$di_tmp/"; apppath="`pwd`"; cd "$di_work/"
    unset di_tmp
    version=`grep '$[R]evision' "$apppath/$appname" | \
        sed 's/^.*$R/R/' | sed 's/ *\$$//'`
}

is_it_executable_file()
{
    #echo "Check: $1"
    if [ ! -f "$1" ]; then
        return 1
    fi
    if [ ! -r "$1" ]; then
        return 1
    fi
    if [ ! -x "$1" ]; then
        return 1
    fi
    return 0
}

sh_summary_cov_filter()
{
    perl -e '
        my $targets = shift( @ARGV );
        $targets =~ s/^\s+//;
        my @files = split( /[ \t\n]+/, $targets );

        my %sz;
        $sz{Total} = 0;
        for my $targ( @files ){
            $sz{$targ} = `stat --format="%s" $targ` + 0;
            #print( qq{$targ: "$sz{$targ}"\n} );
            $sz{Total} += $sz{$targ};
        }

        my $counter = 0;
        while( <STDIN> ){
            my $line = $_;
            $line =~ s/\r?\n$//o;
            if( $line eq "----- ------ ------ ------ ------ ------ ------ ------" ){
                $counter++;
                $line .= "  ------ ------";
            }
            if( $counter == 3 ){
                $counter = 0;
            }elsif( $counter > 0 ){
                my @field = split( /\s+/, $line );
                if( $field[ 0 ] eq 'File' ){
                    $line = "$line    size      %";
                }elsif( $field[ 0 ] eq 'Total' ){
                    $line = sprintf( qq{$line  %6d  100.0}, $sz{ 'Total' } );
                }elsif( exists( $sz{ $field[ 0 ] } ) ){
                    $line = sprintf( qq{$line  %6d  %5.1f},
                        $sz{ $field[ 0 ] }, $sz{ $field[ 0 ] } * 100 / $sz{Total} );
                }
            }
            print( qq{$line\n} );
        }
    ' "$1"
}

sh_edit_coverage_html()
{
    perl -e '
        my $apppath = shift( @ARGV );
        my $target = shift( @ARGV );
        my $proj_name = $apppath;
        $proj_name =~ s!^.*/([^/]+)/tests$!$1!;
        #print( qq{ok: $proj_name, $target\n} );

        if( ! -f "$target" ){
            die( "$target: file not found.\n " );
        }elsif( ! -r "$target" ){
            die( "$target: unable to read file.\n" );
        }

        open( COVHTML_R, "<", "$target" ) || die( "$target: could not open file.: $!" );
        my $buff = "";
        while( <COVHTML_R> ){
            my $line = $_;
            $line =~ s!\r?\n$!!o;

            if( $line =~ s!/\S+($proj_name/cover_db)!$1!go ){
                print( qq{edit: $1\n} );
            }

            $buff .= $line . "\n";
        }
        close( COVHTML_R );

        #my $dist = "$target.new.html";
        my $dist = "$target";
        open( COVHTML_W, ">", "$dist" ) || die( "$dist: could not open file: $!" );
        print COVHTML_W ( $buff );
        close( COVHTML_W );
    ' "$@"
}

sh_get_epoch()
{
    perl -e 'print( time() );'
}
sh_prt_timestamp()
{
    perl -e '
        my $beg = shift( @ARGV );
        my $end = shift( @ARGV );
        my $elaps = $end - $beg;
        #print( qq{\$beg="$beg"\n} );
        &prt_time( "Start", $beg );
        &prt_time( "  End", $end );

        my $S = $elaps % 60;
        $elaps = ( $elaps - $S ) / 60;
        my $M = $elaps % 60;
        my $H = ( $elaps - $M ) / 60;
        printf( qq{Elaps:            %02d:%02d:%02d\n}, $H, $M, $S );

        sub prt_time()
        {
            my $l = shift( @_ );
            my $t = shift( @_ );
            my( $S, $M, $H, $d, $m, $Y ) = localtime( $t );
            $Y += 1900;
            $m += 1;
            printf( qq{$l: %04d-%02d-%02d %02d:%02d:%02d\n}, $Y, $m, $d, $H, $M, $S );
        }
    ' "$@"
}

sh_main "$@"
exit $?
