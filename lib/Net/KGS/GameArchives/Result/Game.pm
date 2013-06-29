package Net::KGS::GameArchives::Result::Game;
use Moo;
use Time::Piece;

our $VERSION = '0.01';

has kifu_url => (
    is => 'ro',
    predicate => 'is_viewable',
);

has editor => ( is => 'ro', predicate => 1 );

has white => ( is => 'ro', predicate => 1 );
has black => ( is => 'ro', predicate => 1 );

has size => ( is => 'ro', required => 1 );

has handicap => ( is => 'ro', predicate => 1 );

has start_time => (
    is => 'ro',
    required => 1,
    coerce => sub { gmtime->strptime($_[0], '%D %I:%M %p') },
);

has type => ( is => 'ro', required => 1 );

has result => ( is => 'ro', required => 1 );

has tag => ( is => 'ro', predicate => 1 );

sub BUILDARGS {
    my ( $self, $game ) = @_;
    my $setup = delete $game->{setup};
    my ( $size, $handicap ) = $setup =~ /^(\d+)\x{d7}\d+ (?:H(\d+))?$/;
    $game->{handicap} = $handicap if $handicap;
    $game->{size} = $size;
    $game;
}

sub is_finished {
    lc $_[0]->result ne 'unfinished';
}

sub is_ranked {
    lc $_[0]->type eq 'ranked';
}

sub is_free {
    lc $_[0]->type eq 'free';
}

sub is_rengo {
    lc $_[0]->type eq 'rengo';
}

sub is_review {
    $_[0]->type =~ /review$/i; # Review or Rengo Review
}

sub is_demo {
    lc $_[0]->type eq 'demonstration';
}

sub is_teaching {
    lc $_[0]->type eq 'teaching';
}

sub is_tournament {
    lc $_[0]->type eq 'tournament';
}

sub is_simul {
    lc $_[0]->type eq 'simul';
}

sub editor_name {
    my $self = shift;
    my ( $name ) = $self->editor =~ /^(\S+)/;
    $name;
}

sub editor_rank {
    my $self = shift;
    my ( $rank ) = $self->editor =~ /\[(\S+)\]$/;
    $rank;
}

sub white_name {
    my $self = shift;
    [ map { /^(\S+)/ } @{ $self->white } ];
}

sub white_rank {
    my $self = shift;
    [ map { /\[(\S+)\]$/ } @{ $self->white } ];
}

sub black_name {
    my $self = shift;
    [ map { /^(\S+)/ } @{ $self->black } ];
}

sub black_rank {
    my $self = shift;
    [ map { /\[(\S+)\]$/ } @{ $self->black } ];
}

sub as_hashref {
    my $self = shift;

    my %game = (
        result => $self->result,
        size   => $self->size,
        type   => $self->type,
    );

    $game{kifu_url} = $self->kifu_url if $self->is_viewable;
    $game{handicap} = $self->handicap if $self->has_handicap;

    \%game;
}

1;
