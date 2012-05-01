package EngSeqBuilder::Schema::Result::EngSeq;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
use List::Util qw( sum );
extends 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime" );

=head1 NAME

EngSeqBuilder::Schema::Result::EngSeq

=cut

__PACKAGE__->table( "eng_seq" );

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'eng_seq_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 class

  data_type: 'text'
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
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
        sequence          => "eng_seq_id_seq",
    },
    "name",
    { data_type => "text", is_nullable => 0 },
    "class",
    { data_type => "text", is_nullable => 0 },
    "type_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "description",
    { data_type => "text", default_value => "", is_nullable => 0 },
);
__PACKAGE__->set_primary_key( "id" );
__PACKAGE__->add_unique_constraint( "eng_seq_name_key", [ "name", "type_id" ] );

=head1 RELATIONS

=head2 compound_eng_seq_component_eng_seqs

Type: has_many

Related object: L<EngSeqBuilder::Schema::Result::CompoundEngSeqComponent>

=cut

__PACKAGE__->has_many(
    "compound_eng_seq_component_eng_seqs", "EngSeqBuilder::Schema::Result::CompoundEngSeqComponent",
    { "foreign.eng_seq_id" => "self.id" }, { cascade_copy => 0, cascade_delete => 0 },
);

=head2 compound_eng_seq_component_components

Type: has_many

Related object: L<EngSeqBuilder::Schema::Result::CompoundEngSeqComponent>

=cut

__PACKAGE__->has_many(
    "compound_eng_seq_component_components", "EngSeqBuilder::Schema::Result::CompoundEngSeqComponent",
    { "foreign.component_id" => "self.id" }, { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<EngSeqBuilder::Schema::Result::EngSeqType>

=cut

__PACKAGE__->belongs_to(
    "type",
    "EngSeqBuilder::Schema::Result::EngSeqType",
    { id            => "type_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 eng_seq_features

Type: has_many

Related object: L<EngSeqBuilder::Schema::Result::EngSeqFeature>

=cut

__PACKAGE__->has_many(
    "eng_seq_features", "EngSeqBuilder::Schema::Result::EngSeqFeature",
    { "foreign.eng_seq_id" => "self.id" }, { cascade_copy => 0, cascade_delete => 0 },
);

=head2 simple_eng_seq

Type: might_have

Related object: L<EngSeqBuilder::Schema::Result::SimpleEngSeq>

=cut

__PACKAGE__->might_have(
    "simple_eng_seq", "EngSeqBuilder::Schema::Result::SimpleEngSeq",
    { "foreign.id" => "self.id" }, { cascade_copy => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-07-12 14:52:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Gca7SXRsds00t6So6r7U5w

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head2 components

Type: many_to_many

Related object: L<EngSeqBuilder::Schema::Result::EngSeq>

=cut

__PACKAGE__->many_to_many( "components" => "compound_eng_seq_component_eng_seqs" => "component" );

# =head2 compounds

# Type: many_to_many

# Related object: L<EngSeqBuilder::Schema::Result::EngSeq>

# =cut

# __PACKAGE__->many_to_many(
#     "compounds" => "compound_eng_seq_component_components" => "component"
# );

=head2 add_features

Given a list of Bio::SeqFeatureI objects, insert corresponding
EngSeqFeature, EngSeqFeatureTag, and EngSeqFeatureTagValue for this
sequence.

=cut

sub add_features {
    my ( $self, $features ) = @_;

    return unless $features and @{ $features };

    for my $feature ( @{ $features } ) {
        my $eng_seq_feature = $self->create_related(
            'eng_seq_features',
            {   primary_tag   => $feature->primary_tag,
                feature_start => $feature->start,
                feature_end   => $feature->end,
                strand        => $feature->strand,
            }
        );
        for my $tag_name ( $feature->get_all_tags ) {
            my $tag = $eng_seq_feature->create_related( 'eng_seq_feature_tags', { name => $tag_name } );
            for my $tag_value ( $feature->get_tag_values( $tag_name ) ) {
                $tag->create_related( 'eng_seq_feature_tag_values', { value => $tag_value } );
            }
        }
    }

    return;
}

## no critic(ProhibitBuiltinHomonyms)
sub length {
    my $self = shift;

    if ( $self->class eq 'simple' ) {
        return length( $self->simple_eng_seq->seq );
    }
    elsif ( $self->class eq 'compound' ) {
        return sum map { $_->length } $self->components;
    }
    else {
        confess( 'length() not supported for EngSeq of class ' . $self->class );
    }
}
## use critic

around delete => sub {
    my $orig = shift;
    my $self = shift;

    $self->delete_seq_features;

    $self->$orig( @_ );
};

sub delete_seq_features {
    my $self = shift;

    for my $feature ( $self->eng_seq_features ) {
        for my $tag ( $feature->eng_seq_feature_tags ) {
            for my $value ( $tag->eng_seq_feature_tag_values ) {
                $value->delete;
            }
            $tag->delete;
        }
        $feature->delete;
    }

    return;
}
__PACKAGE__->meta->make_immutable;
1;
