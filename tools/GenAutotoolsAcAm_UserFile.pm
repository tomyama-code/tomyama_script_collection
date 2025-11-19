################################################################################
## GenAutotoolsAcAm_UserFile.pm -- Define templates and key-value pairs for use with "gen_autotools_acam.pl".
##
## - This package can be edited by the user to form the basis of input files for the autotools.
##
## - $Revision: 2.2 $
##
## - Author: 2025, tomyama
## - Intended primarily for personal use, but BSD license permits redistribution.
##
## BSD 2-Clause License:
## Copyright (c) 2025, tomyama
## All rights reserved.
################################################################################

package GenAutotoolsAcAm_UserFile;

use strict;
use warnings 'all';
use File::Basename;

my %ACAM_KYVL;
$ACAM_KYVL{ '$MY_SCRIPTS$' } = 'c fill mark hello.pl hello.sh';
$ACAM_KYVL{ '$MY_TOOLS$' } = 'tools/build_script.sh' .
                            ' tools/gen_autotools_acam.pl' .
                            ' tools/GenAutotoolsAcAm_UserFile.pm' .
                            ' tools/create_CATALOG.sh';
$ACAM_KYVL{ '$MY_IMG_FORMAT$' } = 'svg';

my %ACAM_TMPL;

$ACAM_TMPL{ 'configure.ac' } = q{dnl #
#AC_PREREQ([2.72])	## Cygwin
##                	##   - autoscan 2.72
##                	##   - aclocal  1.18.1
##                	##   - autoconf 2.72
##                	##   - automake 1.18.1
##                	##   - /usr/share/automake-1.11
##                	##   - /usr/share/automake-1.12
##                	##   - /usr/share/automake-1.13
##                	##   - /usr/share/automake-1.14
##                	##   - /usr/share/automake-1.15
##                	##   - /usr/share/automake-1.16
##                	##   - /usr/share/automake-1.17
##                	##   - /usr/share/automake-1.18
#AC_PREREQ([2.69])	## CentOS 9 Stream [ autoreconf -i が必須 ]
##                	##   - autoscan 2.69
##                	##   - aclocal  1.16.2
##                	##   - autoconf 2.69
##                	##   - automake 1.16.2
##                	##   - /usr/share/automake-1.16 [ 古い ]
#AC_PREREQ([2.72])	## android 15 on Termux
##                	##   - autoscan 2.72
##                	##   - aclocal  1.18.1
##                	##   - autoconf 2.72
##                	##   - automake 1.18.1
##                	##   - /data/data/com.termux/files/usr/share/automake-1.18
AC_PREREQ([2.69])

AC_REVISION($Revision: 2.2 $)

dnl # パッケージ名, バージョン, メンテナのメールアドレス
AC_INIT([tomyama_script_collection], [0.2.9], [tomyama_code@yahoo.co.jp])

dnl # foreign: GNU の厳密な規則に従わない緩めのモード
dnl # dist-gzip: 指定しなくてもデフォルトでフックされている（抑止はno-dist-gzipを指定）
dnl #AM_INIT_AUTOMAKE([foreign dist-zip])
AM_INIT_AUTOMAKE([foreign])

dnl # Makefile.am から Makefile.in を生成する指定
AC_CONFIG_FILES([$AC_CONFIG_FILES$])

dnl # 最後に必要
AC_OUTPUT
};

