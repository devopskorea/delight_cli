package Delight::Dooray;

use strict;
use warnings;
use LWP::UserAgent;
use JSON::MaybeXS;
use LWP::MediaTypes qw(guess_media_type);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        ua    => LWP::UserAgent->new(),
        token => $args{token},
        domain => $args{domain} || 'https://api.dooray.com',
        %args
    }, $class;
    return $self;
}

sub request {
    my ($self, $method, $path, $params) = @_;
    
    my $url = $self->{domain} . $path;
    my $ua = $self->{ua};
    
    use HTTP::Request;
    my $req = HTTP::Request->new($method => $url);
    $req->header('Authorization' => "dooray-api " . $self->{token});
    $req->header('Accept'        => 'application/json');

    if ($params) {
        $req->header('Content-Type' => 'application/json');
        $req->content(encode_json($params));
    }
    
    my $res = $ua->request($req);
    
    if ($res->is_success) {
        return decode_json($res->content) if $res->content;
        return { header => { isSuccessful => 1 } }; # Some DELETE/PUT might return empty
    } else {
        die "API Error ($method $path): " . $res->status_line . " " . $res->content . "\n";
    }
}

sub whoami {
    my ($self) = @_;
    return $self->request('GET', '/common/v1/members/me');
}

sub list_projects {
    my ($self) = @_;
    return $self->request('GET', '/project/v1/projects');
}

sub list_posts {
    my ($self, $project_id) = @_;
    return $self->request('GET', "/project/v1/projects/$project_id/posts");
}

sub get_default_calendar_id {
    my ($self) = @_;
    my $res = $self->request('GET', '/calendar/v1/calendars');
    foreach my $cal (@{$res->{result} || []}) {
        if ($cal->{name} eq '내 캘린더' || $cal->{type} eq 'user') {
            return $cal->{id};
        }
    }
    return $res->{result}[0]{id} if $res->{result} && @{$res->{result}};
    die "Error: No calendar found.\n";
}

sub create_event {
    my ($self, $calendar_id, $event_data) = @_;
    return $self->request('POST', "/calendar/v1/calendars/$calendar_id/events", $event_data);
}

sub list_events {
    my ($self, $time_min, $time_max, %opts) = @_;
    my $path = "/calendar/v1/calendars/*/events?timeMin=$time_min&timeMax=$time_max";
    $path .= "&q=" . $opts{q} if $opts{q};
    $path .= "&size=" . $opts{maxResults} if $opts{maxResults};
    return $self->request('GET', $path);
}

sub get_event {
    my ($self, $calendar_id, $event_id) = @_;
    return $self->request('GET', "/calendar/v1/calendars/$calendar_id/events/$event_id");
}

sub delete_event {
    my ($self, $calendar_id, $event_id) = @_;
    return $self->request('DELETE', "/calendar/v1/calendars/$calendar_id/events/$event_id?deleteType=all");
}

sub update_event {
    my ($self, $calendar_id, $event_id, $event_data) = @_;
    return $self->request('PUT', "/calendar/v1/calendars/$calendar_id/events/$event_id", $event_data);
}

sub search_members {
    my ($self, $name) = @_;
    require URI::Escape;
    my $escaped_name = URI::Escape::uri_escape($name);
    return $self->request('GET', "/common/v1/members?name=$escaped_name");
}

sub query_freebusy {
    my ($self, $params) = @_;
    return $self->request('POST', "/calendar/v1/free-busy/query", $params);
}

sub get_private_drive_id {
    my ($self) = @_;
    my $data = $self->request('GET', '/drive/v1/drives?type=private');
    if ($data->{result} && @{$data->{result}}) {
        return $data->{result}[0]{id};
    }
    die "Error: Private drive not found.\n";
}

sub get_drive_id_by_project_id {
    my ($self, $project_id) = @_;
    my $data = $self->request('GET', "/drive/v1/drives?projectIds=$project_id");
    if ($data->{result} && @{$data->{result}}) {
        # Return the first drive associated with the project
        return $data->{result}[0]{id};
    }
    # Fallback to private drive if project drive is not found
    return $self->get_private_drive_id();
}

sub get_drive_id_by_wiki_id {
    my ($self, $wiki_id) = @_;
    my $data = $self->request('GET', "/drive/v1/drives?wikiIds=$wiki_id");
    if ($data->{result} && @{$data->{result}}) {
        return $data->{result}[0]{id};
    }
    return $self->get_private_drive_id();
}

sub get_root_folder_id {
    my ($self, $drive_id) = @_;
    my $data = $self->request('GET', "/drive/v1/drives/$drive_id/files?type=folder&subTypes=root");
    if ($data->{result} && @{$data->{result}}) {
        return $data->{result}[0]{id};
    }
    die "Error: Root folder not found for drive $drive_id.\n";
}

sub list_files {
    my ($self, $drive_id, %options) = @_;
    my $url = "/drive/v1/drives/$drive_id/files";
    my @params;
    push @params, "size=" . ($options{size} || 5);
    push @params, "page=" . ($options{page} || 0);
    push @params, "type=" . ($options{type} || 'file');
    
    $url .= "?" . join("&", @params) if @params;
    
    return $self->request('GET', $url);
}

