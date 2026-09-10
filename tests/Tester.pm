package tests::Tester;
################################################################################
## - $Revision: 1.14 $
################################################################################

use strict;                         # first released with perl 5
use warnings;                       # first released with perl v5.6.0

use Exporter 'import';              # first released with perl 5
our @EXPORT = qw(capture dies
    done_testing
    subtest
    note
    ok
    isa_ok
    is
    isnt
    like
    unlike
);

use Carp qw();                      # first released with perl 5
use Test::More qw();                # first released with perl v5.6.2
                                    # done_testing(), subtest(), ...

use File::Temp qw();                # first released with perl v5.6.1

use FindBin;                        # first released with perl 5.00307
use Cwd qw();                       # first released with perl 5

## --- テスト対象のコード内でexitさせない ---
#
## 本物の exit を別名で退避
#BEGIN{
#    if( !defined( &CORE::exit_real ) ){
#        *CORE::exit_real = \&CORE::GLOBAL::exit;
#    }
#}
#
## グローバルに常に exit を乗っ取る状態にする
#*CORE::GLOBAL::exit = sub{
#    my $code = shift // 0;
#    die( "EXIT_CODE: $code\n" );    # exit の代わりに die を投げる
#};
#
## テストケースの中でexitしたい場合は &POSIX::_exit( 0 ); を使うこと
## --------------------------------------------------------

my %phrase;
$phrase{apppath} = $FindBin::Bin;
$phrase{proj_root} = Cwd::getcwd();

sub done_testing()
{
    Test::More::done_testing();
}

sub subtest( $& )
{
    Test::More::subtest( @_ );
}

sub note( @ )
{
    Test::More::note( @_ );
}

sub get_phrase()
{
    return %phrase;
}

sub capture( & )
{
    my $code = shift;

    # キャプチャ用の一時ファイルを作成
    my( $tmp_out_fh, $tmp_out_file ) = File::Temp::tempfile();
    my( $tmp_err_fh, $tmp_err_file ) = File::Temp::tempfile();

    # 現在の STDOUT と STDERR を複製して退避
    open( my $old_out, ">&", \*STDOUT ) || die( $! );
    open( my $old_err, ">&", \*STDERR ) || die( $! );

    # STDOUT と STDERR の出力先を一時ファイルへ切り替え
    open( STDOUT, ">&", $tmp_out_fh ) || die( $! );
    open( STDERR, ">&", $tmp_err_fh ) || die( $! );

    # ブロックを実行（この中の出力はすべて一時ファイルへ）
    my $code_ret;
    my $ok = eval{
        # 念のためバッファリングを無効化（オートフラッシュ）
        my $old_fh = select( STDOUT ); $| = 1;
        select( STDERR ); $| = 1;
        select( $old_fh );
        $code_ret = $code->();
        1
    };
    my $e = $@; # エラーが起きた場合は捕捉しておく
    $e = undef if( $ok );
    #print( qq{\$code_ret="$code_ret"\n} );

    # 出力先を元に戻す
    open( STDOUT, ">&", $old_out ) || die( $! );
    open( STDERR, ">&", $old_err ) || die( $! );

    # 一時ファイルから中身を読み出す
    seek( $tmp_out_fh, 0, 0 );
    seek( $tmp_err_fh, 0, 0 );

    my $captured_out = do{ local $/; <$tmp_out_fh> };
    my $captured_err = do{ local $/; <$tmp_err_fh> };

    # 残骸を削除
    close( $tmp_out_fh );
    close( $tmp_err_fh );
    unlink( $tmp_out_file );
    unlink( $tmp_err_file );

    if( $e ){
#        print( qq{\$ok="$ok", \$e="$e"\n} );
#        print( qq{\$e="$e"\n} );
#        print( qq{\$captured_out="$captured_out"\n} );
#        print( qq{\$captured_err="$captured_err"\n} );
#        print( qq{\$code_ret="$code_ret"\n} );
        Carp::croak( $e )
    }  # ブロック内で死んだ場合は再スロー

    # キャプチャした文字列を返す
    return ( $captured_out, $captured_err, $code_ret );
}

