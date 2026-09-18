#!/bin/sh
################################################################################
## create_CATALOG.sh -- Script to generate a catalog of scripts.
##
## - Generates Markdown formatted files in the 'docs' directory.
##   - Output documentation from '--help' option or POD
## - Generates image files using 'Graphviz'.
##   - Outputs svg images from dot files in 'docs'.
##
## - $Revision: 1.15 $
##
## - Tools required for this script
##   - Perl 5.10 or later
##   - pod2markdown
##   - glow
##   - Graphviz (using the dot command)
##
## - Author: 2025-2026, tomyama
## - Intended primarily for personal use, but BSD license permits redistribution.
##
## BSD 2-Clause License:
## Copyright (c) 2025-2026, tomyama
## All rights reserved.
################################################################################

#out_format="png"
out_format="svg"

usage()
{
    echo "SYNOPSIS"
    echo "  ./tools/$appname <CATALOG.md> <script>..."
}

sh_main()
{
    sh_init "$@"
    parse_input "$@"

    rev=`sh_get_revision`
    #echo "appname=\"$appname\", rev=\"$rev\""
    # appname="create_CATALOG.sh", rev="1.12"

    targfile="$1"
    ## Confirmation required before calling "shift" [ on /bin/dash ]
    if [ "$targfile" = "" ]; then
        echo "No arguments specified."
        usage
        exit 1
    fi
    shift

    targdir="`dirname \"$targfile\"`"

    sh_getMdHeader >"$targfile.new"

    ## [ On /bin/dash ]
    ## Accepts "backslash sequences" by default.
    ## There is no concept of "-e".
    echo "# Script Catalog" >>"$targfile.new"
    echo ""                 >>"$targfile.new"

    scr_dir_last=""
    while [ 1 ]; do
        dependent_file="$1"
        ## Confirmation required before calling "shift" [ on /bin/dash ]
        if [ "$dependent_file" = "" ]; then
            break
        fi
        shift

        #echo "\$dependent_file=\"$dependent_file\""

        depend_dir="`dirname \"$dependent_file\"`"
        depend_base="`basename \"$dependent_file\"`"
        is_perl_module=0
        echo "$depend_base" | grep '\.pm$' >/dev/null
        if [ $? -eq 0 ]; then
            is_perl_module=1
        fi

        filecmd_out="`file \"$dependent_file\"`"
        echo "$filecmd_out" | grep -i 'perl' 1>/dev/null
        if [ $? -eq 0 ]; then
            dependent_file_type="perl"
        fi
        echo "$filecmd_out" | grep -i 'shell' 1>/dev/null
        if [ $? -eq 0 ]; then
            dependent_file_type="shell"
        fi

        if [ "$depend_dir" != "$scr_dir_last" ]; then
            if [ "$depend_dir" = "." ]; then
                heading_msg="Scripts to be installed"
            elif [ "$depend_dir" = "tools" ]; then
                heading_msg="The script that manages this directory"
            fi
            ## [ On /bin/dash ]
            ## Accepts "backslash sequences" by default.
            ## There is no concept of "-e".
            echo "* * *" >>"$targfile.new"
            echo ""      >>"$targfile.new"
            echo "## $heading_msg" >>"$targfile.new"
            echo ""      >>"$targfile.new"
        fi
        scr_dir_last="$depend_dir"

        ## [ On /bin/dash ]
        ## Accepts "backslash sequences" by default.
        ## There is no concept of "-e".
        echo "### $dependent_file" >>"$targfile.new"
        echo ""                    >>"$targfile.new"

        ## ヘッダーコメントをCATALOG.mdに
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
            ## [ On /bin/dash ]
            ## Accepts "backslash sequences" by default.
            ## There is no concept of "-e".
            echo '' >>"$targfile.new"
            img_label="Image of the $depend_base command execution"
            if [ $is_perl_module -ne 0 ]; then
                img_label="Image of using the $depend_base module"
            fi
            echo '!'"[$img_label](img/$depend_base.jpg)" >>"$targfile.new"
        fi

        ## [ On /bin/dash ]
        ## Accepts "backslash sequences" by default.
        ## There is no concept of "-e".
        echo "" >>"$targfile.new"
        echo "For details, please refer to [$depend_base.md]($depend_base.md)." >>"$targfile.new"
        echo "" >>"$targfile.new"

        ## スクリプト毎のドキュメントを生成

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

            # Is the environment capable of generating documents?
            is_environment_inadequate=0
            if [ "$dependent_file_type" = "perl" ]; then
                sh_command_exists "pod2markdown"
                if [ $? -ne 0 ]; then
                    errp "error: pod2markdown command is missing."
                    is_environment_inadequate=1
                fi
            fi
            if [ $is_environment_inadequate -ne 0 ]; then
                errp "error: Cannot generate documentation."
                continue;
            fi

            sh_getMdHeader >"$targdir/$depend_base.md"

            if [ -f "$targdir/img/$depend_base.jpg" ]; then
                ## [ On /bin/dash ]
                ## Accepts "backslash sequences" by default.
                ## There is no concept of "-e".
                echo '' >>"$targdir/$depend_base.md"
                img_label="Image of the $depend_base command execution"
                if [ $is_perl_module -ne 0 ]; then
                    img_label="Image of using the $depend_base module"
                fi
                echo '!'"[$img_label](img/$depend_base.jpg)" >>"$targdir/$depend_base.md"
            fi

            ## [ On /bin/dash ]
            ## Accepts "backslash sequences" by default.
            ## There is no concept of "-e".
            echo ""      >>"$targdir/$depend_base.md"
            echo "* * *" >>"$targdir/$depend_base.md"

            if [ "$dependent_file_type" = "perl" ]; then
                perldoc -Tu "./$dependent_file" | \
                    pod2markdown | \
                    sh_embed_version "$dependent_file" >>"$targdir/$depend_base.md"
            elif [ "$dependent_file_type" = "shell" ]; then
                "./$dependent_file" --help | sh_help2markdown | \
                    sh_embed_version "$dependent_file" >>"$targdir/$depend_base.md"
            fi

            ## [ On /bin/dash ]
            ## Accepts "backslash sequences" by default.
            ## There is no concept of "-e".
            echo ""      >>"$targdir/$depend_base.md"
            echo "* * *" >>"$targdir/$depend_base.md"
            echo "- See '[README.md](../README.md)' for installation instructions." >>"$targdir/$depend_base.md"
            echo "- See '[CATALOG.md](CATALOG.md)' for a list and overview of the scripts." >>"$targdir/$depend_base.md"

            sh_showMarkdownDoc "$targdir/$depend_base.md"
        fi
    done

    ## [ On /bin/dash ]
    ## Accepts "backslash sequences" by default.
    ## There is no concept of "-e".
    echo ""      >>"$targfile.new"
    echo "* * *" >>"$targfile.new"
    echo "- See '[README.md](../README.md)' for installation instructions." >>"$targfile.new"

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
    version=`sed -n 's/^.*\$[R]evision: \([0-9][0-9]*\.[0-9][0-9]*\) \$.*$/\1/p' "$apppath/$appname" | uniq`
}

