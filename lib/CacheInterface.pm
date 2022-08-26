package CacheInterface;

use Moo;
use File::Slurp qw(read_file write_file);
use JSON;
use FindBin qw($Bin);
use lib "${Bin}";
use AppConfig;

has cache => (
    is      => 'rw',
    builder => '_build_cache'
);

has config => (
    is      => 'ro',
    default => sub {
        AppConfig->new();
    }
);

sub _build_cache {
    my $config = AppConfig->new();
    return from_json(read_file("$Bin/" . $config->get_config_param('cache_path'), err_mode => 'croak'), {utf8 => 1});
}

sub get_cache {
    my $self = shift;
    return $self->cache;
}

sub set_cache {
    my $self  = shift;
    my $cache = shift;

    $self->cache($cache);

    write_file("$Bin/" . $self->config->get_config_param('cache_path'), to_json($self->cache));
}

1;
