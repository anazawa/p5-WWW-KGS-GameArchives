package Net::KGS::GameArchives;
use Moo;
use Net::KGS::GameArchives::Query;
use Net::KGS::GameArchives::Result;
use Time::Piece;
use Web::Scraper;

has query => ( is => 'ro', default => sub { {} } );

has cache => ( is => 'ro', predicate => '_has_cache' );

sub search {
    my $self    = shift;
    my %default = %{ $self->query };
    my $query   = Net::KGS::GameArchives::Query->new( %default, @_ );
    my $year    = $query->year;
    my $uri     = $query->as_uri;
    my $result  = $self->scrape( $uri );

    return Net::KGS::GameArchives::Result->new($result) if $query->month;

    my @urls = @{ $result->{urls} || [] };
       @urls = grep { {$_->query_form}->{year} == $year } @urls if $year;

    my @results = map { $self->scrape($_) } @urls;
    push @results, $result if !$year or {$uri->query_form}->{year} == $year;

    Net::KGS::GameArchives::Result->new( @results );
}

sub scrape {
    my ( $self, $url ) = @_;
    my $cache = $self->_has_cache && $self->cache->get($url);
    return $cache if $cache;
    my $result = $self->_scrape( $url );
    $self->cache->set( $url => $result ) if $self->_has_cache;
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
            process '//td[8]', 'tag' => 'TEXT';
        };
        process '//a[contains(@href,".zip")]', 'zip_url' => '@href';
        process '//a[contains(@href,".tar.gz")]', 'tgz_url' => '@href';
        process '//table[2]//a', 'urls[]' => '@href';
    }->scrape( $stuff );

    my ( $total_hits ) = do {
        my $summary = delete $result->{summary};
        $summary ? $summary =~ /\((\d+)\sgames\)/ : 0;
    };

    if ( $total_hits == 0 ) {
        $result->{games} = [];
        $result->{urls}  = [];
    }

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
        $game->{tag}        = delete $game->{result} if exists $game->{result};
        $game->{result}     = delete $game->{type};
        $game->{type}       = delete $game->{start_time};
        $game->{start_time} = delete $game->{setup};
        $game->{setup}      = $maybe_setup;
    }

    @$games = reverse @$games; # sort by Start Time in descending order

    $result;
}

1;
