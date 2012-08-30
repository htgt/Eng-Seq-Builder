package EngSeqBuilder;

use Moose;
use MooseX::ClassAttribute;
use MooseX::Params::Validate;
use MooseX::Types::Path::Class;
use EngSeqBuilder::Config;
use EngSeqBuilder::Exception;
use EngSeqBuilder::Schema;
use EngSeqBuilder::SiteSpecificRecombination;
use EngSeqBuilder::Types qw( Strand Species );
use Bio::Seq;
use Bio::SeqUtils;
use Bio::Species;
use Bio::Annotation::Collection;
use Bio::Annotation::Comment;
use Hash::MoreUtils qw( slice_def );
use List::MoreUtils qw( any );
use Data::Dump qw( pp );
use Try::Tiny;
use Const::Fast;
use DBIx::Connector;
use namespace::autoclean;

const my $DEFAULT_SPECIES => 'mouse';

const my %BIO_SPECIES_FOR => (
    mouse => Bio::Species->new(
        -classification => [
            'Mus musculus',
            reverse qw( Eukaryota Metazoa Chordata Craniata Vertebrata Euteleostomi
                        Mammalia Eutheria Euarchontoglires Glires Rodentia
                        Sciurognathi Muroidea Muridae Murinae Mus )
        ]
    ),
    human => Bio::Species->new(
        -classification => [
            'Homo sapiens',
            reverse qw( Eukaryota Opisthokonta Metazoa Eumetazoa Bilateria Coelomata
                        Deuterostomia Chordata Craniata Vertebrata Gnathostomata
                        Teleostomi Euteleostomi Sarcopterygii Tetrapoda  Amniota
                        Mammalia Theria Eutheria Euarchontoglires Primates Haplorrhini
                        Simiiformes Catarrhini Hominoidea Hominidae Homininae Homo
                  )
        ]
    )
);

const my %ASSEMBLY_FOR => (
    mouse => 'GRCm38',
    human => 'GRCh37'
);

class_has parameter_types => (
    isa        => 'HashRef',
    lazy_build => 1,
    traits     => [ 'Hash' ],
    handles    => {
        is_known_param => 'exists',
        param_type_for => 'get'
    }
);

sub _build_parameter_types {

    const my %parameter_types => (
        chromosome          => 'Str',
        strand              => Strand,
        u_insertion         => 'HashRef',
        d_insertion         => 'HashRef',
        insertion           => 'HashRef',
        backbone            => 'HashRef',
        five_arm_start      => 'Int',
        five_arm_end        => 'Int',
        three_arm_start     => 'Int',
        three_arm_end       => 'Int',
        target_region_start => 'Int',
        target_region_end   => 'Int',
        design_id           => 'Int',
        display_id          => 'Str',
        description         => 'Str',
        transcript          => 'Str',
        recombinase         => 'ArrayRef',
        species             => Species,
        assembly            => 'Str',
    );

    return \%parameter_types;
}

sub param_type {
    my ( $self, $param_name ) = @_;

    unless ( $self->is_known_param( $param_name ) ) {
        confess "Unrecognized parameter: '$param_name'";
    }

    return $self->param_type_for( $param_name );
}

class_has parameter_defaults => (
    isa        => 'HashRef',
    lazy_build => 1,
    traits     => [ 'Hash' ],
    handles    => {
        has_param_default => 'exists',
        param_default_for => 'get'
    }
);

sub _build_parameter_defaults {

    const my %parameter_defaults => (
        species => $DEFAULT_SPECIES,
    );

    return \%parameter_defaults;
}

sub param_default {
    my ( $self, $param_name ) = @_;

    if ( $self->has_param_default( $param_name ) ) {
        return ( default => $self->param_default_for( $param_name ) );
    }

    return;
}

# param_spec() takes a list of parameter names and returns a
# specification for MooseX::Params::Validate. The type of the
# parameter is looked up via param_type(). If the parameter name ends
# with '*', the asterisk is stripped and that parameter considered
# optional.

