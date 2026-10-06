#!/usr/bin/perl -I.

use strict;
use warnings;

eval { require AnyEvent::Impl::Perl; require AnyEvent; };
if ($@) {
    print "1..0 # Skip AnyEvent not installed\n";
    exit 0;
}
use FindBin;
use IO::Event;
IO::Event->import('AnyEvent');
require "$FindBin::Bin/callbacks.tt";

