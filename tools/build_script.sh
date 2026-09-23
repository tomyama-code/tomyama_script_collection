#!/bin/sh
################################################################################
## build_script.sh -- A script that describes the build steps
##
## - A script describing the build steps in an environment
##   that uses 'autotools' and 'custom scripts that generate autotools input files'.
##
## - $Revision: 1.10 $
##
## - Author: 2025-2026, tomyama
## - Intended primarily for personal use, but BSD license permits redistribution.
##
## BSD 2-Clause License:
## Copyright (c) 2025-2026, tomyama
## All rights reserved.
################################################################################

sh_main()
{
    sh_init

    if [ "$1" = '-h' -o "$1" = '--help' ]; then
        echo "NAME"
        echo "  $appname -- A script that describes the build steps"
        echo ""
        echo "VERSION"
        echo '  This document describes $Revision: 1.10 $.'
        echo ""
        echo "SYNOPSIS"
        echo "  ./tools/$appname"
        echo ""
        echo "DESCRIPTION"
        echo "  - A script describing the build procedure."
        echo "    - First, generate the 'autotools' input files..."
        echo "    - Then, run 'autotools'."
        echo "    - Build using the 'Makefile'."
        echo ""
        echo "SEE ALSO"
        echo "  - docs/Developer_Manual.md"
        echo ""
        echo "AUTHOR"
        echo "  2025-2026, tomyama"
        echo ""
        echo "LICENSE"
        echo "  BSD 2-Clause License"
        echo "  Copyright (c) 2025-2026, tomyama"
        exit 0
    elif [ "$1" = '-v' -o "$1" = '--version' ]; then
        echo "$appname - ($version)"
        exit 0
    fi

    configure_opts=''
    if [ "$TERMUX_VERSION" != '' ]; then
        ## Note:
        ##   SHELL   : Avoid using "dash".
        ##   --bindir: Termux has a unique directory structure.
        configure_opts="SHELL=/data/data/com.termux/files/usr/bin/bash --bindir=/data/data/com.termux/files/usr/local/bin"
    fi

    force_run_autotools=0
    if [ "$1" != '' ]; then
        force_run_autotools=1
        echo "\$force_run_autotools=$force_run_autotools"
    fi

    cd "$apppath/../"

    sh_exec ./tools/gen_autotools_input.pl
    if [ $? -eq 0 ]; then
        autotools_input_was_updated=1
    else
        autotools_input_was_updated=0
    fi

    echo "\$autotools_input_was_updated=$autotools_input_was_updated"

    need_configure=0
    ## [ On /bin/dash ]
    ## Accepts "backslash sequences" by default.
    ## There is no concept of "-e".
    echo ""
    if [ $autotools_input_was_updated -ne 0 -o $force_run_autotools -ne 0 ]; then
        echo "Run autotools."
        sh_exec aclocal && \
        sh_exec autoconf && \
        sh_exec automake --add-missing --copy
        if [ $? -eq 0 ]; then
            need_configure=1
        fi
    else
        echo "Skip running autotools."
    fi

    if [ ! -f 'Makefile' -o $force_run_autotools -ne 0 -o $need_configure -ne 0 ]; then
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

            echo "-----"
            echo "How to obtain a list of files targeted for archiving:"
            echo "  \$ make echo-distfiles"
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
    version=`sed -n 's/^.*\$[R]evision: \([0-9][0-9]*\.[0-9][0-9]*\) \$.*$/\1/p' "$apppath/$appname" | uniq`
}

sh_exec()
{
    ## [ On /bin/dash ]
    ## Accepts "backslash sequences" by default.
    ## There is no concept of "-e".
    echo ''
    echo '$' "$@"
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
  cat configure.ac | gawk '
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