sub param_spec {
    my ( $self, @params ) = @_;

    my @param_spec;

    for my $param_name ( @params ) {
        my $optional = $param_name =~ s/\*$// ? 1 : 0;
        my $type = $self->param_type( $param_name );
        push @param_spec, $param_name => { isa => $type, optional => $optional, $self->param_default( $param_name ) };
    }

    return @param_spec;
}

has configfile => (
    is      => 'ro',
    isa     => 'Path::Class::File',
    coerce  => 1,
    default => sub { Path::Class::file( $ENV{ ENG_SEQ_BUILDER_CONF } ) }
);

has config => (
    is         => 'ro',
    isa        => 'EngSeqBuilder::Config',
    lazy_build => 1
);

sub _build_config {
    my $self = shift;

    return EngSeqBuilder::Config->new_with_config( configfile => $self->configfile );
}

has append_seq_length => (
    is      => 'ro',
    isa     => 'Int',
    default => 15050,
);

has schema => (
    isa        => 'EngSeqBuilder::Schema',
    reader     => '_schema',
    lazy_build => 1,
    handles    => [ 'txn_do', 'txn_rollback' ]
);

{
    my %connector_for;

    sub _build_schema {
        my $self = shift;

        my ( $dsn, $user, $pass, $attr ) = $self->config->db_connect_params;

        if ( ! $connector_for{$dsn}{$user} ) {
            $connector_for{$dsn}{$user} = DBIx::Connector->new( $dsn, $user, $pass, $attr );
        }

        return EngSeqBuilder::Schema->connect( sub { $connector_for{$dsn}{$user}->dbh } );
    }
}

has max_vector_seq_length => (
    is         => 'rw',
    isa        => 'Int',
    lazy_build => 1
);

sub _build_max_vector_seq_length {
    return shift->config->max_vector_seq_length;
}

with qw( MooseX::Log::Log4perl EngSeqBuilder::Rfetch );

sub bio_species_for {
    my ( $self, $species ) = @_;

    EngSeqBuilder::Exception->throw( 'No Bio::Species configured for ' . $species )
            unless exists $BIO_SPECIES_FOR{ lc $species };

    return $BIO_SPECIES_FOR{ lc $species };
}

sub assembly_for {
    my ( $self, $species ) = @_;

    EngSeqBuilder::Exception->throw( 'No assembly configured for ' . $species )
            unless exists $ASSEMBLY_FOR{ lc $species };

    return $ASSEMBLY_FOR{ lc $species };
}

sub list_seqs {
    my ( $self, @args ) = @_;

    my %params = validated_hash( \@args, type => { isa => 'Str', optional => 1 } );

    my $rs;

    if ( $params{ type } ) {
        $rs = $self->_schema->resultset( 'EngSeq' )->search( { 'type.name' => $params{ type } }, { join => 'type', prefetch => 'type' } );
    }
    else {
        $rs = $self->_schema->resultset( 'EngSeq' )->search( {}, { prefetch => 'type' } );
    }

    return [ map { +{ name => $_->name, type => $_->type->name } } $rs->all ];
}

sub list_components {
    my ( $self, @args ) = @_;

    my %params = validated_hash(
        \@args,
        name => { isa => 'Str' },
        type => { isa => 'Str', optional => 1 },
    );

    my $eng_seq = $self->_fetch_seq( $params{ name }, $params{ type } );

    if ( $eng_seq->class eq 'simple' ) {
        return $eng_seq->name;
    }
    else {
        return [
            $eng_seq->name,
            [   map { $self->list_components( name => $_->component->name ) }
                sort { $a->rank <=> $b->rank } $eng_seq->compound_eng_seq_component_eng_seqs
            ]
        ];
    }
}

