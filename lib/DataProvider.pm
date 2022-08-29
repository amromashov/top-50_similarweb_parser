package DataProvider;

use warnings;
use strict;

use Moo;
use FindBin qw($Bin);
use lib "${Bin}/../lib";

use Parser;
use CacheInterface;

has cache_interface => (
    is      => 'ro',
    default => sub {
        CacheInterface->new();
    }
);

has parser => (
    is      => 'ro',
    default => sub {
        Parser->new();
    }
);

sub generate_cached_response {
    my $self = shift;

    my $cache = $self->cache_interface->get_cache;

    my $result_html = _generate_html_table($cache);

    return $result_html;
}

sub update_cache {
    my $self = shift;
    $self->parser->update_cache();
}

sub _generate_html_table {
    my $cache = shift;

    my $result_html = "<table>\n<tr>\n<td>Rank</td>\n<td>Domain</td>\n<td>Metrics</td>\n</tr>\n";

    foreach my $site_obj (@{$cache}) {
        my $rank   = $site_obj->{rank};
        my $domain = $site_obj->{domain};
        my $metric = $site_obj->{metric} or "Undefined";
        $result_html .= "<tr>\n<td>$rank</td>\n<td>$domain</td>\n<td>$metric</td>\n</tr>\n";
    }

    $result_html .= "</table>";

    return $result_html;
}

1;
