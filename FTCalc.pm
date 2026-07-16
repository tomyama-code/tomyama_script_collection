################################################################################
## FTCalc -- Perl interface for The Flat-Text Calculator
##
## - A module that provides an API for manipulating the calculation script "c".
##
## - Version: 1
## - $Revision: 1.4 $
##
## - Author: 2026, tomyama
## - Intended primarily for personal use, but BSD license permits redistribution.
##
## BSD 2-Clause License:
## Copyright (c) 2026, tomyama
## All rights reserved.
################################################################################

=pod

=encoding utf8

=head1 NAME

FTCalc - Perl interface for The Flat-Text Calculator

=head1 SYNOPSIS

  use lib qx/tsc_bin_path.pl/;
  use FTCalc;

  my $c = FTCalc->new();

  my( $day, $h, $m, $s ) =
      $c->formula( qq{
          dhms2dhms(
              0, 24 / SAKUBOU, 0, 0
          )
      } );
  $s = $c->formula( qq{round( $s, 3 )} );
  print( qq{Calculated result: $day days $h hours $m minutes $s seconds.\n} );
  # Calculated result: 0 days 0 hours 48 minutes 45.78 seconds.

=head1 DESCRIPTION

A module that provides an API for manipulating the calculation script "c".

=head1 METHODS

=cut

package FTCalc;
use strict;
use warnings;
use IPC::Open2;
use Symbol;
use File::Basename qw(dirname);
use parent 'Exporter';

our @EXPORT = qw(
    _FTC_FAIL_OPEN2
    FTC_FSC_FOLLOW_VERBOSE
    FTC_FSC_OUTPUT_FORMULA
    FTC_FSC_OUTPUT_RESULT
    FTC_FSC_OUTPUT_BOTH
);

use constant _FTC_FAIL_OPEN2 => 0x01;

use constant FTC_FSC_FOLLOW_VERBOSE => 0x01;
use constant FTC_FSC_OUTPUT_FORMULA => 0x10;
use constant FTC_FSC_OUTPUT_RESULT  => 0x20;
use constant FTC_FSC_OUTPUT_BOTH    => 0x30;

$main::def_autoflush = 1;
$main::def_timeout = 0.5;
$main::def_b_verbose = 0;
$main::def_formula_os = ( FTC_FSC_FOLLOW_VERBOSE | FTC_FSC_OUTPUT_BOTH );
$main::action_flag = 0x00;

=over 4

=item C<new( [ @OPTIONS ] )>

Creates an instance.
For @OPTIONS, specify any arguments you wish to pass to the c script.

  my $c = FTCalc->new( '--banner' );

=back

=cut

sub new
{
    my( $class, @opts ) = @_;

    my $module_path = &_get_my_path();
    my $path_to_c = "$module_path/c";
    #print( qq{\$path_to_c="$path_to_c"\n} );

    # c スクリプトを標準入力待ちモードで起動
    my( $chld_out, $chld_in );
    $chld_out = gensym();   # ファイルハンドル用のシンボル生成
    $chld_in  = gensym();

    # プロセス起動 (c スクリプトを実行)
    my $pid;
    eval{
        $pid = &_FtcOpen2( $chld_out, $chld_in, $path_to_c, @opts );
    };
    if( $@ ){
        die( "FTCalc: _FtcOpen2(): Failed to start '$path_to_c': $!" );
    }

    # 両方のハンドルをバッファリング無効（即時出力）にする
    $chld_in->autoflush( 1 );
    $chld_out->autoflush( 1 );

    # 監視するファイル記述子のビットマスクを作成
    my $rin = '';
    vec( $rin, fileno( $chld_out ), 1 ) = 1;

    my $self = {
        autoflush => $main::def_autoflush,  # インスタンスの出力だけを対象にする
        path_to_c => $path_to_c,
        c_pid => $pid,
        c_in  => $chld_in,
        c_out => $chld_out,
        r_c_out => $rin,
        timeout => $main::def_timeout,
        b_verbose => $main::def_b_verbose,
        formula_os => $main::def_formula_os,
    };

    bless( $self, $class );     # クラス名を関連付け

    my( $package, $filename, $line ) = caller( 0 );
    my $msg = sprintf( qq{%s: CONSTRACT: Connected the c script: pid=%d: at $filename line $line.\n},
                __PACKAGE__, $self->{c_pid} );
    $msg .= sprintf( qq{%s: CONSTRACT: timeout: %d, b_verbose: %d, formula_os=0x%02X\n},
                __PACKAGE__, $self->{timeout}, $self->{b_verbose}, $self->{formula_os} );
    $self->_vPrint( $msg );

    return $self;
}