sub create_simple_seq {
    my ( $self, @args ) = @_;

    my %params = validated_hash(
        \@args,
        name        => { isa => 'Str' },
        description => { isa => 'Str', default => '' },
        type        => { isa => 'Str' },
        seq         => { isa => 'Str' },
        features    => { isa => 'ArrayRef[Bio::SeqFeatureI]', optional => 1 }
    );

    $params{ class } = 'simple';
    my $bio_seq;

    $self->txn_do(
        sub {
            my $eng_seq = $self->_create_eng_seq( \%params );
            $eng_seq->create_related( 'simple_eng_seq', { seq => $params{ seq } } );
            $eng_seq->add_features( $params{ features } );
            $bio_seq = $self->_mk_bio_seq( $eng_seq );
        }
    );

    return $bio_seq;
}

sub create_compound_seq {
    my ( $self, @args ) = @_;

    my %params = validated_hash(
        \@args,
        name              => { isa => 'Str' },
        description       => { isa => 'Str', default => '' },
        type              => { isa => 'Str' },
        features          => { isa => 'ArrayRef[Bio::SeqFeatureI]', optional => 1 },
        components        => { isa => 'ArrayRef' },
        whole_seq_feature => { isa => 'Bio::SeqFeatureI', optional => 1 },
    );

    $params{ class } = 'compound';
    $params{ features } ||= [];

    my $bio_seq;

    $self->txn_do(
        sub {
            my $eng_seq = $self->_create_eng_seq( \%params );
            my $rank    = 0;
            for my $component_name ( @{ $params{ components } } ) {
                my $component = $self->_schema->resultset( 'EngSeq' )->find( { name => $component_name } )
                    or EngSeqBuilder::Exception->throw( "Failed to retrieve component $component_name" );
                $eng_seq->create_related(
                    'compound_eng_seq_component_eng_seqs',
                    {   rank         => $rank,
                        component_id => $component->id
                    }
                );
                $rank++;
            }
            if ( my $f = $params{ whole_seq_feature } ) {
                $f->start( 1 );
                $f->end( $eng_seq->length );
                $f->strand( 1 );
                push @{ $params{ features } }, $f;
            }
            $eng_seq->add_features( $params{ features } );
            $bio_seq = $self->_mk_bio_seq( $eng_seq );
        }
    );

    return $bio_seq;
}

## no critic(RequireFinalReturn)
sub _fetch_seq {
    my ( $self, $name, $type ) = @_;
    my $eng_seq_rs;

    if ( $type ) {
        $eng_seq_rs = $self->_schema->resultset( 'EngSeq' )->search(
            {   'me.name'   => $name,
                'type.name' => $type
            },
            { join => 'type' }
        );
    }
    else {
        $eng_seq_rs = $self->_schema->resultset( 'EngSeq' )->search( { name => $name } );
    }

    my $count = $eng_seq_rs->count;
    if ( $count == 1 ) {
        return $eng_seq_rs->first;
    }
    elsif ( $count > 1 ) {
        EngSeqBuilder::Exception->throw( "Found multiple sequences with name '$name' - try specifying type" );
    }
    else {    # count == 0
        EngSeqBuilder::Exception->throw( sprintf "Found no sequences with name '%s' of type '%s'",
            $name, $type ? $type : 'ANY' );
    }
}
## use critic

sub fetch_seq {
    my ( $self, @args ) = @_;

    my %params = validated_hash(
        \@args,
        name               => { isa => 'Str' },
        include_transcript => { isa => 'Str', optional => 1 },
        type               => { isa => 'Str', optional => 1 },
    );

    return $self->_mk_bio_seq( $self->_fetch_seq( $params{ name }, $params{ type } ), \%params );
}

