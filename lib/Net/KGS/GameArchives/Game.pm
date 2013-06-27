package Net::KGS::GameArchives::Game;
use Moo;
use Time::Piece;

our $VERSION = '0.01';

has kifu_url => (
    is => 'ro',
    predicate => 'is_viewable',
);

has editor => ( is => 'ro', default => sub { q{} } );

has white => ( is => 'ro', default => sub { [] } );
has black => ( is => 'ro', default => sub { [] } );

has setup => (
    is => 'ro',
    required => 1,
    coerce => sub {
        my $setup = shift;
        $setup =~ s/\s+$//; # "19×19 " -> "19×19"
        $setup =~ s/\xd7/x/; # "19×19" -> "19x19"
        $setup;
    },
);

has start_time => (
    is => 'ro',
    required => 1,
    coerce => sub { gmtime->strptime($_[0], '%D %I:%M %p') },
);

has type => ( is => 'ro', required => 1 );

has result => ( is => 'ro', required => 1 );

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

sub handicap {
    my $self = shift;
    my ( $handicap ) = $self->setup =~ /\sH(\d+)$/;
    $handicap || 0;
}

sub size {
    my $self = shift;
    my ( $size ) = $_[0]->setup =~ /^(\d+)x/; # Go board is square
    $size;
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

1;
