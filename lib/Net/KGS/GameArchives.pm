package Net::KGS::GameArchives;
use Mouse;
use Net::KGS::GameArchives::Result;
use URI;
use Web::Scraper;

has base_url => (
    is => 'ro',
    isa => 'URI',
    default => sub { URI->new('http://www.gokgs.com/gameArchives.jsp') },
);

has param => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);

has cache => (
    is => 'ro',
    predicate => '_has_cache',
);

sub search {
    my $self  = shift;
    my %param = @_ == 1 ? %{$_[0]} : @_;

    my $uri = $self->base_url->clone;
    $uri->query_form( %{ $self->param }, %param );

    my $result = $self->_has_cache && $self->cache->get($uri);
    return $cache if $cache;

    my $result = Net::KGS::GameArchives::Result->new( $self->_scrape($uri) );

    $self->cache->set( $uri => $result ) if $self->_has_cache;

    $result;
}

sub _scrape {
    my ( $self, $uri ) = @_;

    my $result = scraper {
        process '//h2', 'summary', 'TEXT';
        process '//table[1]//tr', 'games[]' => scraper {
            process '//td', 'summary[]' => 'TEXT';
            process '//a[contains(@href,".sgf")]', 'kifu_url' => '@href';
            process '//td[2]//a', 'white[]' => 'TEXT';
            process '//td[3]//a', 'black[]' => 'TEXT';
        };
        process '//a[contains(@href,".zip")]', 'zip_url' => '@href';
        process '//a[contains(@href,".tar.gz")]', 'tgz_url' => '@href';
    }->scrape( $uri );

    my ( $total_hits ) = do {
        my $summary = delete $result->{summary};
        $summary ? $summary =~ /\((\d+)\sgames\)/ : 0;
    };

    return {} if $total_hits == 0;

    my $games = $result->{games};
    shift @$games; # remove <table> heads

    for my $game ( @$games ) {
        my $summary = delete $game->{summary};
        if ( @$summary == 7 ) {
            $game->{is_viewable} = $summary->[0];
            $game->{setup}       = $summary->[3];
            $game->{start_time}  = $summary->[4];
            $game->{type}        = $summary->[5];
            $game->{result}      = $summary->[6];
        }
        else { # <td colspan="2">
            my $users = delete @{$game}{qw/black white/};
            if ( @$users == 1 ) { # Type: Demonstration
                $game->{editor} = $users->[0];
            }
            elsif ( @$users == 3 ) { # Type: Review
                $game->{editor} = $users->[0];
                $game->{white}  = [ $users->[1] ];
                $game->{black}  = [ $users->[2] ];
            }
            elsif ( @$users == 5 ) { # Type: Rengo Review
                $game->{editor} = $users->[0];
                $game->{white}  = [ @{$users}[1,2] ];
                $game->{black}  = [ @{$users}[3,4] ];
            }
            $game->{is_viewable} = $summary->[0];
            $game->{setup}       = $summary->[2];
            $game->{start_time}  = $summary->[3];
            $game->{type}        = $summary->[4];
            $game->{result}      = $summary->[5];
        }
    }

    $result;
}

__PACKAGE__->meta->make_immutable;

1;
