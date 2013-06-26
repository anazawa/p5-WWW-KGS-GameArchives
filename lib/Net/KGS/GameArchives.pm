package Net::KGS::GameArchives;
use Moo;
use Net::KGS::GameArchives::Result;
use URI;
use Web::Scraper;

has base_url => (
    is => 'ro',
    default => sub { URI->new('http://www.gokgs.com/gameArchives.jsp') },
);

has param => (
    is => 'rw',
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

    my $cache = $self->_has_cache && $self->cache->get($uri);
    return $cache if $cache;

    my $result = Net::KGS::GameArchives::Result->new( $self->_scrape($uri) );

    $self->cache->set( $uri => $result ) if $self->_has_cache;

    $result;
}

sub _scrape {
    my ( $self, $stuff ) = @_;

    my $result = scraper {
        process '//h2', 'summary', 'TEXT';
        process '//table[1]//tr', 'games[]' => scraper {
            process '//a[contains(@href,".sgf")]', 'kifu_url' => '@href';
            process '//td[2]//a', 'white[]' => 'TEXT';
            process '//td[3]//a', 'black[]' => 'TEXT';
            process '//td[3]', 'maybe_setup' => 'TEXT';
            process '//td[4]', 'setup' => 'TEXT';
            process '//td[5]', 'start_time' => 'TEXT';
            process '//td[6]', 'type' => 'TEXT';
            process '//td[7]', 'result' => 'TEXT';
        };
        process '//a[contains(@href,".zip")]', 'zip_url' => '@href';
        process '//a[contains(@href,".tar.gz")]', 'tgz_url' => '@href';
    }->scrape( $stuff );

    my ( $total_hits ) = do {
        my $summary = delete $result->{summary};
        $summary ? $summary =~ /\((\d+)\sgames\)/ : 0;
    };

    return {} if $total_hits == 0;

    my $games = $result->{games};
    shift @$games; # remove <table> heads

    for my $game ( @$games ) {
        my $maybe_setup = delete $game->{maybe_setup};
        next if exists $game->{black};
        my $users = delete $game->{white}; # <td colspan="2">
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
        $game->{result}     = delete $game->{type};
        $game->{type}       = delete $game->{start_time};
        $game->{start_time} = delete $game->{setup};
        $game->{setup}      = $maybe_setup;
    }

    $result;
}

1;
