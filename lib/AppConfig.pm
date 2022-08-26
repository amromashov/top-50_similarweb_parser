package AppConfig;

use strict;
use warnings;

use Moo;
use File::Slurp qw(read_file);
use JSON;
use FindBin qw($Bin);

has 'config' => (
    is      => 'ro',
    builder => '_build_config',
);

sub _build_config {
    return from_json(read_file("${Bin}/../data/config.json", err_mode => 'croak'), {utf8 => 1});
}

sub get_config_param {
    my $self  = shift;
    my $param = shift;

    return $self->config->{$param};
}

1;
