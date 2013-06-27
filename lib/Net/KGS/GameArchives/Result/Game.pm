package Net::KGS::GameArchives::Result::Game;
use Moo;
use Time::Piece;

our $VERSION = '0.01';

has kifu_url => (
    is => 'ro',
    predicate => 'is_viewable',
);

has editor => ( is => 'ro' );

has white  => ( is => 'ro' );
has black  => ( is => 'ro' );

has setup => ( is => 'ro' );

has start_time => (
    is => 'ro',
    coerce => sub { gmtime->strptime($_[0], '%D %I:%M %p') },
);

has type => ( is => 'ro' );

has result => ( is => 'ro' );

1;
