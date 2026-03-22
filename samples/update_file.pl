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

# This sample demonstrates updating an existing file on Dooray! Drive
# using the direct File API with a PUT request.

my $config = Delight::Config->new();
my $token = $config->get('token');
my $base_domain = $config->get('domain') || 'https://api.dooray.com';

unless ($token) {
    die "Error: Token not found in config.yml. Run 'delight config token <token>' first.\n";
}

# 1. Initialize Dooray Client to get IDs
my $dooray = Delight::Dooray->new(token => $token, domain => $base_domain);
my $drive_id = $dooray->get_private_drive_id();

# For this sample, we'll look for a file to update. 
# You can replace this with a specific file_id.
print "Looking for a file to update in drive $drive_id...\n";
my $files_data = $dooray->request('GET', "/drive/v1/drives/$drive_id/files?type=file&limit=1");
my $file_to_update = $files_data->{result}[0];

unless ($file_to_update) {
    die "Error: No files found in your drive to update. Upload one first using 'delight drive files create'.\n";
}

my $file_id = $file_to_update->{id};
my $old_name = $file_to_update->{name};
print "Selected file: $old_name (ID: $file_id)\n";

# 2. Prepare the PUT request to the File API
# Transform domain: api.dooray.com -> file-api.dooray.com
my $file_api_domain = $base_domain;
$file_api_domain =~ s/https:\/\/api\./https:\/\/file-api\./;

my $url = "$file_api_domain/uploads/drive/v1/drives/$drive_id/files/$file_id";

# Local file to upload (we'll just use README.md for this sample)
my $local_path = "$FindBin::Bin/../README.md";
my $new_name = "updated_from_sample.txt";

print "Updating to $url...\n";

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request::Common::PUT(
    $url,
    'Authorization' => "dooray-api $token",
    'Content-Type'  => 'multipart/form-data',
    'Content'       => [
        file => [ $local_path, $new_name, 'Content-Type' => 'text/plain' ],
    ]
);

# 3. Execute request
my $res = $ua->request($req);

if ($res->is_success) {
    print "Updated successfully!\n";
    print $res->content . "\n";
} else {
    print "Update Failed: " . $res->status_line . "\n";
    print $res->content . "\n";
}
