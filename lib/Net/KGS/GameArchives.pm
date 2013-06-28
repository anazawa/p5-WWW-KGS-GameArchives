package Net::KGS::GameArchives;
use Carp qw/croak/;
use Moo;
use Net::KGS::GameArchives::Result;
use Time::Piece;
use URI;
use Web::Scraper;

has base_uri => (
    is => 'ro',
    default => sub { URI->new('http://www.gokgs.com/gameArchives.jsp') },
);

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

has tags => ( is => 'ro' );

has old_accounts => ( is => 'ro' );

has cache => ( is => 'ro', predicate => '_has_cache' );

has cache_expires_in => ( is => 'rw', default => sub { '1d' } );

sub search {
    my $self    = shift;
    my %query   = @_ == 1 ? %{$_[0]} : @_;
    my $year    = int( $query{year}  || 0 );
    my $month   = int( $query{month} || 0 );
    my $expires = $self->cache_expires_in;
    my $now     = gmtime;

    croak "Invalid year: $year" if $year and $year > $now->year;
    croak "Invalid month: $month" if $month and $month > 12;

    my $index_uri = $self->_build_uri(
        year  => $now->year,
        month => $now->mon,
    );

    if ( $month ) {
        if ( (!$year or $year == $now->year) and $month == $now->mon ) {
            my $result = $self->scrape( $index_uri, $expires );
            return Net::KGS::GameArchives::Result->new( $result );
        }
        my $uri = $self->_build_uri(
            year  => $year || $now->year,
            month => $month,
        );
        my $result = $self->scrape( $uri );
        return Net::KGS::GameArchives::Result->new( $result );
    }

    my $result = $self->scrape( $index_uri, $expires );

    my @urls = @{ $result->{urls} || [] };
       @urls = grep { {$_->query_form}->{year} == $year } @urls if $year;

    my @results = map { $self->scrape($_) } @urls;
    push @results, $result if !$year or $year == $now->year;

    Net::KGS::GameArchives::Result->new( @results );
}

sub _build_uri {
    my ( $self, %query ) = @_;
    my $uri = $self->base_uri->clone;

    my @query;

    push @query, 'user', $self->user;
    push @query, 'oldAccounts', 'y' if $self->old_accounts;
    push @query, 'tags', 't' if $self->tags;
    push @query, 'year', $query{year} if exists $query{year};
    push @query, 'month', $query{month} if exists $query{month};

    $uri->query_form( @query );

    $uri;
}

sub scrape {
    my ( $self, $uri, $expires ) = @_;
    my $cache = $self->_has_cache && $self->cache->get( $uri );

    return $cache if $cache;

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
    }->scrape( $uri );

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

    croak "Failed to scrape $uri" if @$games != $total_hits;

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

    $self->cache->set($uri, $result, $expires) if $self->_has_cache;

    $result;
}

1;
