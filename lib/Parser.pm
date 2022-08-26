package Parser;

use strict;
use warnings;

use Mojo::Base -strict, -signatures, -async_await;
use FindBin qw($Bin);
use lib "${Bin}/../lib";
use List::Util qw (uniq);
use JSON;
use Mojo::UserAgent;
use Mojo::AsyncAwait;
use Mojo::Promise;
use AppConfig;
use Moo;

has cache_interface => (
    is      => 'ro',
    default => sub {
        CacheInterface->new();
    }
);

has config => (
    is      => 'ro',
    default => sub {
        AppConfig->new();
    }
);

has ua => (
    is      => 'ro',
    default => sub {
        Mojo::UserAgent->new;
    }
);

sub update_cache {
    my $self = shift;

    my $sites_updated_info;
    my $sites_updated_info_location_indexes;

    my $parse_promises;
    my $parse_promises_location;

    my $sites_list = $self->get_similarweb_response;

    for my $site_obj (@{$sites_list}) {
        push(@{$parse_promises}, $self->ua->get_p($site_obj->{domain}));
    }

    Mojo::Promise->all_settled(@{$parse_promises})->then(
        sub {
            my @promises = @_;
            my $counter  = 0;

            for my $tx (@promises) {
                if ($tx->{status} eq 'fulfilled') {
                    my $res = $tx->{value}->[0]->res;

                    if ($res->headers->location) {
                        push(@{$parse_promises_location},             $self->ua->get_p($res->headers->location));
                        push(@{$sites_updated_info_location_indexes}, $counter);
                    }

                    my $matched_metric = ($res->body) =~ m/(google-analytics|mc\.yandex)/;
                    $sites_list->[$counter]{metric} = $matched_metric;

                } else {
                    $sites_list->[$counter]{metric} = $tx->{reason}->[0];
                }
                $counter++;
            }
        }
        )->catch(
        sub {
            my $err = shift;
            warn $err;
        }
        )->wait;

    Mojo::Promise->all_settled(@{$parse_promises_location})->then(
        sub {
            my @promises = @_;
            my $counter  = 0;

            for my $tx (@promises) {
                if ($tx->{status} eq 'fulfilled') {
                    my $res = $tx->{value}->[0]->res;

                    my $matched_metric = ($res->body) =~ m/(google-analytics|mc\.yandex)/;
                    $sites_list->[$sites_updated_info_location_indexes->[$counter]]{metric} = $matched_metric;

                } else {
                    $sites_list->[$sites_updated_info_location_indexes->[$counter]]{metric} = $tx->{reason}->[0];
                }
                $counter++;
            }

            $self->cache_interface->set_cache($sites_list);
        }
        )->catch(
        sub {
            my $err = shift;
            warn $err;
        }
        )->wait;

    $self->cache_interface->set_cache($sites_updated_info);

}

sub get_similarweb_response {
    my $self = shift;

    my $domains;
    my $sites_list;
    my $parse_p;

    my $query_link = $self->config->get_config_param('similarweb_api_query');

    my $res = $self->ua->get($query_link);

    for (@{$res->result->json->{top_sites}}) {
        push(@{$sites_list}, $_);
    }

    return $sites_list;

}

1;
