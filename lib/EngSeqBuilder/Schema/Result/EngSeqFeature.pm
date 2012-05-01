package EngSeqBuilder::Schema::Result::EngSeqFeature;

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

EngSeqBuilder::Schema::Result::EngSeqFeature

=cut

__PACKAGE__->table( "eng_seq_feature" );

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'eng_seq_feature_id_seq'

=head2 eng_seq_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 feature_start

  data_type: 'integer'
  is_nullable: 0

=head2 feature_end

  data_type: 'integer'
  is_nullable: 0

=head2 strand

  data_type: 'integer'
  is_nullable: 0

=head2 source_tag

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 primary_tag

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "eng_seq_feature_id_seq",
    },
    "eng_seq_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "feature_start",
    { data_type => "integer", is_nullable => 0 },
    "feature_end",
    { data_type => "integer", is_nullable => 0 },
    "strand",
    { data_type => "integer", is_nullable => 0 },
    "source_tag",
    { data_type => "text", default_value => "", is_nullable => 0 },
    "primary_tag",
    { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key( "id" );

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

=head2 eng_seq_feature_tags

Type: has_many

Related object: L<EngSeqBuilder::Schema::Result::EngSeqFeatureTag>

=cut

__PACKAGE__->has_many(
    "eng_seq_feature_tags", "EngSeqBuilder::Schema::Result::EngSeqFeatureTag",
    { "foreign.eng_seq_feature_id" => "self.id" }, { cascade_copy => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-13 14:59:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HCNtyVC9eX1gt4PivgkQHQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration

use Bio::SeqFeature::Generic;

has bio_seq_feature => (
    is         => 'ro',
    isa        => 'Bio::SeqFeatureI',
    lazy_build => 1
);

sub _build_bio_seq_feature {
    my $self = shift;

    my $bio_seq_feature = Bio::SeqFeature::Generic->new(
        -primary_tag => $self->primary_tag,
        -source_tag  => $self->source_tag,
        -start       => $self->feature_start,
        -end         => $self->feature_end,
        -strand      => $self->strand
    );

    for my $tag ( $self->eng_seq_feature_tags ) {
        $bio_seq_feature->add_tag_value( $tag->name, map { $_->value } $tag->eng_seq_feature_tag_values );
    }

    return $bio_seq_feature;
}

__PACKAGE__->meta->make_immutable;
1;
