#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Const::Fast;
use Path::Class;
use HTGT::Constants;
use Try::Tiny;

const my @ENG_SEQ_BUILDER      => qw( perl -I lib ./bin/eng-seq-builder);
const my %ENG_SEQ_BUILDER_OPTS => ( debug => undef , commit => undef );

my $MUTANT_SEQ_DIR = dir( '/software/team87/brave_new_world/data/mutant_sequences_draft' );

sub cassette_stage {
    my $name = shift;

    if ( $name =~ m/Ifitm2/ ) {
        'intermediate';
    }
    else {
        'final';
    }    
}

sub to_opt_list {
    my $opts = shift;

    my @opts;
    while ( my ( $name, $value ) = each %{$opts} ) {
        if ( $name eq 'components' ) {
            push @opts, @{ $value };
        }
        elsif ( defined $value ) {
            push @opts, "--$name=$value";
        }
        else {
            push @opts, "--$name";
        }
    }

    return @opts;
}

my @TODO = (
    { action => 'load-component', type => 'B1', name => 'B1', sequence_file => 'fixtures/B1.gbk' },
    { action => 'load-component', type => 'B2', name => 'B2', sequence_file => 'fixtures/B2.gbk' },
    { action => 'load-component', type => 'B3', name => 'B3', sequence_file => 'fixtures/B3.gbk' },
    { action => 'load-component', type => 'B4', name => 'B4', sequence_file => 'fixtures/B4.gbk' },
    { action => 'load-component', type => 'R1', name => 'R1', sequence_file => 'fixtures/R1.gbk' },
    { action => 'load-component', type => 'R2', name => 'R2', sequence_file => 'fixtures/R2.gbk' },
    { action => 'load-component', type => 'R3', name => 'R3', sequence_file => 'fixtures/R3.gbk' },
    { action => 'load-component', type => 'R4', name => 'R4', sequence_file => 'fixtures/R4.gbk' },
    { action => 'load-component', type => 'L1', name => 'L1', sequence_file => 'fixtures/L1.gbk' },
    { action => 'load-component', type => 'L2', name => 'L2', sequence_file => 'fixtures/L2.gbk' },
    { action => 'load-component', type => 'L3', name => 'L3', sequence_file => 'fixtures/L3.gbk' },
    { action => 'load-component', type => 'L4', name => 'L4', sequence_file => 'fixtures/L4.gbk' },
    
    { action => 'load-component', type => 'AB1', name => 'Artificial_intron_B1_append', sequence_file => 'fixtures/artificial_intron_B1_append.gbk' },
    { action => 'load-component', type => 'AB2', name => 'Artificial_intron_B2_append', sequence_file => 'fixtures/artificial_intron_B2_append.gbk' },
    
    { action => 'load-component', type => 'OAB1', name => 'Standard_oligo_B1_append', sequence_file => 'fixtures/standard_oligo_B1_append.fasta' },
    { action => 'load-component', type => 'OAB2', name => 'Standard_oligo_B2_append', sequence_file => 'fixtures/standard_oligo_B2_append.fasta' },
    { action => 'load-component', type => 'OAB3', name => 'Standard_oligo_B3_append', sequence_file => 'fixtures/standard_oligo_B3_append.fasta' },
    { action => 'load-component', type => 'OAB4', name => 'Standard_oligo_B4_append', sequence_file => 'fixtures/standard_oligo_B4_append.fasta' },
    
    { action => 'load-component', type => 'CAB1', name => 'Standard_cassette_B1_append', sequence_file => 'fixtures/standard_cassette_B1_append.fasta' },
    { action => 'load-component', type => 'CAB2', name => 'Standard_cassette_B2_append', sequence_file => 'fixtures/standard_cassette_B2_append.fasta' },
    { action => 'load-component', type => 'BAB3', name => 'Standard_backbone_B3_append', sequence_file => 'fixtures/standard_backbone_B3_append.fasta' },
    { action => 'load-component', type => 'BAB4', name => 'Standard_backbone_B4_append', sequence_file => 'fixtures/standard_backbone_B4_append.fasta' },
    
    { action => 'load-component', type => 'LoxP', name => 'LoxP', sequence_file => 'fixtures/LoxP.gbk', desc => 'LoxP plus flanking append sequence' },
    
    { action => 'create-compound-seq', type => 'AB1', name => 'Standard_B1_append', components => [ qw( Standard_oligo_B1_append Standard_cassette_B1_append )] },
    { action => 'create-compound-seq', type => 'AB2', name => 'Standard_B2_append', components => [ qw( Standard_cassette_B2_append Standard_oligo_B2_append )] },
    { action => 'create-compound-seq', type => 'AB3', name => 'Standard_B3_append', components => [ qw( Standard_backbone_B3_append Standard_oligo_B3_append )] },
    { action => 'create-compound-seq', type => 'AB4', name => 'Standard_B4_append', components => [ qw( Standard_oligo_B4_append Standard_backbone_B4_append )] },
    
    { action => 'load-backbone', name => 'R3R4_pBR_DTA+_Bsd_amp', stage => 'intermediate',  genbank_file => $MUTANT_SEQ_DIR->file('pR3R4_DTA(+)_EM7_Bsd.gbk'),
        desc => "'medium copy number vector backbone from 4th recombineering after gap repair plasmid recombineering which remains after 2-way Gateway reaction. Reactive R3 and R4 sites remain on plasmid.'" },
    { action => 'load-backbone', name => 'R3R4_pBR_amp', stage => 'intermediate',  genbank_file => $MUTANT_SEQ_DIR->file('pR3R4AsiSI_postcre_backbone.gbk'),
        desc => "'medium copy number vector backbone from gap repair plasmid from recombineering which remains after 2-way Gateway reaction. Reactive R3 and R4 sites remain on plasmid.'" },
    
    { action => 'load-backbone', name => 'L3L4_pZero_DTA_kan', stage => 'final',  genbank_file => $MUTANT_SEQ_DIR->file('pL3L4_(+)_DTA_Kan_MapVerified.gbk'),
        desc => "'high copy number; standard backbone for promoterless vectors'" },
    { action => 'load-backbone', name => 'L3L4_pZero_kan', stage => 'final',  genbank_file => $MUTANT_SEQ_DIR->file('L3L4_pZero_map.gbk'),
        desc => "'high copy number, no DTA'" },
    { action => 'load-backbone', name => 'L3L4_pD223_DTA_T_spec', stage => 'final',  genbank_file => $MUTANT_SEQ_DIR->file('pL3L4_DONR223__Spec_DTA(-)Terminator_MapVerified.gbk'),
        desc => "'high copy number, with DTA'" },
    { action => 'load-backbone', name => 'L3L4_pD223_DTA_spec', stage => 'final',  genbank_file => $MUTANT_SEQ_DIR->file('pL3L4_DONR223__Spec_DTA(-)_No_Terminator_MapVerified.gbk'),
        desc => "'high copy number with DTA; version w/o E. Coli transcription terminator on L4 side; used in a ver limited number of experiments'" },
    
    { action => 'load-backbone', name => 'L3L4_pZero_DTA_spec', stage => 'final',  genbank_file => $MUTANT_SEQ_DIR->file('pL3L4_pZero_DTA_Spec_Map_Validated.gbk') },
    { action => 'load-backbone', name => 'L3L4_pZero_DTA_kan_for_norcomm', stage => 'final',  genbank_file => $MUTANT_SEQ_DIR->file('pL3L4_(+)_DTA_Kan_for_norcomm.gbk') },
    
    #inverted backbone 
    { action => 'load-component', name => 'L4L3_pD223_DTA_spec_without_gateway', type => 'backbone',  sequence_file => 'fixtures/L4L3_no_gateway_revcomp.gbk',
        desc => 'INVERTED R3 and R4 Gateway Sites with Linearization close to DTA pA, potentially compromising negative selection' },
    {
        action => 'create-compound-seq', name => 'L4L3_pD223_DTA_spec', type => 'final-backbone',
        components => [ qw( Standard_B4_append B4 L4L3_pD223_DTA_spec_without_gateway B3 Standard_B3_append ) ],
        'primary-tag' => 'misc_feature', tag => 'note=Synthetic Backbone',
    },    
    
    { action => 'load-cassette', name => 'pR6K_R1R2_ZP', stage => 'intermediate',  genbank_file => $MUTANT_SEQ_DIR->file('pR6K_R1R2_ZP_synvec.gbk') },
    
    { action => 'load-cassette', name => 'L1L2_GTK_LacZ_BetactP_neo',      stage => 'final', genbank_file => $MUTANT_SEQ_DIR->file('pL1L2_GTK_LacZ_BetactP_neo.gbk') },
    { action => 'load-cassette', name => 'L1L2_GT0_LF2A_LacZ_BetactP_neo', stage => 'final', genbank_file => $MUTANT_SEQ_DIR->file('pL1L2_GT0_LF2A_LacZ_BetactP_neo.gbk') },
    { action => 'load-cassette', name => 'L1L2_GT1_LF2A_LacZ_BetactP_neo', stage => 'final', genbank_file => $MUTANT_SEQ_DIR->file('pL1L2_GT1_LF2A_LacZ_BetactP_neo.gbk') },
    { action => 'load-cassette', name => 'L1L2_GT2_LF2A_LacZ_BetactP_neo', stage => 'final', genbank_file => $MUTANT_SEQ_DIR->file('pL1L2_GT2_LF2A_LacZ_BetactP_neo.gbk') },
    
    {
        action => 'create-compound-seq', name => 'Ifitm2_intron_L1L2_GTK_LacZ_BetactP_neo', type => 'final-cassette',
        components => [ qw( Artificial_intron_B1_append B1 L1L2_GTK_LacZ_BetactP_neo_without_gateway B2 Artificial_intron_B2_append ) ],
        'primary-tag' => 'misc_feature', tag => 'note=Synthetic Cassette',
    },
    {
        action => 'create-compound-seq', name => 'Ifitm2_intron_L1L2_GT0_LF2A_LacZ_BetactP_neo', type => 'final-cassette',
        components => [ qw( Artificial_intron_B1_append B1 L1L2_GT0_LF2A_LacZ_BetactP_neo_without_gateway B2 Artificial_intron_B2_append ) ],
        'primary-tag' => 'misc_feature', tag => 'note=Synthetic Cassette',
    },
    {
        action => 'create-compound-seq', name => 'Ifitm2_intron_L1L2_GT1_LF2A_LacZ_BetactP_neo', type => 'final-cassette',
        components => [ qw( Artificial_intron_B1_append B1 L1L2_GT1_LF2A_LacZ_BetactP_neo_without_gateway B2 Artificial_intron_B2_append ) ],
        'primary-tag' => 'misc_feature', tag => 'note=Synthetic Cassette',        
    },
    {
        action => 'create-compound-seq', name => 'Ifitm2_intron_L1L2_GT2_LF2A_LacZ_BetactP_neo', type => 'final-cassette',
        components => [ qw( Artificial_intron_B1_append B1 L1L2_GT2_LF2A_LacZ_BetactP_neo_without_gateway B2 Artificial_intron_B2_append ) ],
        'primary-tag' => 'misc_feature', tag => 'note=Synthetic Cassette',        
    },
);



while ( my ( $name, $spec ) = each %HTGT::Constants::CASSETTES ) {
    my $filename = $spec->{filename};
    $filename =~ s/\.\w+$/.gbk/;
    $filename =~ s/\s+/_/g;
    
    my %todo = ( action => 'load-cassette', name => $name, genbank_file  => $MUTANT_SEQ_DIR->file( $filename ), stage => cassette_stage( $name ) );
    $todo{desc} = "'" . $spec->{comments} . "'" if defined $spec->{comments};
    push @TODO, \%todo; 
}


for my $todo ( @TODO ) {
    my @cmd = @ENG_SEQ_BUILDER;
    push @cmd, delete $todo->{action};
    my %opts = ( %ENG_SEQ_BUILDER_OPTS, %$todo );
    push @cmd, to_opt_list( \%opts );
    
    system( @cmd ) == 0
        or print "Error executing @cmd";
}