# デストラクタ（オブジェクトが消えるときに安全に c を終了させる）
sub DESTROY
{
    my $self = shift;

    local $?; # 現在の終了ステータスをローカルに保護（DESTROY内の処理による上書きを防ぐ）

    my( $package, $filename, $line ) = caller( 0 );
    $self->_vPrintf( qq{%s: DESTROY: Terminate the c script: pid=%d: at $filename line $line.\n},
        __PACKAGE__, ( defined( $self->{c_pid} ) ? $self->{c_pid} : -1 ) );

    if( $self->{c_in} ){
        # STDINを閉じると c 側は EOF (Ctrl+D) を検知して終了する
        close( $self->{c_in} );
        undef( $self->{c_in} );
    }
    if( $self->{c_out} ){
        close( $self->{c_out} );
        undef( $self->{c_out} );
    }
    if( $self->{c_pid} ){
        # ゾンビプロセスの防止
        waitpid( $self->{c_pid}, 0 );
        undef( $self->{c_pid} );
    }
}

=over 4

=item C<formula( $FORMULA [, $SELECTION ] )>

Executes the specified calculation formula and returns the result.

Depending on the context and $SELECTION, it can return either a list or a scalar value:

  my( $y, $d ) = $c->formula( qq{age( l2e( 2026-05-01 ) )} );
  print( qq{Age: $y years, $d days old\n} );
  # Age: 0 years, 67 days old

The optional argument $SELECTION accepts a bitmask combined from the B<Formula Selection Constants> below.

=over 4

=item B<Formula Selection Constants>

The default is C<FTC_FSC_FOLLOW_VERBOSE | FTC_FSC_OUTPUT_BOTH>.

Verbosity Flags:

=over 4

=item C<FTC_FSC_FOLLOW_VERBOSE> (0x01)

Follows the global verbose setting.

=back

Output Flags:

=over 4

=item C<FTC_FSC_OUTPUT_FORMULA> (0x10)

Outputs the calculation formula only.

=item C<FTC_FSC_OUTPUT_RESULT> (0x20)

Outputs the calculation result only.

=item C<FTC_FSC_OUTPUT_BOTH> (0x30)

Outputs both the calculation formula and the result.

=back

=back

Examples:

Outputs both the formula and the result, regardless of the verbose output setting:

  my $four = $c->formula( q{1+3}, FTC_FSC_OUTPUT_BOTH );
  # Formula: "1+3"
  #  Result: 4

Produces no output by passing 0 (clearing all flags), regardless of the verbose setting:

  my $three = $c->formula( q{1+2}, 0 );

If a calculation that returns a list is evaluated in a scalar context, a reference to the list is returned.

  my $ref_results = $c->formula( qq{dhms2dhms( 0, 3, 45, 12 + 666 )} );
  print( q{resuts: }, join( ', ', @$ref_results ), "\n" );
  # resuts: 0, 3, 56, 18

Please refer to L<the c script documentation|https://github.com/tomyama-code/tomyama_script_collection/blob/main/docs/c.md> for information on the types of calculation formulas you can write.

=back

=cut

