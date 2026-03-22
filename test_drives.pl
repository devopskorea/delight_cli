use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Delight::Config;
use Delight::Dooray;
use JSON::MaybeXS;

my $c = Delight::Config->new();
my $d = Delight::Dooray->new(token => $c->get('token'), domain => $c->get('domain'));
my $data = $d->request('GET', "/drive/v1/drives?type=project");
print encode_json($data);
