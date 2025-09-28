#!/usr/bin/perl -w
################################################################################
## gen_autotools_acam.pl -- Generate and manage autotools "ac" and "am" files from a single source.
##
## - Outputs autotools ac and am files based on the data in "GenAutotoolsAcAm_UserFile.pm".
## - Eliminates the hassle of adding definitions to multiple files.
##
## - $Revision: 1.5 $
##
## - Author: 2025, tomyama
## - Intended primarily for personal use, but BSD license permits redistribution.
##
## BSD 2-Clause License:
## Copyright (c) 2025, tomyama
## All rights reserved.
################################################################################

use strict;
use warnings 'all';
use File::Basename;
use Text::Diff 'diff';

use lib './tools';    # @INC にディレクトリを追加
use GenAutotoolsAcAm_UserFile;

my $apppath;
my $appname;

exit( &pl_main( @ARGV ) );


## スクリプトのエントリポイント
sub pl_main( @ )
{
    &initialize( @_ );  ## 初期化処理
    &parse_arg( @_ );   ## 引数解析

    GenAutotoolsAcAm_UserFile::setupValue();
    my %ACAM_KYVL = GenAutotoolsAcAm_UserFile::getKeyValue();
    my %ACAM_TMPL = GenAutotoolsAcAm_UserFile::getTemplates();

    foreach my $kv_k( sort( keys( %ACAM_KYVL ) ) ){
        print( qq{"$kv_k" = "$ACAM_KYVL{ $kv_k }"\n} );
    }

    foreach my $k( sort( keys( %ACAM_TMPL ) ) ){
        my $body = $ACAM_TMPL{ $k };

        foreach my $kv_k( sort( keys( %ACAM_KYVL ) ) ){
#            print( qq{"$kv_k" = "$ACAM_KYVL{ $kv_k }"\n} );
            $body =~ s!\Q$kv_k\E!$ACAM_KYVL{ $kv_k }!g;
        }

        ## コメントで始まる行は削除
        my @lines = split( /\r?\n/, $body );
        $body = '';
        my $line_len = scalar( @lines );
        for( my $idx=0; $idx<$line_len; $idx++ ){
            my $l = $lines[ $idx ];
            if( $l =~ m/^(?:dnl|#)/io ){
                next;
            }

            $body .= $l . "\n";
        }

        print( qq{[$k]\n} );
#        print( qq{$body} );

        my $bOldFileNothing = 0;
        if( ! -f $k ){
            $bOldFileNothing = 1;
            print( qq{$appname: $k: file not found: create!\n} );
        }

        my $newname = "$k.new";
        open( NEWFILE, '>', $newname ) ||
            die( qq{$appname: $newname: could not open file: $!} );
        print NEWFILE ( $body );
        close( NEWFILE );

        my $diff = '';
        if( ! $bOldFileNothing ){
            $diff = diff( $k, $newname );
#            print( qq{\$diff = "$diff"\n} );
        }else{
            $diff = 'dummy: If the file does not exist, create it.';
        }

        if( $diff eq '' ){
            print( qq{The file is already up to date.\n} );
            if( unlink( $newname ) <= 0 ){
                print STDERR ( qq{$appname: could not remove file: $newname\n} );
            }
        }else{
            if( unlink( $k ) <= 0 ){
                print STDERR ( qq{$appname: could not remove file: $k\n} );
            }
            rename( $newname, $k ) ||
                die( qq{$appname: could not rename file: $newname -> $k\n} );
        }
    }

    return 0;
}

## 初期化サブルーチン
sub initialize( @ )
{
    ### GLOBAL ###
    $apppath = dirname( $0 );
    $appname = basename( $0 );
    $main::debug = 0;
    ##############

    return 0;
}

## 引数解析
sub parse_arg( @ )
{
    my @val = @_;

    ## 引数分のループを回す
    while( my $myparam = shift( @val ) ){
        if( $myparam =~ s/^-([a-zA-Z])([a-zA-Z]+)$/-$1/o ){
            unshift( @val, "-$2" );
        }

        ## デバッグモードOn
        if    ( $myparam eq '-d' || $myparam eq '--debug' ){
            $main::debug = 1;
        }elsif( $myparam eq '-h' || $myparam eq '--help' ){
            &usage( 0 );
            exit( 0 );
        }else{
            print STDERR ( qq{$appname: `$myparam': Unknown option\n} );
        }
        print STDERR ( qq{ARGV : "$myparam"\n} ) if( $main::debug );
    }

    return 0;
}

## 書式表示
sub usage( $ )
{
    my $msg = "Usage: " .
    "$appname [<OPTIONS...>]\n" .
    "Try `perldoc $apppath/$appname' for more information.\n";

    if( $_[0] ){
        print STDERR ( $msg );
    }else{
        print STDOUT ( $msg );
    }

    return 0;
}
__END__

=pod

=head1 NAME

gen_autotools_acam.pl -- Generate and manage autotools "ac" and "am" files from a single source.

=head1 SYNOPSIS

$ gen_autotools_acam.pl [I<OPTIONS...>]

=head1 DESCRIPTION

This script generates and updates autotools "ac" and "am" files
based on templates and key-value pairs defined in "GenAutotoolsAcAm_UserFile.pm".
It helps avoid the need to duplicate definitions across multiple files.

Example:

  $ ls -1 tools/*.p?
  tools/GenAutotoolsAcAm_UserFile.pm
  tools/gen_autotools_acam.pl
  $ ./tools/gen_autotools_acam.pl

The file "tools/GenAutotoolsAcAm_UserFile.pm" defines templates such as "configure.ac".
Hash keys correspond to relative paths from the project root.
For example, the key for "tests/Makefile.am" is simply "tests/Makefile.am".

Note: This script must be executed from the project root,
otherwise "tools/GenAutotoolsAcAm_UserFile.pm" will not be found.

=head1 OPTIONS

=over 4

=item B<-d>, B<--debug>

Enable debugging mode.

=item B<-h>, B<--help>

Show a brief usage message.

=back

=head1 SEE ALSO

L<GenAutotoolsAcAm_UserFile.pm>, perl(1)

=head1 AUTHOR

2025, tomyama

=head1 LICENSE

Copyright (c) 2025, tomyama

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
3. Neither the name of tomyama nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