sub formula( $$;$ )
{
    my( $self, $expr, $output_sel ) = @_;
    if( !defined( $output_sel ) ){
        $output_sel = $self->_getOutputSel();
    }
    #printf( qq{\$output_sel=0x%02X\n}, $output_sel );

    $expr =~ s!\n! !go;
    $expr =~ s!\s+! !go;
    $expr =~ s!^ !!o;
    $expr =~ s! $!!o;

    if( $output_sel & FTC_FSC_OUTPUT_FORMULA ){
        if( $output_sel & FTC_FSC_FOLLOW_VERBOSE ){
            $self->_vPrintf( qq{Formula: "$expr"\n} );
        }else{
            $self->_printf( qq{Formula: "$expr"\n} );
        }
    }

    # c スクリプトの標準入力に式を書き込む
    my $fh_in = $self->{c_in};
    print $fh_in ( "$expr\n" );

    # c スクリプトからの結果（1行）を読み込む
    my $raw_result = undef;
    my $nfound = $self->_wait_c_reaction();
    if( $nfound > 0 ){
        my $fh_out = $self->{c_out};
        $raw_result = <$fh_out>;
        chomp( $raw_result );
        #print( qq{\$raw_result = "$raw_result"\n} );

        # c の出力「( 0, 0, 48, 45.779788... )」という文字列をパース
        # カッコを除去してカンマで分割
        if( $raw_result =~ m/^\s*\(\s*(.*?)\s*\)\s*$/o ){
            my @list = split( /, /, $1 );
            my $res = sprintf( qq{ Result: ( %s )\n}, join( ', ', @list ) );
            if( $output_sel & FTC_FSC_OUTPUT_RESULT ){
                if( $output_sel & FTC_FSC_FOLLOW_VERBOSE ){
                    $self->_vPrint( $res );
                }else{
                    $self->_print( $res );
                }
            }
            return wantarray ? @list : \@list;
        }
    }else{
        my $msg = "FTCalc: warn: There is no data in the standard input (likely due to a calculation error).\n";
        $msg .= qq{FTCalc: warn: Formula: "$expr"\n};
        my( $package, $filename, $line ) = caller( 0 );
        $msg .= "FTCalc: error: [FATAL] Calculation failed at $filename line $line.\n";
#        warn( $msg );
        die( $msg );
    }

    # 単一の値（リストではない場合）の処理
    if( $output_sel & FTC_FSC_OUTPUT_RESULT ){
        if( $output_sel & FTC_FSC_FOLLOW_VERBOSE ){
            $self->_vPrint( qq{ Result: $raw_result\n} );
        }else{
            $self->_print( qq{ Result: $raw_result\n} );
        }
    }
    return $raw_result;
}

sub _FtcOpen2( $$$@ )
{
    my( $chld_out, $chld_in, $path_to_c, @opts ) = @_;
    #open2 は子プロセスのプロセスIDを返します。
    #失敗した場合は値を返さず、単に /^open2:/ にマッチする例外を発生させます。
    #ただし、子プロセスでの exec の失敗は検出されません。
    #SIGPIPE は自分で捕捉（トラップ）する必要があります。
    if( &_get_action_flag( _FTC_FAIL_OPEN2 ) ){
        &_clr_action_flag( _FTC_FAIL_OPEN2 );
        print( qq{_FtcOpen2(): _FTC_FAIL_OPEN2\n} );
        my $msg = qq{_FtcOpen2(): open2: fail test\n};
        die( $msg );
    }else{
        return &IPC::Open2::open2( $chld_out, $chld_in, $path_to_c, @opts );
    }
}

=head1 FUNCTIONS

=over 4

=item C<get_default_value()>

Get the default value of the module.
Returns a hash keyed by the setting name.

  my %def_val = &FTCalc::get_default_value();
  printf( qq{def_autoflush is %d\n}, $def_val{def_autoflush} );         # def_autoflush is 1
  printf( qq{def_timeout is %f\n}, $def_val{def_timeout} );             # def_timeout is 0.500000
  printf( qq{def_b_verbose is %d\n}, $def_val{def_b_verbose} );         # def_b_verbose is 0
  printf( qq{def_formula_os is 0x%02X\n}, $def_val{def_formula_os} );   # def_formula_os is 0x31

=back

=cut

sub get_default_value()
{
    my %def_value;
    $def_value{def_autoflush} = $main::def_autoflush;
    $def_value{def_timeout}   = $main::def_timeout;
    $def_value{def_b_verbose} = $main::def_b_verbose;
    $def_value{def_formula_os} = $main::def_formula_os;
    return %def_value;
}

=over 4

=item C<set_default_value( %DEFAULT-VALUES )>

Sets the default values ​​for the module.
Specify a hash where the setting names serve as keys.

  my %def_val;
  $def_val{def_autoflush} = 1;
  $def_val{def_timeout} = 3.0;
  $def_val{def_b_verbose} = 1;
  $def_val{def_formula_os} = ( FTC_FSC_FOLLOW_VERBOSE | FTC_FSC_OUTPUT_BOTH );
  &FTCalc::set_default_value( %def_val );

=back

=cut

sub set_default_value( % )
{
    my( %def_value ) = @_;
    if( defined( $def_value{def_autoflush} ) ){
        $main::def_autoflush = $def_value{def_autoflush};
    }
    if( defined( $def_value{def_timeout} ) ){
        $main::def_timeout = $def_value{def_timeout};
    }
    if( defined( $def_value{def_b_verbose} ) ){
        $main::def_b_verbose = $def_value{def_b_verbose};
    }
    if( defined( $def_value{def_formula_os} ) ){
        $main::def_formula_os = $def_value{def_formula_os};
    }
}