sub dies( & )
{
    my $code = shift( @_ );
    defined( wantarray ) ||
        Carp::carp( "Useless use of dies() in void context" );
    local( $@, $!, $? );
    my $ok = eval{
        $code->();
        1
    };
    my $err = $@;
    if( $ok ){
        return undef;
    }
    # (省略: 例外が偽値の場合の特殊処理)
    return $err;
}

sub run_cmd( $@ )
{
    my $class = shift( @_ );
    my @cmds = @_;

    my $cmds_idx_max = scalar( @cmds );
    my @cmds_tmp = @cmds;
    for( my $idx=1; $idx<$cmds_idx_max; $idx++ ){
        $cmds_tmp[ $idx ] = q{'} . $cmds_tmp[ $idx ] . q{'};
    }
    my $cmd = join( ' ', @cmds_tmp );
    #print( qq{\$cmd="$cmd"\n}, ;

    my( $package, $filename, $line ) = caller( 0 );
    #my $cmd_str = qq{\Q$cmd\E}; # 恐らく use utf8 が必要
    my $cmd_str = $cmd;
    $cmd_str =~ s/\n/\\n/go;
    Test::More::note( qq{$filename: $line: $cmd_str\n} );

    my $exit_code = 0;
    my( $stdout, $stderr ) = capture{
        $exit_code = system( @cmds );
        $exit_code >>= 8;
    };

    my $self = {
        cmd    => $cmd,
        stdout => $stdout,
        stderr => $stderr,
        exit_code => $exit_code,
        exception => '_unused_',
    };
    bless( $self, $class );     # クラス名を関連付け

    #$self->dump();

    return $self;
}

sub run_blk( $& )
{
    my $class = shift( @_ );
    my $code = shift( @_ );

    my( $package, $filename, $line ) = caller( 0 );
    Test::More::note( qq{$filename: $line} );

    my $exit_code = 255;
    my( $stdout, $stderr, $exception ) = capture{
        return dies{
            $code->();  # ブロックの実行
            $exit_code = $?;
        };
    };

    my $self = {
        cmd    => '_unused_',
        stdout => $stdout,
        stderr => $stderr,
        exit_code => $exit_code,
        exception => $exception,
    };
    bless( $self, $class );     # クラス名を関連付け

    #$self->dump();

    return $self;
}

sub dump( $ )
{
    my( $self ) = @_;
    printf( qq{cmd="%s"\n}, $self->{cmd} );
    printf( qq{STDOUT="%s"\n}, $self->{stdout} );
    printf( qq{STDERR="%s"\n}, $self->{stderr} );
    printf( qq{exit_code="%d"\n}, $self->{exit_code} );
    printf( qq{exception="%s"\n},
        ( defined( $self->{exception} ) ? $self->{exception} : 'undef' )
    );
}

sub get_stdout( $ )
{
    my( $self ) = @_;
    return $self->{stdout};
}

sub ok( $;$ )
{
    my( $expr, $msg ) = @_;

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $msg = "expression is $expr" if( !defined( $msg ) );
    Test::More::ok( $expr, $msg );
}

sub isa_ok( $$;$ )
{
    my( $object, $class_name, $object_name ) = @_;

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $object_name = "$class_name ?" if( !defined( $object_name ) );
    Test::More::isa_ok( $object, $class_name, $object_name );
}

sub is( $$;$ )
{
    my( $got, $expected, $msg ) = @_;

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $msg = qq{$got == $expected} if( !defined( $msg ) );
    Test::More::is( $got, $expected, $msg );
}

sub isnt( $$;$ )
{
    my( $got, $expected, $name ) = @_;

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $name = qq{$got == $expected} if( !defined( $name ) );
    Test::More::isnt( $got, $expected, $name );
}

