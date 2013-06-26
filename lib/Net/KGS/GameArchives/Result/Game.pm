package Net::KGS::GameArchives::Result::Game;
use Mouse;
use Mouse::Util::TypeConstraints;
use Time::Piece;

subtype 'Net::KGS::Type::StartTime'
    => as 'Time::Piece';

coerce 'Net::KGS::Type::StartTime'
    => from 'Str'
    => via { Time::Piece->strptime($_, '%D %I:%M %p') };

subtype 'Net::KGS::Type::IsViewable'
    => as 'Bool';

coerce 'Net::KGS::Type::IsViewable'
    => from 'Str'
    => via { lc $_ eq 'yes' ? 1 : 0 };

no Mouse::Util::TypeConstraints;

our $VERSION = '0.01';

has 'is_viewable' => (
    is => 'ro',
    isa => 'Net::KGS::Type::IsViewable',
    coerce => 1,
);

has 'kifu_url' => (
    is => 'ro',
    isa => 'URI',
);


has editor => (
    is => 'ro',
    isa => 'Str',
);

has white => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    coerce => 1,
);

has black => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    coerce => 1,
);

has 'setup' => (
    is => 'ro',
    isa => 'Str',
);

has start_time => (
    is => 'ro',
    isa => 'Net::KGS::Type::StartTime',
    coerce => 1,
);

has type => (
    is => 'ro',
    isa => 'Str',
);

has result => (
    is => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;

1;
