#!/usr/bin/env perl
use strict;
use warnings;

use lib qx/tsc_bin_path.pl/;
use FTCalc;

my $c = FTCalc->new();

my( $day, $hour, $minute, $second ) =
    $c->formula( qq{
        dhms2dhms(
            0, 24 / SAKUBOU, 0, 0
        )
    } );

$second = $c->formula( qq{round( $second, 3 )} );

print( qq{One-day lag of the moon: } .
       qq{$hour hours $minute minutes $second seconds.\n} );
# One-day lag of the moon: 0 hours 48 minutes 45.78 seconds.

exit( 0 );
