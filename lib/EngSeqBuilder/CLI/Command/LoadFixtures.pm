package EngSeqBuilder::CLI::Command::LoadFixtures;

use Moose;
use MooseX::Types::Path::Class;
use EngSeqBuilder::Util qw( is_exact_feature );
use Bio::SeqIO;
use Bio::SeqUtils;
use YAML::Any;
use namespace::autoclean;

extends 'EngSeqBuilder::CLI::Command';

override abstract => sub {'Load fixture data into the database (development only)'};

has fixtures_dir => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    traits   => [ 'Getopt' ],
    cmd_flag => 'component_dir',
    required => 1
);

has mutant_sequence_fixtures_dir => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    traits   => [ 'Getopt' ],
    cmd_flag => 'mut_seq_dir',
    required => 1
);

sub execute {
    my ( $self, $opts, $args ) = @_;

    $self->eng_seq_builder->txn_do(
        sub {
            $self->load_component_fixtures( $self->fixtures_dir->file( 'component_fixtures.yml' ) );
            $self->load_mutant_sequences( 'create_cassette_seq', $self->fixtures_dir->file( 'cassette_fixtures.yml' ) );
            $self->load_mutant_sequences( 'create_backbone_seq', $self->fixtures_dir->file( 'backbone_fixtures.yml' ) );
            $self->eng_seq_builder->txn_rollback unless $self->commit;
        }
    );

    return;
}

sub load_component_fixtures {
    my ( $self, $fixture_file ) = @_;

    my $spec_array = YAML::Any::LoadFile( $fixture_file );

    for my $spec ( @{ $spec_array } ) {
        if ( exists $spec->{ source } ) {
            $self->_load_simple_sequence( $spec );
        }
        elsif ( exists $spec->{ components } ) {
            $self->_load_compound_sequence( $spec );
        }
    }

    return;
}

sub _load_compound_sequence {
    my ( $self, $spec ) = @_;

    $self->eng_seq_builder->create_compound_seq(
        name       => $spec->{ name },
        type       => $spec->{ type },
        components => $spec->{ components },
    );

    return;
}

sub _load_simple_sequence {
    my ( $self, $spec ) = @_;

    my $seq_io            = Bio::SeqIO->new( -file => $self->fixtures_dir->file( $spec->{ source } ) );
    my $seq               = $seq_io->next_seq;                                                            # error check
    my @this_seq_features = grep { is_exact_feature( $_ ) } $seq->get_SeqFeatures;

    if ( @this_seq_features ) {
        $self->eng_seq_builder->create_simple_seq(
            name     => $spec->{ name },
            type     => $spec->{ type },
            seq      => $seq->seq,
            features => \@this_seq_features,
        );
    }
    else {
        $self->eng_seq_builder->create_simple_seq(
            name => $spec->{ name },
            type => $spec->{ type },
            seq  => $seq->seq,
        );
    }

    return;
}

sub load_mutant_sequences {
    my ( $self, $function, $fixture_file ) = @_;

    my $spec_array = YAML::Any::LoadFile( $fixture_file );

    for my $spec ( @{ $spec_array } ) {
        my $seq_io = Bio::SeqIO->new(
            -file   => $self->mutant_sequence_fixtures_dir->file( $spec->{ source } ),
            -format => 'genbank'
        );
        my $seq = $seq_io->next_seq;    # error check

        my @optional_args;
        push @optional_args, ( description => $spec->{ description } ) if $spec->{ description };
        push @optional_args, ( append      => $spec->{ append } )      if $spec->{ append };

        $self->eng_seq_builder->$function(
            seq  => $seq,
            name => $spec->{ name },
            type => $spec->{ type },
            @optional_args
        );

    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
