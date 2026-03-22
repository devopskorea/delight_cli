#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Delight::Config;
use Delight::Dooray;
use POSIX qw(strftime);
use JSON::MaybeXS;
use Data::Dumper;
$Data::Dumper::Indent = 1;

# Load config
my $config = Delight::Config->new(config_path => "$FindBin::Bin/../config.yml");
my $dooray = Delight::Dooray->new(
    token  => $config->get('token'),
    domain => $config->get('domain'),
);

print "Checking connectivity for: " . $config->get('domain') . "\n";

# 1. Get my member info and default calendar
my $me_res = $dooray->whoami();
my $my_id = $me_res->{result}{id};
print "My Member ID: $my_id\n";

my $cal_res = $dooray->request('GET', '/calendar/v1/calendars');
my $calendar_id;
foreach my $cal (@{$cal_res->{result}}) {
    if ($cal->{name} eq '내 캘린더' || $cal->{type} eq 'user') {
        $calendar_id = $cal->{id};
        last;
    }
}
$calendar_id ||= $cal_res->{result}[0]{id};

print "Using Calendar ID: $calendar_id\n";

# 2. Prepare event times
my $start_time = time + 3600; # 1 hour from now
my $end_time   = $start_time + 3600; # 1 hour duration

my $startedAt = strftime("%Y-%m-%dT%H:%M:%S+09:00", localtime($start_time));
my $endedAt   = strftime("%Y-%m-%dT%H:%M:%S+09:00", localtime($end_time));

# 3. Create event
my $event_data = {
    users => {
        to => [
            {
                type => 'member',
                member => { organizationMemberId => $my_id }
            }
        ]
    },
    subject => "Dooray! CLI Test Event",
    body => {
        mimeType => "text/html",
        content  => "This event was created by the <b>Delight CLI</b> sample code."
    },
    startedAt => $startedAt,
    endedAt   => $endedAt,
    location  => "Virtual Office",
};

print "Creating event: " . $event_data->{subject} . " ($startedAt to $endedAt)\n";

my $res = $dooray->request('POST', "/calendar/v1/calendars/$calendar_id/events", $event_data);

if ($res->{header}{isSuccessful}) {
    print "Event created successfully!\n";
    print "Event ID: " . $res->{result}{id} . "\n";
} else {
    print "Failed to create event: " . $res->{header}{resultMessage} . "\n";
}