sub delete_seq {
    my ( $self, @args ) = @_;

    my %params = validated_hash(
        \@args,
        name => { isa => 'Str' },
        type => { isa => 'Str', optional => 1 },
    );

    $self->log->debug( "Delete sequence: '$params{name}'" );

    $self->txn_do(
        sub {
            my $eng_seq = $self->_fetch_seq( $params{ name }, $params{ type } );
            EngSeqBuilder::Exception->throw( "cannot delete a component of a compound sequence" )
                if $eng_seq->compound_eng_seq_component_components_rs->count > 0;
            if ( $eng_seq->class eq 'simple' ) {
                $eng_seq->search_related_rs( 'simple_eng_seq' )->delete;
            }
            elsif ( $eng_seq->class eq 'compound' ) {
                $eng_seq->search_related_rs( 'compound_eng_seq_component_eng_seqs' )->delete;
            }
            $self->log->info( "Deleting eng_seq '$params{name}'" );
            $eng_seq->delete;
        }
    );

    return;
}

sub conditional_vector_seq {
    my ( $self, @args ) = @_;

    my %params = validated_hash(
        \@args,
        $self->param_spec(
            qw( chromosome
                strand
                backbone
                five_arm_start
                five_arm_end
                u_insertion
                target_region_start
                target_region_end
                d_insertion
                three_arm_start
                three_arm_end
                display_id*
                design_id*
                transcript*
                description*
                recombinase*
                species*
                assembly*
                )
        )
    );

    $self->log->trace( sub { 'conditonal_vector_seq: ' . pp( \%params ) } );

    my $rfetch_params = $self->_build_rfetch_params( \%params );

    my $seq = $self->_initialise_bio_seq( \%params );
    $seq->is_circular( 1 );

    Bio::SeqUtils->cat(
        $seq,
        $self->fetch_seq( %{ $params{ backbone } } ),
        $self->rfetch_seq(
            @{ $rfetch_params },
            seq_region_start   => $params{ five_arm_start },
            seq_region_end     => $params{ five_arm_end },
            whole_feature_name => Bio::SeqFeature::Generic->new(
                -primary => 'misc_feature',
                -tag     => { note => '5 arm' },
                -strand  => 1,
            ),
        ),
        $self->fetch_seq( %{ $params{ u_insertion } } ),
        $self->rfetch_seq(
            @{ $rfetch_params },
            seq_region_start   => $params{ target_region_start },
            seq_region_end     => $params{ target_region_end },
            targeted           => 1,
            whole_feature_name => Bio::SeqFeature::Generic->new(
                -primary => 'misc_feature',
                -tag     => { note => 'Critical Region' },
                -strand  => 1,
            ),
        ),
        $self->fetch_seq( %{ $params{ d_insertion } } ),
        $self->rfetch_seq(
            @{ $rfetch_params },
            seq_region_start   => $params{ three_arm_start },
            seq_region_end     => $params{ three_arm_end },
            whole_feature_name => Bio::SeqFeature::Generic->new(
                -primary => 'misc_feature',
                -tag     => { note => '3 arm' },
                -strand  => 1,
            ),
        )
    );

    return $self->apply_recombinase( $seq, $params{ recombinase } );
}

sub _ins_del_vector_seq {
    my ( $self, @args ) = @_;

    my %params = validated_hash(
        \@args,
        $self->param_spec(
            qw( chromosome
                strand
                backbone
                five_arm_start
                five_arm_end
                insertion
                three_arm_start
                three_arm_end
                display_id*
                design_id*
                transcript*
                description*
                recombinase*
                species*
                assembly*
                )
        )
    );

    $self->log->trace( sub { '_ins_del_vector_seq: ' . pp( \%params ) } );

    my $rfetch_params = $self->_build_rfetch_params( \%params );

    my $seq = $self->_initialise_bio_seq( \%params );
    $seq->is_circular( 1 );

    Bio::SeqUtils->cat(
        $seq,
        $self->fetch_seq( %{ $params{ backbone } } ),
        $self->rfetch_seq(
            @{ $rfetch_params },
            seq_region_start   => $params{ five_arm_start },
            seq_region_end     => $params{ five_arm_end },
            whole_feature_name => Bio::SeqFeature::Generic->new(
                -primary => 'misc_feature',
                -tag     => { note => '5 arm' },
                -strand  => 1,
            ),
        ),
        $self->fetch_seq( %{ $params{ insertion } } ),
        $self->rfetch_seq(
            @{ $rfetch_params },
            seq_region_start   => $params{ three_arm_start },
            seq_region_end     => $params{ three_arm_end },
            whole_feature_name => Bio::SeqFeature::Generic->new(
                -primary => 'misc_feature',
                -tag     => { note => '3 arm' },
                -strand  => 1,
            ),
        )
    );

    return $self->apply_recombinase( $seq, $params{ recombinase } );
}

