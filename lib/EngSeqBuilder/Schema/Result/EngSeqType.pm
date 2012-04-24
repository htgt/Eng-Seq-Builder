package EngSeqBuilder::Schema::Result::EngSeqType;

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

EngSeqBuilder::Schema::Result::EngSeqType

=cut

__PACKAGE__->table( "eng_seq_type" );

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'eng_seq_type_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "eng_seq_type_id_seq",
    },
    "name",
    { data_type => "text", is_nullable => 0 },
    "description",
    { data_type => "text", default_value => "", is_nullable => 0 },
);
__PACKAGE__->set_primary_key( "id" );
__PACKAGE__->add_unique_constraint( "eng_seq_type_name_key", [ "name" ] );

=head1 RELATIONS

=head2 eng_seqs

Type: has_many

Related object: L<EngSeqBuilder::Schema::Result::EngSeq>

=cut

__PACKAGE__->has_many(
    "eng_seqs",
    "EngSeqBuilder::Schema::Result::EngSeq",
    { "foreign.type_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-07-12 14:52:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Kra87K8ekwDrFBGyBMcaWw

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
