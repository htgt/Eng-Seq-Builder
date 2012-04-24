#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/lib";
use MyTest::EngSeqBuilder;
use Log::Log4perl ':levels';

Log::Log4perl->easy_init( { level => $DEBUG } );

Test::Class->runtests;
