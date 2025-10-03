#!/bin/sh
################################################################################
## build_script.sh -- A script that describes the build steps
##
## - A script describing the build steps in an environment
##   that uses 'autotools' and 'custom scripts that generate autotools input files'.
##
## - $Revision: 1.3 $
##
## - Author: 2025, tomyama
## - Intended primarily for personal use, but BSD license permits redistribution.
##
## BSD 2-Clause License:
## Copyright (c) 2025, tomyama
## All rights reserved.
################################################################################

sh_main()
{
    sh_init

    if [ "$1" = '-h' -o "$1" = '--help' ]; then
        echo "build_script.sh -- A script that describes the build steps"
        echo ""
        echo "A script describing the build steps in an environment"
        echo "that uses 'autotools' and 'custom scripts that generate autotools input files.'"
        exit 0
    elif [ "$1" = '-v' -o "$1" = '--version' ]; then
        echo "$appname - ($version)"
        exit 0
    fi

    configure_opts=''
    if [ "$TERMUX_VERSION" != '' ]; then
        configure_opts="--bindir=/data/data/com.termux/files/usr/local/bin"
    fi

    force_update=0
    if [ "$1" != '' ]; then
        force_update=1
    fi

    cd "$apppath/../"

    sh_exec ./tools/gen_autotools_acam.pl
    the_file_was_updated=$?

    need_configure=0
    if [ $the_file_was_updated -eq 0 -o $force_update -ne 0 ]; then
        echo -e "\nRun autotools."
        sh_exec aclocal && \
        sh_exec autoconf && \
        sh_exec automake --add-missing --copy
        if [ $? -eq 0 ]; then
            need_configure=1
        fi
    else
        echo -e "\nSkip running autotools."
    fi

    if [ ! -f 'Makefile' -o $force_update -ne 0 -o $need_configure -ne 0 ]; then
        sh_exec ./configure $configure_opts
        if [ $? -ne 0 ]; then
            echo "$0: error: exit" 1>&2
            exit 1
        fi
    fi

    sh_exec make check && \
    sh_exec make dist
    dist_status=$?

    if [ $dist_status -eq 0 ]; then
        distribution_archive=`sh_getDistributionArchiveName`
        if [ -f "$distribution_archive" ]; then
            echo
            echo "distribution_archive = \"$distribution_archive\""
            gzip -dc "$distribution_archive" | tar tvf -

            mv -f "$distribution_archive" ..
        else
            echo "$0: $distribution_archive: archive not found" 1>&2
        fi
    fi

    echo
    cd -

    return $dist_status
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

sh_exec()
{
    echo -e '\n$' "$@"
    "$@"
    status_code=$?
    echo "exit_status=$status_code"
#    if [ $status_code -ne 0 ]; then
#        echo "$0: exit" 1>&2
#        exit $?
#    fi
    return $status_code
}

sh_getDistributionArchiveName()
{
  cat configure.ac | awk '
    /^AC_INIT/{
      args = getArgs( $0 );
      split( args, ARGS, ", *" );
      #print( ARGS[ 1 ] );
      tarballname = getValue( ARGS[ 1 ] ) "-" getValue( ARGS[ 2 ] ) ".tar.gz";
      print( tarballname );
    }
    function getArgs( str ){
      args = gensub( "^AC_INIT *\\( *(.*) *\\) *$", "\\1", "1", str );
      #print( args );
      return args;
    }
    function getValue( str ){
      val = gensub( "^ *\\[(.*)\\] *$", "\\1", "1", str );
      #print( val );
      return val;
    }
  '
}

sh_main "$@"
exit $?
