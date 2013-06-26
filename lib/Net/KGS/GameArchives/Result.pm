package Net::KGS::GameArchives::Result;
use Moo;
use Net::KGS::GameArchives::Result::Game;

has games => (
    is => 'ro',
    default => sub { [] },
    coerce => sub {
        [ map { Net::KGS::GameArchives::Result::Game->new($_) } @{$_[0]} ];
    },
);

has zip_url => ( is => 'ro' );
has tgz_url => ( is => 'ro' );

1;
