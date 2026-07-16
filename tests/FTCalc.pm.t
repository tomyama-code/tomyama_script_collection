#!/usr/bin/env perl
use strict;
use warnings;

#use lib '.';
use FindBin;            # first released with perl 5.00307
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Tester;

# モジュールの読み込み
use FTCalc;


# --------------------------------------------------------
# テスト前準備（モジュールのデフォルト値の変更）とその機能のテスト
# --------------------------------------------------------
subtest 'テスト前準備: モジュールのデフォルト値を変更しておく' => sub{
    my %def_val;
    $def_val{def_autoflush} = 1;
    &FTCalc::set_default_value( %def_val );
    undef( %def_val );
    $def_val{def_timeout} = 3.0;
    &FTCalc::set_default_value( %def_val );
    undef( %def_val );
    $def_val{def_b_verbose} = 1;
    &FTCalc::set_default_value( %def_val );
    undef( %def_val );
    $def_val{def_formula_os} = ( FTC_FSC_FOLLOW_VERBOSE | FTC_FSC_OUTPUT_BOTH );
    &FTCalc::set_default_value( %def_val );
    %def_val = &FTCalc::get_default_value();
    is( $def_val{def_autoflush}, 1, 'autoflush は 1' );
    is( $def_val{def_timeout},   3, 'timeout は 3.0' );
    is( $def_val{def_b_verbose}, 1, 'b_verbose は 1' );
    is( $def_val{def_formula_os}, 0x31, 'def_formula_os は 0x31' );
};

# --------------------------------------------------------
# コンストラクタ: 異常系のテスト
# --------------------------------------------------------
subtest 'コンストラクタ: 異常系のテスト' => sub{
    &FTCalc::_set_action_flag( _FTC_FAIL_OPEN2 );
    my $t;

    $t = tests::Tester->run_blk( sub{
        my $c = FTCalc->new();
    } );
    ok( defined( $t->exception ), 'open2で正しく例外（die）が発生すること' );
    $t->exception_like(
        qr/FTCalc: _FtcOpen2\(\): Failed to start /,
        '例外メッセージにエラーキーワードが含まれていること'
    );
    $t->stdout_is( "_FtcOpen2(): _FTC_FAIL_OPEN2\n", 'テストの前提条件を満たしていること' );
    $t->stderr_is( "", 'STDERR is silent.' );
};

# --------------------------------------------------------
# インスタンスの設定値を変えるAPIのテスト
# --------------------------------------------------------
subtest 'インスタンスの設定値を変えるAPIのテスト' => sub{
    my $c;
    my( $stdout, $stderr ) = capture{
        $c = FTCalc->new();
    };
    isa_ok( $c, 'FTCalc', 'インスタンスが正しく生成できること' );
    my( $ins1_pid ) = ( $stdout =~ /^FTCalc: CONSTRACT: Connected the c script: pid=(\d+): / );
    ok( defined( $ins1_pid ), 'コンストラクタの情報が出力され、PIDが取得できること' );
    note( qq{\$ins1_pid="$ins1_pid"} );

    $c->_setAutoflush( 0 );
    my $autoflash_val = $c->_getAutoflush();
    is( $autoflash_val, 0, 'autoflashに設定した値(0)であること' );
    ( $stdout, $stderr ) = capture{
        $c->_vPrint( "It does not " );
        $c->_vPrintf( "buffer.\n" );
    };
    is( $stdout, "It does not buffer.\n", 'バッファの有無は問わず正しく出力されていること' );
    $c->_setAutoflush( 1 );
    $autoflash_val = $c->_getAutoflush();
    is( $autoflash_val, 1, 'autoflashに設定した値(1)であること' );

    my $verbos_org = $c->_getVerbos();
    $c->_setVerbos( 0 );
    my $verbos_got = $c->_getVerbos();
    is( $verbos_got, 0, 'verboseに設定した値(0)であること' );
    ( $stdout, $stderr ) = capture{
        $c->_vPrint( "123 " );
        $c->_vPrintf( "456 \n" );
    };
    is( $stdout, "", 'verboseが0なので出力されないこと' );
    $c->_setVerbos( $verbos_org );
    $verbos_got = $c->_getVerbos();
    is( $verbos_got, $verbos_org, "verboseに設定した値($verbos_org)であること" );

    my $to_org = $c->_getTimeout();
    $c->_setTimeout( 1 );
    my $to_got = $c->_getTimeout();
    is( $to_got, 1, '設定したタイムアウト値(1)であること' );
    $c->_setTimeout( $to_org );
    $to_got = $c->_getTimeout();
    is( $to_got, $to_org, "設定したタイムアウト値($to_org)であること" );

    ( $stdout, $stderr ) = capture{
        undef( $c );    # $ins1_pid はここで消える
    };
    like(
        $stdout,
        qr/FTCalc: DESTROY: Terminate the c script: pid=$ins1_pid: /,
        '$ins1_pid が正しく破棄できていること'
    );
    is( $stderr, "", 'STDERR is silent.' );
};

