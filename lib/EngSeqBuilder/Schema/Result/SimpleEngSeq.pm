package EngSeqBuilder::Schema::Result::SimpleEngSeq;

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

EngSeqBuilder::Schema::Result::SimpleEngSeq

=cut

__PACKAGE__->table( "simple_eng_seq" );

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 seq

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id", { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "seq", { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key( "id" );

=head1 RELATIONS

=head2 id

Type: belongs_to

Related object: L<EngSeqBuilder::Schema::Result::EngSeq>

=cut

__PACKAGE__->belongs_to(
    "id",
    "EngSeqBuilder::Schema::Result::EngSeq",
    { id            => "id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-13 14:59:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KMXD766E9ZumS1+qD6advA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
