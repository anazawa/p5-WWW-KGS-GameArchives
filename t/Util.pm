package t::Util;
use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = qw( slurp );

sub slurp {
    my $file = shift;
    open my $fh, '<:encoding(UTF-8)', $file or die "Can't open $file: $!";
    do { local $/; <$fh> };
}

1;
