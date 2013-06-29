package Net::KGS::GameArchives::Result;
use Moo;
use Net::KGS::GameArchives::Result::Game;

has tagged_by => ( is => 'ro', predicate => 1 );

has games => (
    is => 'ro',
    coerce => sub {
        my $games = shift;
        [ map { Net::KGS::GameArchives::Result::Game->new($_) } @$games ];
    },
);

has tgz_url => ( is => 'ro', predicate => 1 );
has zip_url => ( is => 'ro', predicate => 1 );

has urls => ( is => 'ro', predicate => 1 );

1;
