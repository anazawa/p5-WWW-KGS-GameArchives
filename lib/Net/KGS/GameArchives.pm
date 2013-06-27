package Net::KGS::GameArchives;
use Moo;
use Net::KGS::GameArchives::Result;
use Time::Piece;
use URI;
use Web::Scraper;

has base_url => (
    is => 'ro',
    default => sub { URI->new('http://www.gokgs.com/gameArchives.jsp') },
);

has user => (
    is => 'ro',
    required => 1,
);

has urls => (
    is => 'lazy',
);

has cache => (
    is => 'ro',
    predicate => '_has_cache',
);

sub _build_urls {
    my $self = shift;
    my $url  = $self->base_url->clone;
    my $now  = gmtime;

    $url->query_form(
        user  => $self->user,
        year  => $now->year,
        month => $now->mon,
    );

    my $result = $self->scrape( $url );
    my $urls = $result->{urls} || [];

    push @$urls, $url;

    $urls;
}

sub search {
    my $self  = shift;
    my %param = @_ == 1 ? %{$_[0]} : @_;

    $param{user} = $self->user;

    my $year = $param{year};
    my $month = $param{month};
    my $day = $param{day};

    if ( $year and $month and $day ) {
        my $url = $self->base_url->clone;
        $url->query_form( %param );
        my $result = Net::KGS::GameArchives::Result->new( $self->scrape($url) );
        my $games = $result->games;
        @$games = grep { $_->start_time->mday == $day } @$games;
        return $result;
    }
    elsif ( $year and $month ) {
        my $url = $self->base_url->clone;
        $url->query_form( %param );
        my $result = $self->scrape( $url );
        return Net::KGS::GameArchives::Result->new( $result );
    }
    elsif ( $year ) {
        my @urls = grep { {$_->query_form}->{year} == $year } @{$self->urls};
        my @results = map { $self->scrape($_) } @urls;
        my @games = map { @{$_->{games}} } @results;
        return Net::KGS::GameArchives::Result->new( games => \@games );
    }
    else {
        my @results = map { $self->scrape($_) } @{$self->urls};
        my @games = map { @{$_->{games}} } @results;
        return Net::KGS::GameArchives::Result->new( games => \@games );
    }

    #my @games = map { @{$_->{games}} } @results;
    #my @tgz_urls = map { $_->{tgz_url} } @results;
    #my @zip_urls = map { $_->{zip_url} } @resylts;

    #for my $result ( @results ) {
    #    push @games, @{$result->{games}};
    #    push @tgz_urls, $result->{tgz_url};
    #    push @zip_urls, $result->{zip_url};
    #}

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
        $game->{result}     = delete $game->{type};
        $game->{type}       = delete $game->{start_time};
        $game->{start_time} = delete $game->{setup};
        $game->{setup}      = $maybe_setup;
    }

    @$games = reverse @$games; # sort by Start Time in descending order

    $result;
}

1;
