package Net::KGS::GameArchives::Result;
use Moo;
use Net::KGS::GameArchives::Game;

has games => (
    is => 'ro',
    default => sub { [] },
    coerce => sub {
        [
            map {
                ref $_ eq 'HASH' ? Net::KGS::GameArchives::Game->new($_) : $_
            } @{$_[0]}
        ];
    },
);

has tgz_urls => ( is => 'ro', default => sub { [] } );
has zip_urls => ( is => 'ro', default => sub { [] } );

1;