sub _getAutoflush( $ )
{
    my( $self ) = @_;
    return $self->{autoflush};
}

sub _setAutoflush( $$ )
{
    my( $self, $val ) = @_;
    $self->{autoflush} = $val;
}

sub _getTimeout( $ )
{
    my( $self ) = @_;

    return $self->{timeout};
}

sub _setTimeout( $$ )
{
    my( $self, $val ) = @_;

    $self->{timeout} = $val;
}

sub _getVerbos( $ )
{
    my( $self ) = @_;
    return $self->{b_verbose};
}

sub _setVerbos( $$ )
{
    my( $self, $val ) = @_;

    $self->{b_verbose} = $val;
}

sub _getOutputSel( $ )
{
    my( $self ) = @_;
    return $self->{formula_os};
}

sub _setOutputSel( $$ )
{
    my( $self, $val ) = @_;
    #printf( qq{\$val: $val [ 0x%02X ]\n}, $val );
    $self->{formula_os} = $val;
}

sub _get_action_flag( $ )
{
    my( $flag_bit ) = @_;
    return ( $main::action_flag & $flag_bit ? 1 : 0 );
}

sub _set_action_flag( $ )
{
    my( $flag_bit ) = @_;
    $main::action_flag |= $flag_bit;
}

sub _clr_action_flag( $ )
{
    my( $flag_bit ) = @_;
    $main::action_flag &= ~$flag_bit;
}

sub _print( $@ )
{
    my( $self, @args ) = @_;
    # 出力する「その瞬間だけ」一時的に有効にする
    # 呼び出し元のハンドルまで汚染しない
    local $| = ( ( $self->{autoflush} ) ? 1 : 0 );
    print( @args );
}

sub _vPrint( $@ )
{
    my( $self, @args ) = @_;
    if( $self->{b_verbose} ){
        $self->_print( @args );
    }
}

sub _printf( $$;@ )
{
    my( $self, $format, @args ) = @_;
    # 出力する「その瞬間だけ」一時的に有効にする
    # 呼び出し元のハンドルまで汚染しない
    local $| = ( ( $self->{autoflush} ) ? 1 : 0 );
    printf( $format, @args );
}

sub _vPrintf( $$;@ )
{
    my( $self, $format, @args ) = @_;
    if( $self->{b_verbose} ){
        $self->_printf( $format, @args );
    }
}

sub _wait_c_reaction( $ )
{
    my( $self ) = @_;
    # タイムアウト時間を設定（秒数）
    my $timeout = $self->{timeout};
    my( $nfound, $timeleft ) =
        select( my $rout = $self->{r_c_out}, undef, undef, $timeout );

    return $nfound;
}

sub _get_my_path()
{
    # 自身のパッケージ名（My::Module）をファイルパスの形式（My/Module.pm）に変換
    my $module_file = __PACKAGE__ . '.pm';
    $module_file =~ s!::!/!g;

    # %INC から実際の配置パス（フルパス）を取得
    my $full_path = $INC{ $module_file };

    # ディレクトリのパスだけを抽出したい場合
    my $dir_path = &File::Basename::dirname( $full_path );

    return $dir_path;
}

1;

__END__

=head1 DEPENDENCIES

This script uses only B<core Perl modules>. No external modules from CPAN are required.

=head2 Core Modules Used

=over 4

=item * L<constant> — first included in perl 5.004

=item * L<File::Basename> — first included in perl 5

=item * L<IPC::Open2> — first included in perl 5

=item * L<parent> — first included in perl v5.10.1

=item * L<strict> — first included in perl 5

=item * L<Symbol> - first included in perl 5.002

=item * L<warnings> — first included in perl v5.6.0

=back

=head2 Survey methodology

=over 4

=item 1. Preparation

Define the script name:

  $ target_script=FTCalc.pm

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

=item L<c -- The Flat-Text Calculator (Perl Script)|https://github.com/tomyama-code/tomyama_script_collection/blob/main/docs/c.md>

=item L<perl(1)>

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

# --- ここから Pod::Coverage への指示 ---
# 先頭がアンダースコア（_）で始まるものや、
# 定数（FTC_ で始まるものなど）をドキュメント対象から除外します
package
  Pod::Coverage::FTCalc;

sub new {
    return bless {}, shift;
}

sub _is_private {
    my( $self, $sub ) = @_;
    # 例：先頭が「_」で始まるなら非公開とみなす
    return 1 if $sub =~ /^_/;
    return 0;
}