sub insertion_vector_seq {
    my ( $self, @args ) = @_;
    return $self->_ins_del_vector_seq( @args );
}

sub deletion_vector_seq {
    my ( $self, @args ) = @_;
    return $self->_ins_del_vector_seq( @args );
}

sub conditional_allele_seq {
    my ( $self, @args ) = @_;

    my %params = validated_hash(
        \@args,
        $self->param_spec(
            qw( chromosome
                strand
                five_arm_start
                five_arm_end
                u_insertion
                target_region_start
                target_region_end
                d_insertion
                three_arm_start
                three_arm_end
                display_id*
                design_id*
                transcript*
                description*
                recombinase*
                species*
                assembly*
                )
        )
    );

    $self->log->trace( sub { 'conditional_allele_seq: ' . pp( \%params ) } );

    my $rfetch_params = $self->_build_rfetch_params( \%params );

    my $seq = $self->_initialise_bio_seq( \%params );

    Bio::SeqUtils->cat(
        $seq,
        $self->_get_allele_five_arm_seq( $rfetch_params, \%params ),
        $self->fetch_seq( %{ $params{ u_insertion } } ),
        $self->rfetch_seq(
            @{ $rfetch_params },
            seq_region_start   => $params{ target_region_start },
            seq_region_end     => $params{ target_region_end },
            targeted           => 1,
            whole_feature_name => Bio::SeqFeature::Generic->new(
                -primary => 'misc_feature',
                -tag     => { note => 'Critical Region' },
                -strand  => 1,
            ),
        ),
        $self->fetch_seq( %{ $params{ d_insertion } } ),
        $self->_get_allele_three_arm_seq( $rfetch_params, \%params ),
    );

    return $self->apply_recombinase( $seq, $params{ recombinase } );
}

sub targeted_trap_allele_seq {
    my ( $self, @args ) = @_;

    my %params = validated_hash(
        \@args,
        $self->param_spec(
            qw( chromosome
                strand
                five_arm_start
                five_arm_end
                u_insertion
                target_region_start
                target_region_end
                three_arm_start
                three_arm_end
                display_id*
                design_id*
                transcript*
                description*
                recombinase*
                species*
                assembly*
                )
        )
    );

    # XXX TODO: this code assumes cassette is in the U-insertion;
    # should handle cassette in D-insertion as a legitimate alternative

    $self->log->trace( sub { 'targeted_trap_allele_seq: ' . pp( \%params ) } );

    my $rfetch_params = $self->_build_rfetch_params( \%params );

    my $seq = $self->_initialise_bio_seq( \%params );

    my ( $loxp_start, $loxp_end );
    if ( $params{ strand } == 1 ) {
        $loxp_start = $params{ target_region_end } + 1;
        $loxp_end   = $params{ three_arm_start } - 1;
    }
    else {
        $loxp_start = $params{ three_arm_end } + 1;
        $loxp_end   = $params{ target_region_start } - 1;
    }

    my $loxp;
    if ( $loxp_end >= $loxp_start ) {
        $loxp = $self->rfetch_seq(
            @{ $rfetch_params },
            seq_region_start => $loxp_start,
            seq_region_end   => $loxp_end
        );
    }
    else {
        $loxp = Bio::Seq->new( -alphabet => 'dna', -seq => '' );
    }

    Bio::SeqUtils->cat(
        $seq,
        $self->_get_allele_five_arm_seq( $rfetch_params, \%params ),
        $self->fetch_seq( %{ $params{ u_insertion } } ),
        $self->rfetch_seq(
            @{ $rfetch_params },
            seq_region_start   => $params{ target_region_start },
            seq_region_end     => $params{ target_region_end },
            targeted           => 1,
            whole_feature_name => Bio::SeqFeature::Generic->new(
                -primary => 'misc_feature',
                -tag     => { note => 'Critical Region' },
                -strand  => 1,
            ),
        ),
        $loxp,
        $self->_get_allele_three_arm_seq( $rfetch_params, \%params ),
    );

    return $self->apply_recombinase( $seq, $params{ recombinase } );
}

