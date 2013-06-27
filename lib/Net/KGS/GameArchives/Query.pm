package Net::KGS::GameArchives::Query;
use Moo;
use Time::Piece;
use URI;

has user => (
    is => 'ro',
    required => 1,
    isa => sub {
        my $user = shift;
        die "Must be 1 to 10 characters long" if !$user or length $user > 10;
        die "Must contain only English letters and digits" if $user =~ /\W/;
        die "Must start with a letter" if $user =~ /^[0-9]/;
    },
);

has year => (
    is => 'ro',
    coerce => sub { int $_[0] },
);

has month => (
    is => 'ro',
    coerce => sub { int $_[0] },
);

has tags => ( is => 'ro' );

has old_accounts => ( is => 'ro' );

sub as_uri {
    my $self = shift;
    my $uri  = URI->new('http://www.gokgs.com/gameArchives.jsp');
    my $now  = gmtime;

    my @query;

    push @query, 'user', $self->user;
    push @query, 'oldAccounts', 'y' if $self->old_accounts;
    push @query, 'tags', 't' if $self->tags;
    push @query, 'year', ( $self->month && $self->year ) || $now->year;
    push @query, 'month', $self->month || $now->mon;

    $uri->query_form( @query );

    $uri;
}

1;
