package Net::KGS::GameArchives;
use 5.008_009;
use strict;
use warnings;
use Carp qw/croak/;
use URI;
use Web::Scraper;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    bless { %args }, $class;
}

sub base_uri {
    $_[0]->{base_uri} ||= URI->new('http://www.gokgs.com/gameArchives.jsp');
}

sub user_agent {
    $_[0]->{user_agent};
}

sub _has_user_agent {
    exists $_[0]->{user_agent};
}

sub _scraper {
    my $self = shift;
    $self->{scraper} ||= $self->_build_scraper;
}

sub _build_scraper {
    my $self = shift;

    my $scraper = scraper {
        process '//h2[1]', 'summary' => 'TEXT';
        process '//table[tr/th/text()="Viewable?"]//following-sibling::tr', 'games[]' => scraper {
            process '//a[contains(@href,".sgf")]', 'kifu_url' => '@href';
            process '//td[2]//a', 'white[]' => { name => 'TEXT', link => '@href' };
            process '//td[3]//a', 'black[]' => { name => 'TEXT', link => '@href' };
            process '//td[3]', 'maybe_setup' => 'TEXT';
            process '//td[4]', 'setup' => 'TEXT';
            process '//td[5]', 'start_time' => 'TEXT';
            process '//td[6]', 'type' => 'TEXT';
            process '//td[7]', 'result' => 'TEXT';
            process '//td[8]', 'tag' => 'TEXT';
        };
        process '//a[contains(@href,".zip")]', 'zip_url' => '@href';
        process '//a[contains(@href,".tar.gz")]', 'tgz_url' => '@href';
        process '//table[descendant::tr/th/text()="Year"]//following-sibling::tr', 'calendar[]' => scraper {
            process '//td[1]', 'year' => 'TEXT';
            process qq{//following-sibling::td[text()!="\x{a0}"]}, 'month[]' => scraper {
                process '.', 'name' => 'TEXT';
                process 'a', 'link' => '@href';
            };
        };
    };

    $scraper->user_agent( $self->user_agent ) if $self->_has_user_agent;

    $scraper;
}

sub scrape {
    my $self   = shift;
    my $result = $self->_scraper->scrape( @_ );
    my $games  = $result->{games};

    return $result unless $games;

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

sub query {
    my ( $self, @query ) = @_;
    my $uri = $self->base_uri->clone;
    $uri->query_form( @query );
    $self->scrape( $uri );
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
