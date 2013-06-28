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

has tagged_by => ( is => 'ro', predicate => 'has_tagged_by' );

sub BUILDARGS {
    my ( $class, @results ) = @_;
    my ( @games, @tgz_urls, @zip_urls, $tagged_by );
    for my $result ( @results ) {
        push @games, @{ $result->{games} };
        push @tgz_urls, $result->{tgz_url} if exists $result->{tgz_url};
        push @zip_urls, $result->{zip_url} if exists $result->{zip_url};
        $tagged_by = $result->{tagged_by} if exists $result->{tagged_by};
    }
    $class->SUPER::BUILDARGS(
        games    => \@games,
        tgz_urls => \@tgz_urls,
        zip_urls => \@zip_urls,
        tagged_by => $tagged_by,
    );
}

1;