# --------------------------------------------------------
# 基本的な数式計算
# --------------------------------------------------------
my $c;
subtest '基本的な数式計算' => sub{
    my( $stdout, $stderr ) = capture{
        $c = FTCalc->new();
    };
    isa_ok( $c, 'FTCalc', 'インスタンスが正しく生成できること' );
    my( $ins2_pid ) = ( $stdout =~ /^FTCalc: CONSTRACT: Connected the c script: pid=(\d+): / );
    ok( defined( $ins2_pid ), 'コンストラクタの情報が出力され、PIDが取得できること' );
    note( qq{\$ins2_pid="$ins2_pid"} );
    note( qq{\$stdout="$stdout"} );

    # 戻り値（配列）の検証
    my( $day, $h, $m, $s );
    ( $stdout, $stderr ) = capture{
        ( $day, $h, $m, $s ) = $c->formula( q{
            dhms2dhms(
                0, 24 / SAKUBOU, 0, 0
            )
        }, FTC_FSC_OUTPUT_BOTH );
    };
    is( $stdout, qq{Formula: "dhms2dhms( 0, 24 / SAKUBOU, 0, 0 )"\n} .
                 qq{ Result: ( 0, 0, 48, 45.7797882084 )\n}, '計算式が1行にまとめられていること' );

    $c->_setVerbos( 0 );
    ( $stdout, $stderr ) = capture{
        $h = $c->formula( qq{( ( $h + 3 ) * 3 ) - 1}, 0 );
        $s = $c->formula( qq{round( $s, 3 )}, 0 );
    };
    is( $stdout, "", 'output_selが0なので出力されないこと' );
    $c->_setVerbos( 1 );

    note( "計算結果: $day 日 $h 時間 $m 分 $s 秒" );

    # 実際の出力 (0, 0, 48, 45.78) に合わせて期待値を修正
    is( $day, 0,     '日数が正しいこと' );
    is( $h,   8,     '時間が正しいこと' );
    is( $m,   48,    '分が正しいこと' );
    is( $s,   45.78, '秒が正しいこと' );

    # 参照で受け取る
    my $ref_age;
    ( $stdout, $stderr ) = capture{
        $ref_age = $c->formula( q{age( l2e( 2026-05-01 ) )} );
    };
    my( $y, $d ) = ( @$ref_age );
    note( "$y 年 $d 日齢" );
    like( $y, qr/^\d+$/, '年齢が数値であること' );
    like( $stdout,
        qr/^Formula: "age\( l2e\( 2026\-05\-01 \) \)"\n Result: \( \d+, \d+ \)\n$/,
        'verbose表示（計算式と結果が出力）されていること'
    );
    is( $stderr, "", 'STDERR is silent.' );

# --------------------------------------------------------
# エラーになる式の検証
# --------------------------------------------------------
    # モジュールが内部で die() して落ちるため、dies { ... } ブロックで囲んでトラップ
    my $exception;
    ( $stdout, $stderr, $exception ) = capture{
        return dies{
            my $ret = $c->formula( q{round( pi )} );
        };
    };

    # ちゃんと die して例外が発生したかを検証
    ok( defined( $exception ), '引数エラーで正しく例外（die）が発生すること' );

    # 発生した例外メッセージに期待する文字（FATALなど）が含まれているかを検証
    #print( qq{\$exception="$exception"\n} );
    like(
        $exception,
        qr/\nFTCalc: warn: Formula: "round\( pi \)"\nFTCalc: error: \[FATAL\] Calculation failed /,
        '例外メッセージが正しく出力されていること'
    );
    is( $stdout, qq{Formula: "round( pi )"\n}, '計算式だけ出力されていること' );
    is( $stderr, "", 'STDERR is silent.' );

# --------------------------------------------------------
# 複雑な書式を返す式の検証
# --------------------------------------------------------
    my $res;
    ( $stdout, $stderr ) = capture{
        $res = $c->formula( q{linspace( 0|0, 255, 3, 0 )} );
    };
    is( $res, '( 0, 128, 255 ) [ = ( 0x0, 0x80, 0xFF ) ]', 'linspace が出力する文字列が一致' );
    is( $stdout, qq{Formula: "linspace( 0|0, 255, 3, 0 )"\n} .
                 qq{ Result: ( 0, 128, 255 ) [ = ( 0x0, 0x80, 0xFF ) ]\n},
                 '計算式と結果が正しく出力されていること' );
    is( $stderr, "", 'STDERR is silent.' );

# --------------------------------------------------------
# re-generate-c-2
# --------------------------------------------------------
    ( $stdout, $stderr ) = capture{
        $c->DESTROY();
    };
    like(
        $stdout,
        qr/FTCalc: DESTROY: Terminate the c script: pid=$ins2_pid: /,
        '$ins2_pid が正しく破棄できていること'
    );
    is( $stderr, "", 'STDERR is silent.' );
    ( $stdout, $stderr ) = capture{
        undef( $c );
    };
    like(
        $stdout,
        qr/FTCalc: DESTROY: Terminate the c script: pid=-1: /,
        '$ins2_pid を重複して破棄する処理にはならないこと'
    );
    is( $stderr, "", 'STDERR is silent.' );
    ok( !defined( $c ), '$c が正しく破棄されたこと' );

    ( $stdout, $stderr ) = capture{
        $c = FTCalc->new( '--banner' );
    };
    isa_ok( $c, 'FTCalc', 're-generate-c-1: バナー付きで生成できること' );
    my( $ins3_pid ) = ( $stdout =~ /^FTCalc: CONSTRACT: Connected the c script: pid=(\d+): / );
    ok( defined( $ins3_pid ), 'コンストラクタの情報が出力され、PIDが取得できること' );
    is( $stderr, "", 'STDERR is silent.' );
    note( qq{\$ins3_pid="$ins3_pid"} );

    ( $stdout, $stderr ) = capture{
        $c = FTCalc->new();     # re-generate-c-1 はここで消える
    };
    isa_ok( $c, 'FTCalc', 're-generate-c-2: 上書きで生成できること' );
    my( $ins4_pid ) = ( $stdout =~ /^FTCalc: CONSTRACT: Connected the c script: pid=(\d+): / );
    ok( defined( $ins4_pid ), 'コンストラクタの情報が出力され、PIDが取得できること' );
    is( $stderr, "", 'STDERR is silent.' );
    note( qq{\$ins4_pid="$ins4_pid"} );
    like(
        $stdout,
        qr/FTCalc: DESTROY: Terminate the c script: pid=$ins3_pid: /,
        '$ins3_pid がこのタイミングで破棄できていること'
    );
    is( $stderr, "", 'STDERR is silent.' );

    my $four = -1;
    ( $stdout, $stderr ) = capture{
        $four = $c->formula( q{1+3} );
    };
    is( $four, 4, '再生成後のインスタンスでも計算ができること' );
    is( $stdout, qq{Formula: "1+3"\n Result: 4\n}, '計算式と結果が出力できていること' );
    is( $stderr, "", 'STDERR is silent.' );

# --------------------------------------------------------
# re-generate-c-3
# --------------------------------------------------------
    {
        my $c;  # シャドウイングで$cを生成
        ( $stdout, $stderr ) = capture{
            $c = FTCalc->new();
        };
        isa_ok( $c, 'FTCalc', 're-generate-c-3: スコープ内で新たな $c が生成できること' );
        my( $ins5_pid ) = ( $stdout =~ /^FTCalc: CONSTRACT: Connected the c script: pid=(\d+): / );
        ok( defined( $ins5_pid ), 'コンストラクタの情報が出力され、PIDが取得できること' );
        note( qq{\$ins5_pid="$ins5_pid"} );

        # 戻り値の検証
        my $pi_res;
        ( $stdout, $stderr ) = capture{
            $pi_res = $c->formula( '２ ＰＩ １０' );
        };
        is( $stdout, qq{Formula: "２ ＰＩ １０"\n Result: 62.8318530718\n}, '計算式と結果が出力できていること' );
        is( $stderr, "", 'STDERR is silent.' );
        is( $pi_res, 62.8318530718, '全角文字を含む計算が成功すること');

        ( $stdout, $stderr ) = capture{
            undef( $c );    # re-generate-c-3 はここで消える
        };
        like(
            $stdout,
            qr/FTCalc: DESTROY: Terminate the c script: pid=$ins5_pid: /,
            '$ins5_pid がこのタイミングで破棄できていること'
        );
        is( $stderr, "", 'STDERR is silent.' );
    }

    ( $stdout, $stderr ) = capture{
        undef( $c );    # re-generate-c-2 はここで消える
    };
    like(
        $stdout,
        qr/FTCalc: DESTROY: Terminate the c script: pid=$ins4_pid: /,
        '$ins4_pid がこのタイミングで破棄できていること'
    );
    is( $stderr, "", 'STDERR is silent.' );

    note( "bye!" );
};