sub insertion_allele_seq {
    my ( $self, @args ) = @_;
    return $self->_ins_del_allele_seq( @args );
}

sub deletion_allele_seq {
    my ( $self, @args ) = @_;
    return $self->_ins_del_allele_seq( @args );
}

sub apply_recombinase {
    my ( $self, $seq, $recombinases ) = @_;

    return $seq
        unless $recombinases and @{ $recombinases };

    my $res = $seq;

    for my $recombinase ( @{ $recombinases } ) {
        $res = EngSeqBuilder::SiteSpecificRecombination::apply_recombinase( $res, $recombinase );
    }

    return $res;
}

sub _ins_del_allele_seq {
    my ( $self, @args ) = @_;

    my %params = validated_hash(
        \@args,
        $self->param_spec(
            qw( chromosome
                strand
                five_arm_start
                five_arm_end
                insertion
                three_arm_start
                three_arm_end
                display_id*
                design_id*
                transcript*
                description*
                recombinase*
                species*
                assembly*
                )
        )
    );

    $self->log->trace( sub { '_ins_del_allele_seq: ' . pp( \%params ) } );

    my $rfetch_params = $self->_build_rfetch_params( \%params );

    my $seq = $self->_initialise_bio_seq( \%params );

    Bio::SeqUtils->cat(
        $seq,
        $self->_get_allele_five_arm_seq( $rfetch_params, \%params ),
        $self->fetch_seq( %{ $params{ insertion } } ),
        $self->_get_allele_three_arm_seq( $rfetch_params, \%params ),
    );

    return $self->apply_recombinase( $seq, $params{ recombinase } );
}

sub _get_allele_five_arm_seq {
    my ( $self, $rfetch_params, $params ) = @_;
    my ( $flank_genomic_start, $flank_genomic_end );

    if ( ( $params->{ five_arm_end } - $params->{ five_arm_start } + 1 ) > $self->append_seq_length ) {
        $flank_genomic_start = $params->{ five_arm_start };
        $flank_genomic_end   = $params->{ five_arm_end };
    }
    elsif ( $params->{ strand } == 1 ) {
        $flank_genomic_start = $params->{ five_arm_end } - $self->append_seq_length + 1;
        $flank_genomic_end   = $params->{ five_arm_end };
    }
    elsif ( $params->{ strand } == -1 ) {
        $flank_genomic_start = $params->{ five_arm_start };
        $flank_genomic_end   = $params->{ five_arm_start } + $self->append_seq_length - 1;
    }

    my $seq = $self->rfetch_seq(
        @{ $rfetch_params },
        seq_region_start => $flank_genomic_start,
        seq_region_end   => $flank_genomic_end
    );

    my ( $five_arm_feat_start, $five_arm_feat_end ) = $self->_slice_rel_coord(
        $flank_genomic_start, $flank_genomic_end,
        $params->{ strand },
        $params->{ five_arm_start },
        $params->{ five_arm_end }
    );

    my $five_arm_feat = Bio::SeqFeature::Generic->new(
        -strand      => 1,
        -primary_tag => 'misc_feature',
        -tag         => { note => '5 arm' },
        -start       => $five_arm_feat_start,
        -end         => $five_arm_feat_end,
    );
    $seq->add_SeqFeature( $five_arm_feat );

    return $seq;
}

