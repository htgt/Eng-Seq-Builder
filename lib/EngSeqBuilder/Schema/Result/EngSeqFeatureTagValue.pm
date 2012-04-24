package EngSeqBuilder::Schema::Result::EngSeqFeatureTagValue;

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

EngSeqBuilder::Schema::Result::EngSeqFeatureTagValue

=cut

__PACKAGE__->table( "eng_seq_feature_tag_value" );

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'eng_seq_feature_tag_value_id_seq'

=head2 eng_seq_feature_tag_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "eng_seq_feature_tag_value_id_seq",
    },
    "eng_seq_feature_tag_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "value",
    { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key( "id" );
__PACKAGE__->add_unique_constraint(
    "eng_seq_feature_tag_value_eng_seq_feature_tag_id_key",
    [ "eng_seq_feature_tag_id", "value" ],
);

=head1 RELATIONS

=head2 eng_seq_feature_tag

Type: belongs_to

Related object: L<EngSeqBuilder::Schema::Result::EngSeqFeatureTag>

=cut

__PACKAGE__->belongs_to(
    "eng_seq_feature_tag",
    "EngSeqBuilder::Schema::Result::EngSeqFeatureTag",
    { id            => "eng_seq_feature_tag_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-13 14:59:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1Qr2gRXBxqfPYOG5N9czSw

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