sub upload_file {
    my ($self, $drive_id, $file_path, $name, $parent_id) = @_;
    
    $parent_id ||= $self->get_root_folder_id($drive_id);
    
    require HTTP::Request::Common;
    
    # Transform domain: api.dooray.com -> file-api.dooray.com
    my $file_api_domain = $self->{domain};
    $file_api_domain =~ s/https:\/\/api\./https:\/\/file-api\./;
    
    # Transform path: /drive/v1/... -> /uploads/drive/v1/...
    my $path = "/drive/v1/drives/$drive_id/files";
    my $url = "$file_api_domain/uploads$path";
    $url .= "?parentId=$parent_id";

    my $type = guess_media_type($file_path);

    my $req = HTTP::Request::Common::POST(
        $url,
        'Authorization' => "dooray-api " . $self->{token},
        Content_Type => 'multipart/form-data',
        Content => [
            file => [ $file_path, $name, 'Content-Type' => $type ],
            name => $name,
        ]
    );

    # print "DEBUG: Direct Upload URL: $url\n";
    my $res = $self->{ua}->request($req);
    
    if ($res->is_success) {
        return decode_json($res->content);
    } else {
        die "Upload Error: " . $res->status_line . " " . $res->content . "\n";
    }
}

sub update_file {
    my ($self, $drive_id, $file_id, $file_path, $name) = @_;
    
    require HTTP::Request::Common;
    
    # Transform domain: api.dooray.com -> file-api.dooray.com
    my $file_api_domain = $self->{domain};
    $file_api_domain =~ s/https:\/\/api\./https:\/\/file-api\./;
    
    # PUT /uploads/drive/v1/drives/{driveId}/files/{fileId}
    my $url = "$file_api_domain/uploads/drive/v1/drives/$drive_id/files/$file_id";

    my $type = guess_media_type($file_path);

    my $req = HTTP::Request::Common::POST( # Dooray often uses POST with _method=PUT or just PUT for file uploads
        $url,
        'Authorization' => "dooray-api " . $self->{token},
        Content_Type => 'multipart/form-data',
        Content => [
            file => [ $file_path, $name, 'Content-Type' => $type ],
            name => $name,
        ]
    );
    $req->method('PUT');

    my $res = $self->{ua}->request($req);
    
    if ($res->is_success) {
        return decode_json($res->content);
    } else {
        die "Update Error: " . $res->status_line . " " . $res->content . "\n";
    }
}

sub find_file_by_name {
    my ($self, $drive_id, $name, $parent_id) = @_;
    $parent_id ||= $self->get_root_folder_id($drive_id);
    
    # We might need to paginate if there are many files, but for now search first 100
    my $res = $self->request('GET', "/drive/v1/drives/$drive_id/files?parentId=$parent_id&size=100");
    foreach my $file (@{$res->{result} || []}) {
        if ($file->{name} eq $name) {
            return $file->{id};
        }
    }
    return undef;
}

sub list_wikis {
    my ($self) = @_;
    return $self->request('GET', '/wiki/v1/wikis');
}

sub list_drives {
    my ($self) = @_;
    return $self->request('GET', '/drive/v1/drives');
}

sub list_posts_paginated {
    my ($self, $project_id, $page, $size) = @_;
    $page ||= 0;
    $size ||= 100;
    return $self->request('GET', "/project/v1/projects/$project_id/posts?page=$page&size=$size");
}

sub get_post_detail {
    my ($self, $project_id, $post_id) = @_;
    return $self->request('GET', "/project/v1/projects/$project_id/posts/$post_id");
}

sub get_post_files {
    my ($self, $project_id, $post_id) = @_;
    return $self->request('GET', "/project/v1/projects/$project_id/posts/$post_id/files");
}

sub list_wiki_pages_paginated {
    my ($self, $wiki_id, $page, $size) = @_;
    $page ||= 0;
    $size ||= 100;
    return $self->request('GET', "/wiki/v1/wikis/$wiki_id/pages?page=$page&size=$size");
}

sub get_wiki_page_detail {
    my ($self, $wiki_id, $page_id) = @_;
    return $self->request('GET', "/wiki/v1/wikis/$wiki_id/pages/$page_id");
}

sub get_wiki_page_files {
    my ($self, $wiki_id, $page_id) = @_;
    return $self->request('GET', "/wiki/v1/wikis/$wiki_id/pages/$page_id/files");
}

sub download_file {
    my ($self, $url, $save_path) = @_;
    
    use HTTP::Request;
    my $req = HTTP::Request->new('GET' => $url);
    $req->header('Authorization' => "dooray-api " . $self->{token});
    
    # Handle 307 redirects manually to preserve Authorization header
    my $res = $self->{ua}->simple_request($req);
    
    while ($res->is_redirect) {
        my $redirect_url = $res->header('Location');
        $req = HTTP::Request->new('GET' => $redirect_url);
        $req->header('Authorization' => "dooray-api " . $self->{token});
        $res = $self->{ua}->simple_request($req);
    }
    
    if ($res->is_success) {
        open my $fh, '>', $save_path or die "Could not open $save_path: $!\n";
        binmode $fh;
        print $fh $res->content;
        close $fh;
        return 1;
    } else {
        die "Download Error from $url: " . $res->status_line . " " . $res->content . "\n";
    }
}

1;

