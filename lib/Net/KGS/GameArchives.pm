package Net::KGS::GameArchives;
use Carp;
use Moo;
use Net::KGS::GameArchives::Result;
use Time::Piece;
use URI;
use Web::Scraper;

our $BaseURI = URI->new('http://www.gokgs.com/gameArchives.jsp');

sub base_uri {
    $BaseURI;
}

has user => (
    is => 'rw',
    required => 1,
    isa => sub {
        my $user = shift;
        die 'Must be 1 to 10 characters long' if !$user or length $user > 10;
        die 'Must contain only English letters and digits' if $user =~ /\W/;
        die 'Must start with a letter' if $user =~ /^[0-9]/;
    },
);

has year => (
    is => 'rw',
    isa => sub { die "Invalid" if $_[0] > gmtime->year },
    coerce => sub { int $_[0] },
);

has month => (
    is => 'rw',
    isa => sub { die "Invalid" if !$_[0] or $_[0] > 12 },
    coerce => sub { int $_[0] },
);

has tags => ( is => 'rw' );

has old_accounts => ( is => 'rw' );

has _scraper => ( is => 'ro', builder => '_build_scraper', lazy => 1 );
has user_agent => ( is => 'ro', predicate => '_has_user_agent' );

sub _build_scraper {
    my $self = shift;

    my $scraper = scraper {
        process '//h2[1]', 'summary' => 'TEXT';
        process '//table[1]//tr', 'games[]' => scraper {
            process '//a[contains(@href,".sgf")]', 'kifu_url' => '@href';
            process '//td[2]//a', 'white[]' => { name => 'TEXT', url => '@href' };
            process '//td[3]//a', 'black[]' => { name => 'TEXT', url => '@href' };
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
    };

    $scraper->user_agent( $self->user_agent ) if $self->_has_user_agent;

    $scraper;
}

sub as_uri {
    my $self = shift;
    my $now  = gmtime;
    my $uri  = $self->base_uri->clone;

    my @query;

    push @query, 'user', $self->user;
    push @query, 'oldAccounts', 'y' if $self->old_accounts;
    push @query, 'tags', 't' if $self->tags;
    push @query, $self->year  || $now->year;
    push @query, $self->month || $now->mon;

    $uri->query_form( @query );

    $uri;
}

sub scrape {
    my $self   = shift;
    my $stuff  = shift || $self->as_uri;
    my $result = $self->_scraper->scrape( $stuff, @_ );

    my $total_hits = 0;
    if ( my $summary = delete $result->{summary} ) {
        ( $total_hits ) = $summary =~ /\((\d+) games?\)$/;
        $summary =~ /tagged by (\w+),/ and $result->{tagged_by} = $1;
    }

    if ( $total_hits == 0 ) {
        $result->{games} = [];
        $result->{urls}  = [];
    }

    my $games = $result->{games};
    shift @$games; # remove <table> heads

    croak "Failed to parse $stuff" if @$games != $total_hits;

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

sub parse {
    my $self = shift;
    Net::KGS::GameArchives::Result->new( $self->scrape );
}

1;

__END__

=head1 NAME

Net::KGS::GameArchives - Interface to KGS Go Server Game Archives

=head1 SYNOPSIS

  use Net::KGS::GameArchives;
  my $archives = Net::KGS::GameArchives->new( user => 'YourAccount' );
  my $result = $archives->parse; # => Net::KGS::GameAcrhives::Result object

=head1 DISCLAIMER

According to KGS's C<robots.txt>, bots are not allowed to crawl 
the Game Archives:

  User-agent: *
  Disallow: /gameArchives.jsp

Although this module can be used to implement crawlers,
the author doesn't intend to violate their policy.
Use at your own risk.

=head1 SEE ALSO

L<http://www.gokgs.com/robots.txt>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
