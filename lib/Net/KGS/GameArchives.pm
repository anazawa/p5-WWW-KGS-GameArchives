package Net::KGS::GameArchives;
use Mouse;
use Net::KGS::GameArchives::Result;
use WebService::Simple::KGS::GameArchives;

has _client => (
    is => 'ro',
    isa => 'WebService::Simple::KGS::GameArchives',
    builder => '_build_client',
    lazy => 1,
);

sub _build_client {
    my $self = shift;
    WebService::Simple::KGS::GameArchives->new;
}

sub search {
    my ( $self, $param ) = @_;
    my $response = $self->_client->get( q{}, $param );
    my $result = $response->parse_response;
    Net::KGS::GameArchives::Result->new( $result );
}

__PACKAGE__->meta->make_immutable;

1;
