package Delight::Drive;

use strict;
use warnings;
use LWP::UserAgent;
use JSON::MaybeXS;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        ua => LWP::UserAgent->new(),
        auth => $args{auth},
        %args
    }, $class;
    return $self;
}

sub list_files {
    my ($self) = @_;
    my $token = $self->{auth}->get_token();
    
    unless ($token) {
        die "Error: No access token found. Run 'delight auth login'\n";
    }

    my $url = "https://www.googleapis.com/drive/v3/files";
    my $res = $self->{ua}->get($url, 
        'Authorization' => "Bearer $token",
        'Accept' => 'application/json'
    );

    if ($res->is_success) {
        my $data = decode_json($res->content);
        return $data->{files};
    } else {
        die "Failed to list files: " . $res->status_line . " " . $res->content . "\n";
    }
}

1;
