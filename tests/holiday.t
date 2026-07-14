#!/usr/bin/env perl
use strict;
use warnings;

## Test::More was first released with perl v5.6.2
use Test::More;     # subtest()

#use lib '.';
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, '..' );
use tests::Tester;

subtest qq{Normal} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{./holiday | cat -} );
    $t->exit_is( 0, qq{./holiday | cat -} );
    $t->stdout_like( qr/^## \$Revision: 20/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{PAGER=cat ./holiday} );
    $t->exit_is( 0, qq{PAGER=cat ./holiday} );
    $t->stdout_like( qr/^## \$Revision: 20/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{PAGER=non-existent-command ./holiday} );
    $t->exit_isnt( 0, qq{PAGER=non-existent-command ./holiday} );
    $t->stdout_is( qq{}, qq{STDOUT is silent.} );
    $t->stderr_like( qr/\nnon\-existent\-command \.\/cl\.holiday: failed: status=\-1: / );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./holiday unknown_argument | cat -} );
    $t->exit_is( 0, qq{./holiday unknown_argument | cat -} );
    $t->stdout_like( qr/^## \$Revision: 20/ );
    $t->stderr_is( qq{holiday: warn: unknown_argument: unknown argument\n} );
    undef( $t );

};

subtest qq{-v, --version} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{./holiday -v} );
    $t->exit_is( 0, qq{./holiday -v} );
    $t->stdout_like( qr/^Version: \d/ );
    $t->stdout_like( qr/\n   Perl: v\d/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./holiday --version} );
    $t->exit_is( 0, qq{./holiday --version} );
    $t->stdout_like( qr/^Version: \d/ );
    $t->stdout_like( qr/\n   Perl: v\d/ );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

};

subtest qq{-h, --help} => sub{
    my $t;

    $t = tests::Tester->run_cmd( qq{./holiday -h} );
    $t->exit_is( 0, qq{./holiday -h} );
    $t->stdout_like( qr/^Usage: holiday / );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

    $t = tests::Tester->run_cmd( qq{./holiday --help} );
    $t->exit_is( 0, qq{./holiday --help} );
    $t->stdout_like( qr/^Usage: holiday / );
    $t->stderr_is( qq{}, qq{STDERR is silent.} );
    undef( $t );

};

done_testing();
