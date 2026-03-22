package Delight::Config;

use strict;
use warnings;
use YAML::XS;
use File::HomeDir;
use File::Spec;

sub new {
    my ($class, %args) = @_;
    my $config_path = $args{config_path};
    unless ($config_path) {
        if (-e 'config.yml') {
            $config_path = 'config.yml';
        } else {
            $config_path = File::Spec->catfile(File::HomeDir->my_home, '.delight.yml');
        }
    }
    my $self = bless {
        config_path => $config_path,
        %args
    }, $class;
    $self->load();
    return $self;
}

sub load {
    my ($self) = @_;
    if (-e $self->{config_path}) {
        $self->{config} = YAML::XS::LoadFile($self->{config_path});
    } else {
        $self->{config} = {
            domain => 'https://api.dooray.com',
            token  => '',
        };
    }
}

sub save {
    my ($self) = @_;
    YAML::XS::DumpFile($self->{config_path}, $self->{config});
}

sub get {
    my ($self, $key) = @_;
    return $self->{config}->{$key};
}

sub set {
    my ($self, $key, $value) = @_;
    $self->{config}->{$key} = $value;
}

1;
