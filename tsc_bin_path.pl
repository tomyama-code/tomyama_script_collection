#!/usr/bin/env perl
################################################################################
## tsc_bin_path.pl -- Prints the installation path or project root directory.
##
## - Version: 1
## - $Revision: 1.3 $
##
## - Author: 2026, tomyama
## - Intended primarily for personal use, but BSD license permits redistribution.
##
## BSD 2-Clause License:
## Copyright (c) 2026, tomyama
## All rights reserved.
################################################################################
use strict;
use warnings;
use FindBin;
use Pod::Text;

if( defined( $ARGV[ 0 ] ) ){
    if( $ARGV[ 0 ] eq '-h' || $ARGV[ 0 ] eq '--help' ){
        # パーサーの初期化
        my $parser = Pod::Text->new();
        # ファイルからPODを抽出してテキストとして標準出力
        $parser->parse_from_file( $0 );
        exit( 0 );
    }
}

my $mypath = $FindBin::Bin;

if( defined( $ARGV[ 0 ] ) ){
    my $tmppath = "$mypath/$ARGV[ 0 ]";
    if( -d "$tmppath" ){
        $mypath = $tmppath;
    }else{
        die( qq{error: directory not found: "$tmppath"\n} );
    }
}

print( $mypath );
exit( 0 );
__END__

=pod

=encoding utf8

=head1 NAME

tsc_bin_path.pl -- Prints the installation path or project root directory.

=head1 DESCRIPTION

If called using the PATH environment variable,
it outputs the installation path;
if called using a relative path,
it outputs the specified path.

=head1 SYNOPSIS

$ tsc_bin_path.pl [I<OPTIONS...>]

=head1 OPTIONS

=over 4

=item -h, --help

  Display simple help and exit.

=back

=head1 DEPENDENCIES

This script uses only B<core Perl modules>. No external modules from CPAN are required.

=head2 Core Modules Used

=over 4

=item * L<FindBin> - first included in perl 5.00307

=item * L<Pod::Text> - first included in perl 5.002

=item * L<strict> — first included in perl 5

=item * L<warnings> — first included in perl v5.6.0

=back

=head2 Survey methodology

=over 4

=item 1. Preparation

Define the script name:

  $ target_script=tsc_bin_path.pl

=item 2. Extract used modules

Generate a list of modules from C<use> statements:

  $ grep '^use ' $target_script | sed 's!^use \([^ ;{][^ ;{]*\).*$!\1!' | \
      sort | uniq | tee ${target_script}.uselist

=item 3. Check core module status

Run C<corelist> for each module to find the first Perl version it appeared in:

  $ cat ${target_script}.uselist | while read line; do
      corelist $line
    done

=back

=head1 SEE ALSO

=over 4

=item L<C<perl(1)>>

=back

=head1 AUTHOR

2026, tomyama

=head1 LICENSE

Copyright (c) 2026, tomyama

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
