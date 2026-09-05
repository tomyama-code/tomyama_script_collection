#!/usr/bin/env perl
#####
## ゆっくりと少しずつ出力する
##
## - ex) ./trials/output_slowly_and_gradually.pl | ./mark --head-tail -
## - $Revision: 1.5 $
#####

use strict;                         # first released with perl 5
use warnings;                       # first released with perl v5.6.0
use POSIX qw();                     # first released with perl 5
use Getopt::Long qw();              # first released with perl 5
#use IO::Handle;                     # first released with perl 5.00307

STDOUT->autoflush( 1 );

my @indata = (
    qq{0123456789abcdef},
    qq{123456789abcdef0},
    qq{23456789abcdef01},
    qq{3456789abcdef012},
    qq{456789abcdef0123},
    qq{56789abcdef01234},
    qq{6789abcdef012345},
    qq{789abcdef0123456},
    qq{89abcdef01234567},
    qq{9abcdef012345678},
    qq{abcdef0123456789},
    qq{bcdef0123456789a},
    qq{cdef0123456789ab},
    qq{def0123456789abc},
    qq{ef0123456789abcd},
    qq{f0123456789abcde},
);

my $indata_len = scalar( @indata );
#print( qq{\$indata_len = $indata_len\n} );  # $indata_len = 16

my $indata_counter = 0;
sub get_data( $$$$ )
{
    my( $ref_indata, $ref_out, $row, $use_cr ) = @_;

    my $rows = $row;
    if( ( $rows + $indata_counter ) > $indata_len ){
        $rows = $indata_len - $indata_counter;
    }

    my $cr = '';
    $cr = "\r" if( $use_cr );

    $$ref_out = '';
    for( my $idx=0; $idx<$rows; $idx++ ){
        my $ary_idx = $indata_counter + $idx;
        #print( qq{\$ary_idx = $ary_idx\n} );
        $$ref_out .= sprintf( "%02d: %s$cr\n", $idx+1, ${ $ref_indata }[ $ary_idx ] );
    }

    $indata_counter += $rows;
    return $rows;
}

sub out_data( $$$ )
{
    my( $ref_buff, $num_of_row, $counter ) = @_;
    my @buff = split( /\n/, $$ref_buff );
    for( my $idx=0; $idx<$num_of_row; $idx++ ){
        $buff[ $idx ] = sprintf( '%03d: %s', $counter+$idx+1, $buff[ $idx ] );
    }
    my $msg = join( "\n", @buff );
    print( qq{$msg\n} );
    return $counter+$num_of_row;
}

use constant DEF_WAIT_SEC => 1;
use constant DEF_ROW => 8;

my $msg_buff;
my $wait_sec = DEF_WAIT_SEC;
my $row_counter = 0;
my $row = DEF_ROW;
my $use_cr = 0;

# 設定: ショートオプションのまとめ指定（バンドリング）を有効化
Getopt::Long::Configure("bundling");

Getopt::Long::GetOptions(
    'row=i' => \$row,
    'use-cr'    => \$use_cr,
    'sleep-sec=o' => \$wait_sec,
) || die( qq{error: Failed to parse option switches.\n} );

my $cycle = POSIX::ceil( $indata_len / $row );

#print( qq{\$row=$row, \$cycle=$cycle, \$use_cr=$use_cr\n} );

for( my $idx=0; $idx<$cycle; $idx++ ){
    my $num_of_row = get_data( \@indata, \$msg_buff, $row, $use_cr );
    $row_counter = out_data( \$msg_buff, $num_of_row, $row_counter );

    sleep( $wait_sec ) if( $row_counter < $indata_len );
}