## argument analysis
parse_input()
{
    while [ 1 ]; do
        arg="$1"
        ## Confirmation required before calling "shift" [ on /bin/dash ]
        if [ "$arg" = "" ]; then
            break
        fi
        shift

        #echo $arg
        case "$arg" in
        '-v' | '--version')
            echo "$appname - version($version)"
            exit 0
            ;;
        '-h' | '--help')
            echo "NAME"
            echo "  $appname -- Script to generate a catalog of scripts."
            echo ""
            echo "VERSION"
            echo '  This document describes $Revision: 1.15 $.'
            echo ""
            usage
            echo ""
            echo "DESCRIPTION"
            echo "  - Generates Markdown formatted files in the 'docs' directory."
            echo "    - Output documentation from '--help' option or POD"
            echo ""
            echo "  - Generates image files using 'Graphviz'."
            echo "    - Outputs svg images from dot files in 'docs'."
            echo ""
            echo "OPTIONS"
            echo "  -h, --help     display this help and exit"
            echo "  -v, --version  output version information and exit"
            echo ""
            echo "DEPENDENCIES"
            echo "  Tools required for this script."
            echo ""
            echo "  - Perl 5.10 or later"
            echo "  - pod2markdown"
            echo "  - glow"
            echo "  - Graphviz (using the dot command)"
            echo ""
            echo "AUTHOR"
            echo "  2025-2026, tomyama"
            echo ""
            echo "LICENSE"
            echo "  BSD 2-Clause License"
            echo "  Copyright (c) 2025-2026, tomyama"
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

