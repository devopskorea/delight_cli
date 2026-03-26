#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Delight::Config;
use Delight::Dooray;
use Data::Dumper;

# 1. Load configuration
my $config = Delight::Config->new(config_path => "$FindBin::Bin/../config.yml");
my $token = $config->get('token');

unless ($token) {
    die "Error: 'token' not found in config.yml. Please update config.yml with your Dooray API token.\n";
}

my $dooray = Delight::Dooray->new(
    token  => $token,
    domain => $config->get('domain'),
);

# 2. Get Project ID (from argument or use config)
my $project_id = $ARGV[0] || $config->get('default_project_id');

unless ($project_id) {
    print "No project ID provided or found in config. Fetching projects...\n";
    my $projects_res = $dooray->list_projects();
    if ($projects_res->{result} && @{$projects_res->{result}}) {
        $project_id = $projects_res->{result}[0]{id};
        print "Using first available project: " . $projects_res->{result}[0]{code} . " ($project_id)\n";
    } else {
        die "Error: No projects found. Cannot proceed without a project-id.\n";
    }
}

print "--- Testing with Project ID: $project_id ---\n\n";

# 3. Test Drive API with project-id
print "[Drive API Test]\n";
eval {
    my $drive_id = $dooray->get_drive_id_by_project_id($project_id);
    print "Found Drive ID: $drive_id for project $project_id\n";
    
    my $files = $dooray->list_files($drive_id, size => 3);
    print "Successfully listed files in Drive:\n";
    foreach my $file (@{$files->{result} || []}) {
        print " - $file->{name} ($file->{id})\n";
    }
};
if ($@) {
    print "Drive API Test Failed: $@\n";
}

print "\n";

# 4. Test Wiki API with project-id
print "[Wiki API Test]\n";
eval {
    my $wiki_id = $dooray->get_wiki_id_by_project_id($project_id);
    print "Found Wiki ID: $wiki_id for project $project_id\n";
    
    my $wiki_res = $dooray->list_wiki_pages($wiki_id);
    print "Successfully listed top-level Wiki pages:\n";
    foreach my $page (@{$wiki_res->{result} || []}) {
        print " - $page->{subject} ($page->{id})\n";
    }
};
if ($@) {
    print "Wiki API Test Failed: $@\n";
}

print "\n--- Test Completed ---\n";
