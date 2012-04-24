package EngSeqBuilder::Schema::Result::CompoundEngSeqComponent;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime" );

=head1 NAME

EngSeqBuilder::Schema::Result::CompoundEngSeqComponent

=cut

__PACKAGE__->table( "compound_eng_seq_component" );

=head1 ACCESSORS

=head2 eng_seq_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 rank

  data_type: 'integer'
  is_nullable: 0

=head2 component_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "eng_seq_id",   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "rank",         { data_type => "integer", is_nullable    => 0 },
    "component_id", { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key( "eng_seq_id", "rank" );

=head1 RELATIONS

=head2 eng_seq

Type: belongs_to

Related object: L<EngSeqBuilder::Schema::Result::EngSeq>

=cut

__PACKAGE__->belongs_to(
    "eng_seq",
    "EngSeqBuilder::Schema::Result::EngSeq",
    { id            => "eng_seq_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 component

Type: belongs_to

Related object: L<EngSeqBuilder::Schema::Result::EngSeq>

=cut

__PACKAGE__->belongs_to(
    "component",
    "EngSeqBuilder::Schema::Result::EngSeq",
    { id            => "component_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-29 12:10:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A/VmOtkcSANYIKp5F9fOnQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
