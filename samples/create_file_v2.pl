#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Delight::Config;
use Delight::Dooray;
use HTTP::Request::Common;
use LWP::UserAgent;
use JSON::MaybeXS;

# This sample demonstrates creating a new file on Dooray! Drive
# by sending a POST request to the main API, following the 307 redirect.

my $config = Delight::Config->new();
my $token = $config->get('token');
my $base_domain = $config->get('domain') || 'https://api.dooray.com';

unless ($token) {
    die "Error: Token not found in config.yml. Run 'delight config token <token>' first.\n";
}

# 1. Initialize Dooray Client to get IDs
my $dooray = Delight::Dooray->new(token => $token, domain => $base_domain);
my $drive_id = $dooray->get_private_drive_id();
my $parent_id = $dooray->get_root_folder_id($drive_id);

print "Targeting Drive: $drive_id, Parent: $parent_id\n";

# 2. Prepare the POST request to the main API
my $url = "$base_domain/drive/v1/drives/$drive_id/files?parentId=$parent_id";
my $local_path = "$FindBin::Bin/../README.md";
my $ts = time();
my $remote_name = "file_via_redirect_$ts.txt";

print "Uploading to $url...\n";

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request::Common::POST(
    $url,
    'Authorization' => "dooray-api $token",
    'Content-Type'  => 'multipart/form-data',
    'Content'       => [
        file => [ $local_path, $remote_name, 'Content-Type' => 'text/plain' ],
    ]
);

# 3. Handle the 307 Redirect manually
my $res = $ua->request($req);

if ($res->code == 307) {
    my $redirect_url = $res->header('Location');
    print "Got 307 Redirect to: $redirect_url\n";
    
    # Re-send the request to the new URL
    $req->uri($redirect_url);
    $res = $ua->request($req);
}

if ($res->is_success) {
    print "Created successfully!\n";
    print $res->content . "\n";
} else {
    print "Creation Failed: " . $res->status_line . "\n";
    print $res->content . "\n";
}