errp()
{
    echo "$@" 1>&2
}

sh_get_revision()
{
    rev='$Revision: 1.15 $'
    echo "$rev" | sed 's!^\$[R]evision: \([0-9][0-9]*\.[0-9][0-9]*\) \$$!\1!'
}

sh_getMdHeader()
{
    echo '<!--- This file is auto-generated by `make catalog`. Do not edit manually. -->'
}

sh_command_exists()
{
    which "$1" >/dev/null 2>&1
}

sh_help2markdown()
{
    cat - | perl -ne '
        my $line = $_;
        $line =~ s/\r?\n$//o;

        my @head1 = (
            q{NAME},
            q{VERSION},
            q{SYNOPSIS},
            q{DESCRIPTION},
            q{OPTIONS},
            q{SEE ALSO},
            q{DEPENDENCIES},
            q{AUTHOR},
            q{LICENSE}
        );
        my $definition_of_head1 = join( q{|}, @head1 );
        if( $line =~ s/^($definition_of_head1)$/# $1\n/o ){
        }else{
            $line =~ s/^  //o;
        }

        print( qq{$line\n} );
    '
}

sh_embed_version()
{
    script_name="$1"
    cat - | perl -ne '
        my $line = $_;
        $line =~ s/\r?\n$//o;

        my $flag_embedded = 0;
        if( $line =~ s/^\s*(This document describes) \$[R]evision: (\d+\.\d+) \$\.$/- $1 $script_name [$2]./go ){
            $flag_embedded = 1;
        }
        print( "$line\n" );
        if( $flag_embedded ){
            print( qq{- This document was generated by $appname [$rev].\n} );
        }
    ' -s -- "-script_name=$script_name" "-appname=$appname" "-rev=$rev"
}

sh_showMarkdownDoc()
{
    if [ "$glow_command_exists" = '' ]; then
        glow_command_exists=0
        sh_command_exists "glow"
        if [ $? -eq 0 ]; then
            glow_command_exists=1
        fi
    fi
    if [ $glow_command_exists -eq 0 ]; then
        errp "error: glow: command not found"
        return 1
    fi

    echo "[$1]"
    glow "$1"
}

sh_get_epoch_sec_of_last_update_time()
{
    targetfile="$1"
    perl -e 'print( ( stat( $ARGV[ 0 ] ) )[ 9 ], "\n" )' "$targetfile"
}

sh_isUpdateNecessary()
{
    basefile="$1"
    genfile="$2"

    if [ ! -f "$basefile" ]; then
        errp "$0: error: $basefile: file not found"
        exit 1
    fi

    epoch_base="`sh_get_epoch_sec_of_last_update_time \"$basefile\"`"

    if [ -f "$genfile" ]; then
        epoch_genfile="`sh_get_epoch_sec_of_last_update_time \"$genfile\"`"

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

        sh_command_exists "dot"
        if [ $? -ne 0 ]; then
            errp "error: dot: command not found"
            continue
        fi

        dot -Kdot -T${out_format} "$dot" "-o${dot_base}.${out_format}"
    done
}

sh_main "$@"
exit $?
