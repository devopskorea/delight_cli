#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Delight::Config;
use Delight::Dooray;
use Data::Dumper;

my $config = Delight::Config->new(config_path => "$FindBin::Bin/../config.yml");
my $dooray = Delight::Dooray->new(
    token  => $config->get('token'),
    domain => $config->get('domain'),
);

my $drive_id = $dooray->get_private_drive_id();
print "Drive ID: $drive_id\n";

my $res = $dooray->request('GET', "/drive/v1/drives/$drive_id/files?type=folder&subTypes=root");
print "Root Folder Info: " . Dumper($res);