sub like( $$;$ )
{
    my( $got, $expected, $name ) = @_;

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $name = qq{like( qq{$got}, qr/$expected/ )} if( !defined( $name ) );
    Test::More::like( $got, $expected, $name );
}

sub unlike( $$;$ )
{
    my( $got, $expected, $name ) = @_;

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $name = qq{unlike( qq{$got}, qr/$expected/ )} if( !defined( $name ) );
    Test::More::unlike( $got, $expected, $name );
}

sub exit_is( $$;$ )
{
    my( $self, $expected, $msg ) = @_;
    $msg = "exit code is $expected" if( !defined( $msg ) );

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Test::More::is( $self->{exit_code}, $expected, $msg );
}

sub exit_isnt( $$;$ )
{
    my( $self, $expected, $msg ) = @_;
    $msg = "exit code is not $expected" if( !defined( $msg ) );

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Test::More::isnt( $self->{exit_code}, $expected, $msg );
}

sub has_exception( $;$ )
{
    my( $self, $msg ) = @_;

    $msg //= 'Should raise an exception (die).';

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return Test::More::ok( defined( $self->{exception} ), $msg );
}

sub has_no_exception( $;$ )
{
    my( $self, $msg ) = @_;

    $msg //= 'Should execute successfully without exception.';

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $res = Test::More::ok( !defined( $self->{exception} ), $msg );

    if( $res == 0 ){
        print( qq{exception="$self->{exception}"\n} );
    }

    return $res;
}

sub stdout_is( $$;$ )
{
    my( $self, $expected, $msg ) = @_;
    if( !defined( $msg ) ){
        $msg = "STDOUT matches";
        if( $expected eq '' ){
            $msg = "STDOUT is silent";
        }
    }

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Test::More::is( $self->{stdout}, $expected, $msg );
}

sub stderr_is( $$;$ )
{
    my( $self, $expected, $msg ) = @_;
    if( !defined( $msg ) ){
        $msg = "STDERR matches";
        if( $expected eq '' ){
            $msg = "STDERR is silent";
        }
    }

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Test::More::is( $self->{stderr}, $expected, $msg );
}

sub exception_is( $$;$ )
{
    my( $self, $expected, $msg ) = @_;
    if( !defined( $msg ) ){
        $msg = "exception matches";
        if( $expected eq '' ){
            $msg = "exception is silent";
        }
    }
    return 0 if( !defined( $self->{exception} ) );

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Test::More::is( $self->{exception}, $expected, $msg );
}

sub stdout_like( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "STDOUT matches pattern" if( !defined( $msg ) );

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Test::More::like( $self->{stdout}, $pattern, $msg );
}

sub stdout_unlike( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "STDOUT does not match pattern" if( !defined( $msg ) );

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Test::More::unlike( $self->{stdout}, $pattern, $msg );
}

sub stderr_like( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "STDERR matches pattern" if( !defined( $msg ) );

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Test::More::like( $self->{stderr}, $pattern, $msg );
}

sub stderr_unlike( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "STDERR does not match pattern" if( !defined( $msg ) );

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Test::More::unlike( $self->{stderr}, $pattern, $msg );
}

sub exception( $ )
{
    my( $self ) = @_;

    return $self->{exception};
}

sub exception_like( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "exception matches pattern" if( !defined( $msg ) );

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    if( !defined( $self->{exception} ) ){
        Test::More::ok( defined( $self->{exception} ), $msg );
        return;
    }
    Test::More::like( $self->{exception}, $pattern, $msg );
}

sub exception_unlike( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "exception does not matches pattern" if( !defined( $msg ) );

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    if( !defined( $self->{exception} ) ){
        Test::More::ok( defined( $self->{exception} ), $msg );
        return;
    }
    Test::More::unlike( $self->{exception}, $pattern, $msg );
}

1;

__END__

