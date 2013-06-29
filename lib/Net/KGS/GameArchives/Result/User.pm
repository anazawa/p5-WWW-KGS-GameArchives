package Net::KGS::GameArchives::Result::User;
use Moo;

has name => ( is => 'ro', required => 1 );

has rank => ( is => 'ro', predicate => 1 );

has url => ( is => 'ro', required => 1 );

has is_expired => ( is => 'lazy' );

sub _build_is_expired {
    my $self = shift;
    my %query = %{ $self->url->query_form };
    $query{oldAccounts} ? 1 : 0;
}

# See http://www.gokgs.com/help/rank.html
sub BUILDARGS {
    my ( $self, $user ) = @_;
    my ( $name, $rank ) = $user->{name} =~ /^(\w+)(?: \[(-|\?|\d+[kdp])\??\])?$/;
    my %args = ( name => $name, url => $user->{url} );
    $args{rank} = $rank if $rank;
    \%args;
}

sub as_string {
    my $self = shift;
    my $user = $self->name;
    $user .= ' [' . $self->rank . ']' if $self->has_rank;
    $user;
}

1;
