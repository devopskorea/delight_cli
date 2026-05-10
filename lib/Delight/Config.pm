package Delight::Config;

use strict;
use warnings;
use File::Spec;

sub new {
    my ($class, %args) = @_;
    my $config_path = $args{config_path};
    unless ($config_path) {
        if (-e 'config.yml') {
            $config_path = 'config.yml';
        } else {
            $config_path = File::Spec->catfile(_home(), '.delight.yml');
        }
    }
    my $self = bless {
        config_path => $config_path,
        %args
    }, $class;
    $self->load();
    return $self;
}

sub _home {
    return $ENV{HOME} || (getpwuid($<))[7] || '.';
}

sub load {
    my ($self) = @_;
    if (-e $self->{config_path}) {
        $self->{config} = _load_flat_yaml($self->{config_path});
    } else {
        $self->{config} = {
            domain => 'https://api.dooray.com',
            token  => '',
        };
    }
}

sub save {
    my ($self) = @_;
    _dump_flat_yaml($self->{config_path}, $self->{config});
}

sub get {
    my ($self, $key) = @_;
    return $self->{config}->{$key};
}

sub set {
    my ($self, $key, $value) = @_;
    $self->{config}->{$key} = $value;
}

# Minimal flat-YAML parser: one "key: value" per line.
# Values may be bare or "double-quoted" or 'single-quoted'.
# Lines starting with '#' or '---' are ignored. No nesting, no lists.
sub _load_flat_yaml {
    my ($path) = @_;
    open my $fh, '<:encoding(UTF-8)', $path or die "Cannot read $path: $!";
    my %h;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*$/ || $line =~ /^\s*#/ || $line =~ /^---\s*$/;
        if ($line =~ /^([A-Za-z_][\w]*):\s*(.*)$/) {
            my ($k, $v) = ($1, $2);
            $v =~ s/^\s+|\s+$//g;
            if ($v =~ /^"(.*)"$/) { $v = $1; $v =~ s/\\"/"/g; }
            elsif ($v =~ /^'(.*)'$/) { $v = $1; }
            $h{$k} = $v;
        }
    }
    close $fh;
    return \%h;
}

# Minimal flat-YAML dumper. Quotes values that look numeric (preserve as string)
# or contain characters that would need escaping.
sub _dump_flat_yaml {
    my ($path, $href) = @_;
    open my $fh, '>:encoding(UTF-8)', $path or die "Cannot write $path: $!";
    print $fh "---\n";
    for my $k (sort keys %$href) {
        my $v = $href->{$k};
        $v = '' unless defined $v;
        my $out;
        if ($v eq '') {
            $out = "''";
        } elsif ($v =~ /^[+-]?\d+$/) {
            # Numeric-looking → quote to keep as string (Dooray IDs are big numerics)
            $out = qq{"$v"};
        } elsif ($v =~ /[:#"'\n\\]/ || $v =~ /^\s/ || $v =~ /\s$/) {
            (my $esc = $v) =~ s/\\/\\\\/g;
            $esc =~ s/"/\\"/g;
            $out = qq{"$esc"};
        } else {
            $out = $v;
        }
        print $fh "$k: $out\n";
    }
    close $fh;
}

1;
