package Net::KGS::GameArchives::Result;
use Moo;
use Net::KGS::GameArchives::Result::Game;

has games => (
    is => 'ro',
    default => sub { [] },
    coerce =>
    sub { [ map { Net::KGS::GameArchives::Result::Game->new($_) } @{$_[0]} ] },
);

has tgz_urls => ( is => 'ro', default => sub { [] } );
has zip_urls => ( is => 'ro', default => sub { [] } );

sub BUILDARGS {
    my ( $class, @results ) = @_;
    my ( @games, @tgz_urls, @zip_urls );
    for my $result ( @results ) {
        push @games, @{ $result->{games} };
        push @tgz_urls, $result->{tgz_url} if exists $result->{tgz_url};
        push @zip_urls, $result->{zip_url} if exists $result->{zip_url};
    }
    $class->SUPER::BUILDARGS(
        games    => \@games,
        tgz_urls => \@tgz_urls,
        zip_urls => \@zip_urls
    );
}

1;