# --------------------------------------------------------
# formatメソッドの出力選択機能のテスト
# --------------------------------------------------------
subtest 'formatメソッドの出力選択機能のテスト' => sub{
    my $c;  # シャドウイングで$cを生成
    my( $stdout, $stderr ) = capture{
        $c = FTCalc->new();
    };
    isa_ok( $c, 'FTCalc', 'インスタンスが生成できること' );
    my( $ins6_pid ) = ( $stdout =~ /^FTCalc: CONSTRACT: Connected the c script: pid=(\d+): / );
    ok( defined( $ins6_pid ), 'コンストラクタの情報が出力され、PIDが取得できること' );
    note( qq{\$ins6_pid="$ins6_pid"} );

    my $res;

    $c->_setVerbos( 0 );

    $c->_setOutputSel( 0 );
    ( $stdout, $stderr ) = capture{
        $res = $c->formula( '0+1' );
    };
    is( $stdout, "", '何も出力されない' );
    is( $stderr, "", 'STDERR is silent.' );

    $c->_setOutputSel( FTC_FSC_OUTPUT_FORMULA );
    ( $stdout, $stderr ) = capture{
        $res = $c->formula( '0+2' );
    };
    is( $stdout, qq{Formula: "0+2"\n}, '計算式だけが表示される' );
    is( $stderr, "", 'STDERR is silent.' );

    $c->_setOutputSel( FTC_FSC_OUTPUT_RESULT );
    ( $stdout, $stderr ) = capture{
        $res = $c->formula( '0+3' );
    };
    is( $stdout, qq{ Result: 3\n}, '計算結果だけが表示される' );
    is( $stderr, "", 'STDERR is silent.' );

    $c->_setOutputSel( FTC_FSC_OUTPUT_BOTH );
    ( $stdout, $stderr ) = capture{
        $res = $c->formula( '0+4' );
    };
    is( $stdout, qq{Formula: "0+4"\n Result: 4\n}, '計算式と計算結果が表示される' );
    is( $stderr, "", 'STDERR is silent.' );

    $c->_setOutputSel( FTC_FSC_FOLLOW_VERBOSE );
    ( $stdout, $stderr ) = capture{
        $res = $c->formula( '0+5' );
    };
    is( $stdout, "", '何も出力されない' );
    is( $stderr, "", 'STDERR is silent.' );

    $c->_setOutputSel( FTC_FSC_FOLLOW_VERBOSE | FTC_FSC_OUTPUT_BOTH );
    ( $stdout, $stderr ) = capture{
        $res = $c->formula( '0+6' );
    };
    is( $stdout, "", '何も出力されない' );
    is( $stderr, "", 'STDERR is silent.' );

    $c->_setOutputSel( 0 );
    ( $stdout, $stderr ) = capture{
        $res = $c->formula( '( 0, 7 )' );
    };
    is( $stdout, "", '何も出力されない' );
    is( $stderr, "", 'STDERR is silent.' );

    $c->_setOutputSel( FTC_FSC_OUTPUT_BOTH );
    ( $stdout, $stderr ) = capture{
        $res = $c->formula( '0+8', 0 );
    };
    is( $stdout, "", '何も出力されない' );
    is( $stderr, "", 'STDERR is silent.' );
};

done_testing();
