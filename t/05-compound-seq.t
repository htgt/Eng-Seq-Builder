#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use EngSeqBuilder;
use Data::Dump 'dd';

my $schema = EngSeqBuilder::Schema->connect( 'dbi:SQLite:dbname=:memory:', '', '', { AutoCommit => 1 } );
$schema->deploy;        
$schema->populate( 'EngSeqType', [ [ 'id', 'name' ], [ 1, 'test' ] ] );

my %eng_seq;

ok my $A = $schema->resultset( 'EngSeq' )->create( { name => 'A', type_id => 1, class => 'simple' } ), "create A";
ok my $B = $schema->resultset( 'EngSeq' )->create( { name => 'B', type_id => 1, class => 'simple' } ), "create B";
ok my $C = $schema->resultset( 'EngSeq' )->create( { name => 'C', type_id => 1, class => 'compound' } ), "create C";

ok $C->create_related( 'compound_eng_seq_component_eng_seqs',
                       { component_id => $A->id, rank => 0 } ), 'create component A';

ok $C->create_related( 'compound_eng_seq_component_eng_seqs',
                       { component_id => $B->id, rank => 1 } ), 'create component B';

my @components = map { $_->component->name } sort { $a->rank <=> $b->rank } $C->compound_eng_seq_component_eng_seqs;

is_deeply \@components, [ 'A', 'B' ], 'Got expected components';

is_deeply [ map $_->eng_seq->name, $C->compound_eng_seq_component_components ], [], 'C is not a component';

is_deeply [ map $_->eng_seq->name, $A->compound_eng_seq_component_components ], [ 'C' ], 'A is a component of C';

is_deeply [ map $_->eng_seq->name, $A->compound_eng_seq_component_components ], [ 'C' ], 'B is a component of C';

ok $C->compound_eng_seq_component_eng_seqs_rs->delete, 'delete components of C';

is_deeply [ map $_->componet->name, $C->compound_eng_seq_component_eng_seqs ], [], 'C has no components';

is $C->compound_eng_seq_component_eng_seqs_rs->count, 0, 'count of component_eng_seqs is 0';

is_deeply [ map $_->eng_seq->name, $A->compound_eng_seq_component_components ], [], 'A is not a component of C';

is $A->compound_eng_seq_component_components_rs->count, 0, 'count of A compunds is 0';

is_deeply [ map $_->eng_seq->name, $A->compound_eng_seq_component_components ], [], 'B is not a component of C';

is $B->compound_eng_seq_component_components_rs->count, 0, 'count of B compunds is 0';

done_testing;