$ACAM_TMPL{ 'Makefile.am' } = q{##

# # make install 時に bindir（通常 /usr/local/bin）へコピーされるファイル
# bin_SCRIPTS = $MY_SCRIPTS$
# インストールもされるし、配布 tarball にも必ず入る
dist_bin_SCRIPTS = $MY_SCRIPTS$

# make dist したときに tarball に含める追加ファイル
# automakeが自動的に見つけるファイルは書かない方針
# （該当ファイルは automake --help でリストを確認できる）
EXTRA_DIST = LICENSE \
  docs/CATALOG.md \
  docs/Developer_Manual.md \
  $MY_DOTS$ \
  $MY_IMGS$ \
  docs/img/*.jpg \
  $MY_DOCS$ \
  $MY_TL_DOCS$ \
  $MY_TOOLS$ \
  tests/cmd_wrapper \
  tests/prt \
  tests/testdata_uniq_line.txt \
  tests/tests.sh

SUBDIRS = $SUBDIRS$

docs/CATALOG.md: $(dist_bin_SCRIPTS) $MY_TOOLS$
	$(builddir)/tools/create_CATALOG.sh docs/CATALOG.md $^

.PHONY: catalog
catalog: docs/CATALOG.md ;

docs/img/%.$MY_IMG_FORMAT$: docs/img/%.dot
	dot -Kdot -T$MY_IMG_FORMAT$ $< -o $@

docs/img/%.png: docs/img/%.dot
	dot -Kdot -Tpng $< -o $@

docs/%.md: catalog ;

dist-hook: catalog ;
};

$ACAM_TMPL{ 'tests/Makefile.am' } = q{##

# テスト用のスクリプト（make checkで使われる）
TESTS = $MY_TESTS_BNAME$

dist_check_SCRIPTS = $(TESTS)
};

sub getKeyValue()
{
    return %ACAM_KYVL;
}

sub getTemplates()
{
    return %ACAM_TMPL;
}

sub setupValue()
{
    $ACAM_KYVL{ 'ACAM_REVISION' } = '$Revision: 2.2 $';
    $ACAM_KYVL{ '$MY_TESTS$' } = &getTestNames( $ACAM_KYVL{ '$MY_SCRIPTS$' } );
    $ACAM_KYVL{ '$MY_TESTS_BNAME$' } = &getBaseNames( $ACAM_KYVL{ '$MY_TESTS$' } );
    $ACAM_KYVL{ '$MY_DOCS$' } = &getDocNames( $ACAM_KYVL{ '$MY_SCRIPTS$' } );
    $ACAM_KYVL{ '$MY_TL_DOCS$' } = &getDocNames( $ACAM_KYVL{ '$MY_TOOLS$' } );
    my @my_imgs_dot = glob( 'docs/img/*.dot' );
    $ACAM_KYVL{ '$MY_DOTS$' } = join( ' ', @my_imgs_dot );
    $ACAM_KYVL{ '$MY_IMGS$' } = &getImgNames( $ACAM_KYVL{ '$MY_DOTS$' } );

    $ACAM_KYVL{ '$AC_CONFIG_FILES$' } = '';
    my @ac_cfg_files = ();
    my @subdirs = ();
    foreach my $k( sort( keys( %ACAM_TMPL ) ) ){
        if( $k =~ m!^((.*?)/?Makefile)\.am$!o ){
            push( @ac_cfg_files, $1 );
            if( defined( $2 ) && $2 ne '' ){
                push( @subdirs, $2 );
            }
        }
    }
    $ACAM_KYVL{ '$AC_CONFIG_FILES$' } = join( ' ', @ac_cfg_files );
    $ACAM_KYVL{ '$SUBDIRS$' } = join( ' ', @subdirs );
}

## "fill hello.pl hello.sh"
## -> "tests/fill.test.pl tests/hello.pl.test.pl tests/hello.sh.test.pl"
sub getTestNames( $ )
{
    my @arr = split( / +/, $_[ 0 ] );
    my $idx_max = scalar( @arr );
    for( my $idx=0; $idx<$idx_max; $idx++ ){
        #printf( qq{\$arr[ $idx ] = "$arr[ $idx ]"\n} );
        my $bname = basename( $arr[ $idx ] );
        $arr[ $idx ] = 'tests/' . $bname . '.test.pl';
    }
    return join( ' ', @arr );
}

## "fill hello.pl hello.sh"
## -> "docs/fill.md docs/hello.pl.md docs/hello.sh.md"
sub getDocNames( $ )
{
    my @arr = split( / +/, $_[ 0 ] );
    my $idx_max = scalar( @arr );
    for( my $idx=0; $idx<$idx_max; $idx++ ){
        #printf( qq{\$arr[ $idx ] = "$arr[ $idx ]"\n} );
        my $bname = basename( $arr[ $idx ] );
        $arr[ $idx ] = 'docs/' . $bname . '.md';
    }
    return join( ' ', @arr );
}

## "tests/fill.test.pl tests/hello.pl.test.pl tests/hello.sh.test.pl"
## -> "fill.test.pl hello.pl.test.pl hello.sh.test.pl"
sub getBaseNames( $ )
{
    my @arr = split( / +/, $_[ 0 ] );
    my $idx_max = scalar( @arr );
    for( my $idx=0; $idx<$idx_max; $idx++ ){
        #printf( qq{\$arr[ $idx ] = "$arr[ $idx ]"\n} );
        my $bname = basename( $arr[ $idx ] );
        $arr[ $idx ] = $bname;
    }
    return join( ' ', @arr );
}

##    "docs/devel_step_0.dot docs/devel_step_0_1.dot"
## -> "docs/devel_step_0.svg docs/devel_step_0_1.svg"
sub getImgNames( $ )
{
    my @arr = split( / +/, $_[ 0 ] );
    my $idx_max = scalar( @arr );
    my @imgs = ();
    for( my $idx=0; $idx<$idx_max; $idx++ ){
        #printf( qq{\$arr[ $idx ] = "$arr[ $idx ]"\n} );
        my $imgpath = $arr[ $idx ];
        $imgpath =~ s!\.dot$!.$ACAM_KYVL{ '$MY_IMG_FORMAT$' }!io;
        push( @imgs, $imgpath );
    }
    return join( ' ', @imgs );
}

1;
__END__

=pod

=head1 NAME

GenAutotoolsAcAm_UserFile.pm -- Define templates and key-value pairs for use with "gen_autotools_acam.pl".

=head1 SYNOPSIS

Loading method example:

  use lib './tools';    # Add the package location to @INC
  use GenAutotoolsAcAm_UserFile;

=head1 DESCRIPTION

This package serves as a user-editable configuration for "gen_autotools_acam.pl".
It defines:

=over 4

=item *
Key-value pairs (placeholders such as C<$MY_SCRIPTS$>)

=item *
File templates (e.g. C<configure.ac>, C<Makefile.am>)

=back

The script replaces the placeholders in each template with the values defined here,
and outputs the resulting files.

=head1 FUNCTIONS

=over 4

=item B<getKeyValue()>

Return the hash of key-value pairs.

=item B<getTemplates()>

Return the hash of template file definitions.

=item B<setupValue()>

Populate dynamic values (e.g. test names, documentation file lists) based on existing keys.

=back

=head1 SEE ALSO

L<gen_autotools_acam.pl>, perl(1)

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