sub _get_allele_three_arm_seq {
    my ( $self, $rfetch_params, $params ) = @_;
    my ( $flank_genomic_start, $flank_genomic_end );

    if ( ( $params->{ three_arm_end } - $params->{ three_arm_start } + 1 ) > $self->append_seq_length ) {
        $flank_genomic_start = $params->{ three_arm_start };
        $flank_genomic_end   = $params->{ three_arm_end };
    }
    elsif ( $params->{ strand } == 1 ) {
        $flank_genomic_start = $params->{ three_arm_start };
        $flank_genomic_end   = $params->{ three_arm_start } + $self->append_seq_length - 1;
    }
    else {
        $flank_genomic_start = $params->{ three_arm_end } - $self->append_seq_length + 1;
        $flank_genomic_end   = $params->{ three_arm_end };
    }

    my $seq = $self->rfetch_seq(
        @{ $rfetch_params },
        seq_region_start => $flank_genomic_start,
        seq_region_end   => $flank_genomic_end,
    );

    my ( $three_arm_feat_start, $three_arm_feat_end ) = $self->_slice_rel_coord(
        $flank_genomic_start, $flank_genomic_end,
        $params->{ strand },
        $params->{ three_arm_start },
        $params->{ three_arm_end }
    );

    my $three_arm_feat = Bio::SeqFeature::Generic->new(
        -strand      => 1,
        -primary_tag => 'misc_feature',
        -tag         => { note => '3 arm' },
        -start       => $three_arm_feat_start,
        -end         => $three_arm_feat_end,
    );
    $seq->add_SeqFeature( $three_arm_feat );

    return $seq;
}

sub _slice_rel_coord {
    my ( $self, $slice_genomic_start, $slice_genomic_end, $strand, $genomic_coord_start, $genomic_coord_end ) = @_;

    my ( $start, $end );
    if ( $strand == 1 ) {
        $start = $genomic_coord_start - $slice_genomic_start + 1;
        $end   = $genomic_coord_end - $slice_genomic_start + 1;
    }
    else {
        $start = $slice_genomic_end - $genomic_coord_end + 1;
        $end   = $slice_genomic_end - $genomic_coord_start + 1;
    }
    return ( $start, $end );
}

sub _check_seq_length {
    my ( $self, $params ) = @_;

    my $length;

    if ( $params->{ strand } == 1 ) {
        $length = $params->{ three_arm_end } - $params->{ five_arm_start };
    }
    else {
        $length = $params->{ five_arm_end } - $params->{ three_arm_start };
    }

    if ( $length > $self->max_vector_seq_length ) {
        EngSeqBuilder::Exception->throw( sprintf 'Sequence length (%d) exceeds maximum permitted (%d)',
            $length, $self->max_vector_seq_length );
    }

    return;
}

sub _build_rfetch_params {
    my ( $self, $params ) = @_;

    # The targeting repository stores negative-stranded coordinate in
    # the opposite order from that expected by EnsEMBL.
    for ( qw( five_arm three_arm target_region ) ) {
        my ( $start_key, $end_key ) = ( $_ . '_start', $_ . '_end' );
        if ( exists $params->{ $start_key } && $params->{ $start_key } > $params->{ $end_key } ) {
            @{ $params }{ $start_key, $end_key } = @{ $params }{ $end_key, $start_key };
        }
    }

    $self->_check_seq_length( $params );

    my @rfetch_params = (
        species           => $params->{ species },
        version           => ( $params->{ assembly } || $self->assembly_for( $params->{ species } ) ),
        seq_region_name   => $params->{ chromosome },
        seq_region_strand => $params->{ strand },
    );
    push @rfetch_params, ( include_transcript => $params->{ transcript } ) if $params->{ transcript };

    return \@rfetch_params;
}

