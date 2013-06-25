package Net::KGS::GameArchives::Result;
use Mouse;
use Mouse::Util::TypeConstraints;
use Net::KGS::GameArchives::Result::Game;

subtype 'Net::KGS::Type::Games'
    => as 'ArrayRef[Net::KGS::GameArchives::Result::Game]';

coerce 'Net::KGS::Type::Games'
    => from 'ArrayRef[HashRef]'
    => via { [ map { Net::KGS::GameArchives::Result::Game->new($_) } @$_ ] };

no Mouse::Util::TypeConstraints;

has games => (
    is => 'ro',
    isa => 'Net::KGS::Type::Games',
    coerce => 1,
);

__PACKAGE__->meta->make_immutable;

1;
