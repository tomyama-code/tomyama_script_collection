#!/bin/sh
######################################################################
## create_graph.sh -- A script to generate image files using "Graphviz".
##
## - Outputs svn images from dot files in "docs".
##
## - $Revision: 1.2 $
##
## - Tools required for this script
##   - Perl 5.10 or later
##   - Graphviz (using the dot command)
##
## - Author: 2025, tomyama
## - Intended primarily for personal use, but BSD license permits redistribution.
##
## BSD 2-Clause License:
## Copyright (c) 2025, tomyama
## All rights reserved.
######################################################################

#out_format="png"
out_format="svg"

usage()
{
    echo "Usage: $appname [-h|--help] [-v|--version]"
}

## script entry point
sh_main()
{
    sh_init "$@"

    parse_input "$@"

    cd "$apppath/../docs/"
    for dot in *.dot; do
        if [ "$dot" = '*.dot' ]; then
            echo "There were no dot files in the \"docs\" directory."
            exit 0
        fi
        #echo "dot: \"$dot\""

        epoch_dot="`stat '--format=%Y' \"$dot\"`"

        dot_basename="`basename \"$dot\"`"
        dot_base="`echo \"$dot\" | sed 's!\.[^\.][^\.]*$!!'`"
        #echo "\$dot_base=\"$dot_base\""

        if [ -f "${dot_base}.${out_format}" ]; then
            epoch_img="`stat '--format=%Y' \"${dot_base}.${out_format}\"`"

            if [ "$epoch_img" -ge "$epoch_dot" ]; then
                echo "[$dot] Already updated."
                continue
            fi
            echo "[$dot] Update required."
        else
            echo "[$dot] Needs to be created."
        fi

        dot -Kdot -T${out_format} "$dot" "-o${dot_base}.${out_format}"
    done
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

## argument analysis
parse_input()
{
    while [ 1 ]; do
        arg="$1"
        shift 2>/dev/null
        if [ $? -ne 0 ]; then
            break
        fi

        #echo $arg
        case "$arg" in
        '-v' | '--version')
            echo "$appname - version($version)"
            exit 0
            ;;
        '-h' | '--help')
            usage
            echo ""
            echo "A script to generate image files using 'Graphviz'."
            echo "Outputs svn images from dot files in 'docs'."
            echo ""
            echo "OPTIONS"
            echo "  -h, --help     display this help and exit"
            echo "  -v, --version  output version information and exit"
            exit 0
            ;;
        '-'*)
            errp "$appname: \`$arg': unknown option"
            errp "`usage`"
            exit 1
            ;;
        *)
            ;;
        esac
    done
}

## error output
errp()
{
    echo "$@" 1>&2
}

sh_main "$@"
exit $?