sub _initialise_bio_seq {
    my ( $self, $params ) = @_;

    my $seq = Bio::Seq->new( -alphabet => 'dna' );

    $seq->display_id( $params->{ display_id } || 'synthetic_sequence' );
    $seq->desc( $params->{ description } ) if $params->{ description };
    $seq->species( $self->bio_species_for( $params->{species} ) );

    my $annotations = $self->_get_seq_annotations( $params );
    $seq->annotation( $annotations ) if $annotations;

    return $seq;
}

sub _get_seq_annotations {
    my ( $self, $params ) = @_;

    my $annotation_collection = Bio::Annotation::Collection->new;

    my $cassette_name;
    for my $pname ( qw( u_insertion d_insertion insertion ) ) {
        if ( $params->{ $pname } ) {
            my $s = $self->_fetch_seq( @{ $params->{ $pname } }{ qw( name ) } );
            if ( $s->type->name =~ m/cassette/ ) {
                $cassette_name = $s->name;
                last;
            }
        }
    }

    if ( $cassette_name ) {
        my $cassette = Bio::Annotation::Comment->new( -text => 'cassette: ' . $cassette_name );
        $annotation_collection->add_Annotation( 'comment', $cassette );
    }

    if ( $params->{design_id} ) {
        my $design = Bio::Annotation::Comment->new( -text => 'design_id: ' . $params->{ design_id } );
        $annotation_collection->add_Annotation( 'comment', $design );
    }

    if ( $params->{backbone} ) {
        my $backbone = Bio::Annotation::Comment->new( -text => 'backbone: ' . $params->{ backbone }->{ name } );
        $annotation_collection->add_Annotation( 'comment', $backbone );
    }

    return $annotation_collection;
}

sub _create_eng_seq {
    my ( $self, $params ) = @_;

    my $eng_seq_type = $self->_schema->resultset( 'EngSeqType' )->find( { name => $params->{ type } } )
        or EngSeqBuilder::Exception->throw( "Invalid type: '$params->{type}'" );

    my $eng_seq = $eng_seq_type->create_related(
        'eng_seqs',
        {   name        => $params->{ name },
            class       => $params->{ class },
            description => $params->{ description }
        }
    );

    $self->log->info( "Created $params->{type} eng_seq '$params->{name}' with id: " . $eng_seq->id );

    return $eng_seq;
}

sub _mk_bio_seq {
    my ( $self, $eng_seq, $params ) = @_;

    my $bio_seq = Bio::Seq->new( -alphabet => 'dna' );

    if ( $eng_seq->class eq 'simple' ) {
        $bio_seq = Bio::Seq->new(
            -alphabet => 'dna',
            -seq      => $eng_seq->simple_eng_seq->seq
        );
    }
    elsif ( $eng_seq->class eq 'compound' ) {
        $bio_seq = Bio::Seq->new( -alphabet => 'dna', -seq => '' );
        my @components = map { $self->_mk_bio_seq( $_->component, $params ) }
            sort { $a->rank <=> $b->rank } $eng_seq->compound_eng_seq_component_eng_seqs;
        Bio::SeqUtils->cat( $bio_seq, @components );
    }

    $bio_seq->primary_id( $eng_seq->id );
    ( my $display_id = $eng_seq->name ) =~ s/\s+/_/g;
    $bio_seq->display_id( $display_id );

    if ( my $desc = $eng_seq->description ) {
        $bio_seq->description( $desc );
    }

    for my $feature ( $eng_seq->eng_seq_features ) {
        $bio_seq->add_SeqFeature( $feature->bio_seq_feature );
    }

    return $bio_seq;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
