package tests::Tester;
use strict;
use warnings;

use Exporter 'import';          # first released with perl 5
our @EXPORT = qw(capture dies equal t_like
    done_testing
    subtest
    note
    ok
    isa_ok
    is
    like
    unlike
);

use Test::More;                 # first released with perl v5.6.2
                                # done_testing(), subtest(), ...

use File::Temp qw(tempfile);    # first released with perl v5.6.1

use FindBin;                    # first released with perl 5.00307
use Cwd 'getcwd';               # first released with perl 5

my %phrase;
$phrase{apppath} = $FindBin::Bin;
$phrase{proj_root} = getcwd();

sub get_phrase()
{
    return %phrase;
}

sub capture( & )
{
    my $code = shift;

    # キャプチャ用の一時ファイルを作成
    my( $tmp_out_fh, $tmp_out_file ) = &File::Temp::tempfile();
    my( $tmp_err_fh, $tmp_err_file ) = &File::Temp::tempfile();

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
        croak( $e )
    }  # ブロック内で死んだ場合は再スロー

    # キャプチャした文字列を返す
    return ( $captured_out, $captured_err, $code_ret );
}

use Carp qw(carp croak);    # first released with perl 5

sub dies( & )
{
    my $code = shift( @_ );
    defined( wantarray ) ||
        carp( "Useless use of dies() in void context" );
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
    note( qq{$filename: $line: $cmd\n} );

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
    note( qq{$filename: $line} );

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

#sub ok( $;$ )
#{
#    my( $expr, $msg ) = @_;
#    $msg = "expression is $expr" if( !defined( $msg ) );
#    ok( $expr, $msg );
#}

sub equal( $$;$ )
{
    my( $got, $expected, $name ) = @_;

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $name = qq{$got == $expected} if( !defined( $name ) );
    &Test::More::is( $got, $expected, $name );
}

sub t_like( $$;$ )
{
    my( $got, $expected, $name ) = @_;

    # 呼出元の行番号を Test::More に正しく報告するためのマジック
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $name = qq{like( qq{$got}, qr/$expected/ )} if( !defined( $name ) );
    &Test::More::like( $got, $expected, $name );
}

sub exit_is( $$;$ )
{
    my( $self, $expected, $msg ) = @_;
    $msg = "exit code is $expected" if( !defined( $msg ) );
    is( $self->{exit_code}, $expected, $msg );
}

sub exit_isnt( $$;$ )
{
    my( $self, $expected, $msg ) = @_;
    $msg = "exit code is not $expected" if( !defined( $msg ) );
    isnt( $self->{exit_code}, $expected, $msg );
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
    is( $self->{stdout}, $expected, $msg );
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
    is( $self->{stderr}, $expected, $msg );
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
    is( $self->{exception}, $expected, $msg );
}

sub stdout_like( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "STDOUT matches pattern" if( !defined( $msg ) );
    like($self->{stdout}, $pattern, $msg );
}

sub stdout_unlike( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "STDOUT does not match pattern" if( !defined( $msg ) );
    unlike($self->{stdout}, $pattern, $msg );
}

sub stderr_like( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "STDERR matches pattern" if( !defined( $msg ) );
    like($self->{stderr}, $pattern, $msg );
}

sub stderr_unlike( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "STDERR does not match pattern" if( !defined( $msg ) );
    unlike($self->{stderr}, $pattern, $msg );
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
    if( !defined( $self->{exception} ) ){
        ok( defined( $self->{exception} ), $msg );
        return;
    }
    like( $self->{exception}, $pattern, $msg );
}

sub exception_unlike( $$;$ )
{
    my( $self, $pattern, $msg ) = @_;
    $msg = "exception does not matches pattern" if( !defined( $msg ) );
    if( !defined( $self->{exception} ) ){
        ok( defined( $self->{exception} ), $msg );
        return;
    }
    unlike( $self->{exception}, $pattern, $msg );
}

1;

__END__

