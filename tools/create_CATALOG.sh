#!/bin/sh
################################################################################
## create_CATALOG.sh -- Script to generate a catalog of scripts.
##
## - Generates Markdown formatted files in the 'docs' directory.
##   - Output documentation from '--help' option or POD
## - Generates image files using 'Graphviz'.
##   - Outputs svg images from dot files in 'docs'.
##
## - $Revision: 1.7 $
##
## - Tools required for this script
##   - Perl 5.10 or later
##   - pod2markdown
##   - help2man
##   - glow
##   - Graphviz (using the dot command)
##
## - Author: 2025, tomyama
## - Intended primarily for personal use, but BSD license permits redistribution.
##
## BSD 2-Clause License:
## Copyright (c) 2025, tomyama
## All rights reserved.
################################################################################

#out_format="png"
out_format="svg"

usage()
{
    echo "Usage: $appname <CATALOG.md> <script>..."
}

sh_main()
{
    sh_init "$@"
    parse_input "$@"

    targfile="$1"
    shift 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "No arguments specified."
        usage
        exit 1
    fi

    targdir="`dirname \"$targfile\"`"

    sh_getMdHeader >"$targfile.new"

    echo -e "# Script Catalog\n" >>"$targfile.new"

    scr_dir_last=""
    while [ 1 ]; do
        dependent_file="$1"
        shift 2>/dev/null
        if [ $? -ne 0 ]; then
            break
        fi

        #echo "\$dependent_file=\"$dependent_file\""

        depend_dir="`dirname \"$dependent_file\"`"
        depend_base="`basename \"$dependent_file\"`"

        if [ "$depend_dir" != "$scr_dir_last" ]; then
            if [ "$depend_dir" = "." ]; then
                heading_msg="Scripts to be installed"
            elif [ "$depend_dir" = "tools" ]; then
                heading_msg="The script that manages this directory"
            fi
            echo -e "* * *\n\n## $heading_msg\n" >>"$targfile.new"
        fi
        scr_dir_last="$depend_dir"

        echo -e "### $dependent_file\n" >>"$targfile.new"

        cat "$dependent_file" | awk '
            BEGIN{
                RS = "";
                FS = "\n";
            }
            NR == 1{
                for( idx=1; idx<NF; idx++ ){
                    if( match( $idx, "^#####" ) ){
                    }else if( match( $idx, "^##" ) ){
                        sub( "^## ?", "", $idx );
                        sub( "^.* -- ", "", $idx );
                        print( $idx )
                    }
                }
            }
            ' >>"$targfile.new"

        if [ -f "$targdir/img/$depend_base.jpg" ]; then
            echo -e '\n!'"[Image of the $depend_base command execution](img/$depend_base.jpg)" >>"$targfile.new"
        fi

        echo -e "\nFor details, please refer to [$depend_base.md]($depend_base.md).\n" >>"$targfile.new"

        sh_isUpdateNecessary "$dependent_file" "$targdir/$depend_base.md"
        ret=$?
        update_flag=0
        if [ $ret -eq 0 ]; then
            sh_isUpdateNecessary "$apppath/$appname" "$targdir/$depend_base.md"
            if [ $? -ne 0 ]; then
                echo "[$targdir/$depend_base.md] \"$appname\" has been updated."
                update_flag=1
            else
                echo "[$targdir/$depend_base.md] Already updated."
                update_flag=0
            fi
        elif [ $ret -eq 1 ]; then
            echo "[$targdir/$depend_base.md] Update required."
            update_flag=1
        else
            echo "[$targdir/$depend_base.md] Needs to be created."
            update_flag=1
        fi

        if [ $update_flag -ne 0 ]; then
            sh_getMdHeader >"$targdir/$depend_base.md"

            if [ -f "$targdir/img/$depend_base.jpg" ]; then
                echo -e '\n!'"[Image of the $depend_base command execution](img/$depend_base.jpg)" >>"$targdir/$depend_base.md"
            fi

            echo -e "\n* * *" >>"$targdir/$depend_base.md"

            filecmd_out="`file \"$dependent_file\"`"
            echo "$filecmd_out" | grep -i 'perl' 1>/dev/null
            if [ $? -eq 0 ]; then
                perldoc -Tu "$dependent_file" | pod2markdown >>"$targdir/$depend_base.md"
            fi
            echo "$filecmd_out" | grep -i 'shell' 1>/dev/null
            if [ $? -eq 0 ]; then
                help2man --no-info "./$dependent_file" | man -l - | awk '
                    /^NAME/{
                        FLAG = 1;
                    }
                    FLAG != 0{
                        if( match( $0, "^[a-z]" ) ){
                            FLAG = 0;
                        }else if( match( $0, "^[A-Z]" ) ){
                            printf( "# %s\n\n", $0 );
                        }else{
                            sub( "^       ", "", $0 );
                            if( $0 == "OPTIONS" ){
                              sub( "^", "# " );
                            }
                            print;
                        }
                    }
                ' >>"$targdir/$depend_base.md"
            fi

            echo -e "\n* * *" >>"$targdir/$depend_base.md"
            echo -e "- See '[README.md](../README.md)' for installation instructions." >>"$targdir/$depend_base.md"
            echo -e "- See '[CATALOG.md](CATALOG.md)' for a list and overview of the scripts." >>"$targdir/$depend_base.md"

            sh_showMarkdownDoc "$targdir/$depend_base.md"
        fi
    done

    echo -e "\n* * *" >>"$targfile.new"
    echo -e "- See '[README.md](../README.md)' for installation instructions." >>"$targfile.new"

    if [ -f "$targfile" ]; then
        diff "$targfile" "$targfile.new" >/dev/null
        if [ $? -eq 0 ]; then
            echo "[$targfile] Already updated."
            \rm -f "$targfile.new"
        else
            echo "[$targfile] Update required."
            mv -f "$targfile.new" "$targfile"
            sh_showMarkdownDoc "$targfile"
        fi
    else
        echo "[$targfile] Needs to be created."
        mv "$targfile.new" "$targfile"
        sh_showMarkdownDoc "$targfile"
    fi

    #sh_createGraph "$targdir"
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
            echo "Script to generate a catalog of scripts."
            echo ""
            echo "- Generates Markdown formatted files in the 'docs' directory."
            echo "  - Output documentation from '--help' option or POD"
            echo "- Generates image files using 'Graphviz'."
            echo "  - Outputs svg images from dot files in 'docs'."
            echo ""
            echo "- Tools required for this script"
            echo "  - Perl 5.10 or later"
            echo "  - pod2markdown"
            echo "  - help2man"
            echo "  - glow"
            echo "  - Graphviz (using the dot command)"
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

sh_getMdHeader()
{
    echo '<!--- This file is auto-generated by `make catalog`. Do not edit manually. -->'
}

sh_showMarkdownDoc()
{
    echo "[$1]"
    glow "$1"
}

sh_isUpdateNecessary()
{
    basefile="$1"
    genfile="$2"

    if [ ! -f "$basefile" ]; then
        echo "$0: error: $basefile: file not found" 1>&2
        exit 1
    fi

    epoch_base="`stat '--format=%Y' \"$basefile\"`"

    if [ -f "$genfile" ]; then
        epoch_genfile="`stat '--format=%Y' \"$genfile\"`"

        if [ "$epoch_genfile" -ge "$epoch_base" ]; then
            return 0
        fi
        return 1
    else
        return 2
    fi
}

sh_createGraph()
{
    cd "$1"
    for dot in *.dot; do
        if [ "$dot" = '*.dot' ]; then
            echo "There were no dot files in the \"docs\" directory."
            return 0
        fi
        #echo "dot: \"$dot\""

        dot_basename="`basename \"$dot\"`"
        dot_base="`echo \"$dot\" | sed 's!\.[^\.][^\.]*$!!'`"
        #echo "\$dot_base=\"$dot_base\""

        sh_isUpdateNecessary "$dot" "${dot_base}.${out_format}"
        ret=$?
        if [ $ret -eq 0 ]; then
            echo "[$dot] Already updated."
            continue
        elif [ $ret -eq 1 ]; then
            echo "[$dot] Update required."
        else
            echo "[$dot] Needs to be created."
        fi

        dot -Kdot -T${out_format} "$dot" "-o${dot_base}.${out_format}"
    done
}

sh_main "$@"
exit $?
