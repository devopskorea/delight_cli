package Delight::Dooray;

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common;
use JSON::XS;
use LWP::MediaTypes qw(guess_media_type);
use Encode;
use URI::Escape;

# JSON::XS with utf8=>1:
#   encode(): character strings → UTF-8 bytes (for sending to API)
#   decode(): UTF-8 bytes → character strings (for reading from API)
my $JSON = JSON::XS->new->utf8;

# Dooray API returns double-encoded UTF-8 for non-ASCII text.
# After decode, strings contain UTF-8 byte values as Latin-1 codepoints.
# This function decodes the second UTF-8 layer recursively.
sub _fix_double_utf8 {
    my ($data) = @_;
    if (ref $data eq 'HASH') {
        for my $key (keys %$data) {
            if (ref $data->{$key}) {
                _fix_double_utf8($data->{$key});
            } elsif (defined $data->{$key} && $data->{$key} =~ /[\xC2-\xF4][\x80-\xBF]/) {
                eval { $data->{$key} = Encode::decode('UTF-8', $data->{$key}, Encode::FB_CROAK) };
            }
        }
    } elsif (ref $data eq 'ARRAY') {
        for my $i (0 .. $#$data) {
            if (ref $data->[$i]) {
                _fix_double_utf8($data->[$i]);
            } elsif (defined $data->[$i] && $data->[$i] =~ /[\xC2-\xF4][\x80-\xBF]/) {
                eval { $data->[$i] = Encode::decode('UTF-8', $data->[$i], Encode::FB_CROAK) };
            }
        }
    }
}

sub new {
    my ($class, %args) = @_;
    return bless {
        ua     => LWP::UserAgent->new(),
        token  => $args{token},
        domain => $args{domain} || 'https://api.dooray.com',
    }, $class;
}

sub _auth_header { return ('Authorization' => "dooray-api " . $_[0]->{token}) }

sub _file_api_url {
    my ($self, $path) = @_;
    (my $domain = $self->{domain}) =~ s|https://api\.|https://file-api.|;
    return "$domain/uploads$path";
}

sub request {
    my ($self, $method, $path, $params) = @_;

    my $req = HTTP::Request->new($method => $self->{domain} . $path);
    $req->header($self->_auth_header);
    $req->header('Accept' => 'application/json');

    if ($params) {
        $req->header('Content-Type' => 'application/json');
        $req->content($JSON->encode($params));
    }

    my $res = $self->{ua}->request($req);

    if ($res->is_success) {
        my $content = $res->content;
        if ($content) {
            my $data = $JSON->decode($content);
            _fix_double_utf8($data);
            return $data;
        }
        return { header => { isSuccessful => 1 } };
    } else {
        die "API Error ($method $path): " . $res->status_line . " " . $res->content . "\n";
    }
}

# --- Common / Members ---

sub whoami        { $_[0]->request('GET', '/common/v1/members/me') }
sub list_projects { $_[0]->request('GET', '/project/v1/projects') }

sub search_members {
    my ($self, $name) = @_;
    $self->request('GET', "/common/v1/members?name=" . uri_escape($name));
}

sub search_members_by_email {
    my ($self, $email) = @_;
    $self->request('GET', "/common/v1/members?externalEmailAddresses=$email");
}

# --- Posts ---

sub list_posts {
    my ($self, $project_id) = @_;
    $self->request('GET', "/project/v1/projects/$project_id/posts");
}

sub list_posts_paginated {
    my ($self, $project_id, $page, $size) = @_;
    $page ||= 0;
    $size ||= 100;
    $self->request('GET', "/project/v1/projects/$project_id/posts?page=$page&size=$size");
}

sub get_post_detail {
    my ($self, $project_id, $post_id) = @_;
    $self->request('GET', "/project/v1/projects/$project_id/posts/$post_id");
}

sub create_post {
    my ($self, $project_id, $data) = @_;
    $self->request('POST', "/project/v1/projects/$project_id/posts", $data);
}

sub update_post {
    my ($self, $project_id, $post_id, $data) = @_;
    $self->request('PUT', "/project/v1/projects/$project_id/posts/$post_id", $data);
}

sub get_post_files {
    my ($self, $project_id, $post_id) = @_;
    $self->request('GET', "/project/v1/projects/$project_id/posts/$post_id/files");
}

# --- Calendar ---

sub get_default_calendar_id {
    my ($self) = @_;
    my $res = $self->request('GET', '/calendar/v1/calendars');
    foreach my $cal (@{$res->{result} || []}) {
        return $cal->{id} if $cal->{name} eq '내 캘린더' || $cal->{type} eq 'user';
    }
    return $res->{result}[0]{id} if $res->{result} && @{$res->{result}};
    die "Error: No calendar found.\n";
}

sub create_event {
    my ($self, $calendar_id, $event_data) = @_;
    $self->request('POST', "/calendar/v1/calendars/$calendar_id/events", $event_data);
}

sub list_events {
    my ($self, $time_min, $time_max, %opts) = @_;
    my $path = "/calendar/v1/calendars/*/events?timeMin=$time_min&timeMax=$time_max";
    $path .= "&q=" . $opts{q} if $opts{q};
    $path .= "&size=" . $opts{maxResults} if $opts{maxResults};
    $self->request('GET', $path);
}

sub get_event {
    my ($self, $calendar_id, $event_id) = @_;
    $self->request('GET', "/calendar/v1/calendars/$calendar_id/events/$event_id");
}

sub delete_event {
    my ($self, $calendar_id, $event_id, %opts) = @_;
    my $data = $opts{deleteType} ? { deleteType => $opts{deleteType} } : {};
    $self->request('POST', "/calendar/v1/calendars/$calendar_id/events/$event_id/delete", $data);
}

sub update_event {
    my ($self, $calendar_id, $event_id, $event_data) = @_;
    $self->request('PUT', "/calendar/v1/calendars/$calendar_id/events/$event_id", $event_data);
}

sub query_freebusy {
    my ($self, $params) = @_;
    $self->request('POST', "/calendar/v1/free-busy/query", $params);
}

# --- Drive ---

sub list_drives { $_[0]->request('GET', '/drive/v1/drives') }

sub get_private_drive_id {
    my ($self) = @_;
    my $data = $self->request('GET', '/drive/v1/drives?type=private');
    return $data->{result}[0]{id} if $data->{result} && @{$data->{result}};
    die "Error: Private drive not found.\n";
}

sub get_drive_id_by_project_id {
    my ($self, $project_id) = @_;
    my $data = $self->request('GET', "/drive/v1/drives?projectIds=$project_id");
    return $data->{result}[0]{id} if $data->{result} && @{$data->{result}};
    return $self->get_private_drive_id();
}

sub get_drive_id_by_wiki_id {
    my ($self, $wiki_id) = @_;
    my $data = $self->request('GET', "/drive/v1/drives?wikiIds=$wiki_id");
    return $data->{result}[0]{id} if $data->{result} && @{$data->{result}};
    return $self->get_private_drive_id();
}

sub get_root_folder_id {
    my ($self, $drive_id) = @_;
    my $data = $self->request('GET', "/drive/v1/drives/$drive_id/files?type=folder&subTypes=root");
    return $data->{result}[0]{id} if $data->{result} && @{$data->{result}};
    die "Error: Root folder not found for drive $drive_id.\n";
}

sub list_files {
    my ($self, $drive_id, %opts) = @_;
    my $size = $opts{size} || 5;
    my $page = $opts{page} || 0;
    my $type = $opts{type} || 'file';
    $self->request('GET', "/drive/v1/drives/$drive_id/files?size=$size&page=$page&type=$type");
}

sub _file_upload_request {
    my ($self, $method, $url, $file_path, $name) = @_;

    my $type = guess_media_type($file_path);
    my $req = POST(
        $url,
        $self->_auth_header,
        Content_Type => 'multipart/form-data',
        Content => [
            file => [ $file_path, $name, 'Content-Type' => $type ],
            name => $name,
        ]
    );
    $req->method($method) if $method ne 'POST';

    my $res = $self->{ua}->request($req);
    if ($res->is_success) {
        return $JSON->decode($res->content);
    } else {
        die "Upload Error: " . $res->status_line . " " . $res->content . "\n";
    }
}

sub upload_file {
    my ($self, $drive_id, $file_path, $name, $parent_id) = @_;
    $parent_id ||= $self->get_root_folder_id($drive_id);
    my $url = $self->_file_api_url("/drive/v1/drives/$drive_id/files") . "?parentId=$parent_id";
    $self->_file_upload_request('POST', $url, $file_path, $name);
}

sub update_file {
    my ($self, $drive_id, $file_id, $file_path, $name) = @_;
    my $url = $self->_file_api_url("/drive/v1/drives/$drive_id/files/$file_id");
    $self->_file_upload_request('PUT', $url, $file_path, $name);
}

sub find_file_by_name {
    my ($self, $drive_id, $name, $parent_id) = @_;
    $parent_id ||= $self->get_root_folder_id($drive_id);
    my $res = $self->request('GET', "/drive/v1/drives/$drive_id/files?parentId=$parent_id&size=100");
    foreach my $file (@{$res->{result} || []}) {
        return $file->{id} if $file->{name} eq $name;
    }
    return undef;
}

# --- Wiki ---

sub list_wikis { $_[0]->request('GET', '/wiki/v1/wikis') }

sub create_wiki_page {
    my ($self, $wiki_id, $data) = @_;
    $self->request('POST', "/wiki/v1/wikis/$wiki_id/pages", $data);
}

sub update_wiki_page {
    my ($self, $wiki_id, $page_id, $data) = @_;
    $self->request('PUT', "/wiki/v1/wikis/$wiki_id/pages/$page_id", $data);
}



sub list_wiki_pages_paginated {
    my ($self, $wiki_id, $page, $size, %opts) = @_;
    $page ||= 0;
    $size ||= 100;
    my $path = "/wiki/v1/wikis/$wiki_id/pages?page=$page&size=$size";
    $path .= "&parentPageId=" . $opts{parentPageId} if $opts{parentPageId};
    $self->request('GET', $path);
}

sub get_wiki_page_detail {
    my ($self, $wiki_id, $page_id) = @_;
    $self->request('GET', "/wiki/v1/wikis/$wiki_id/pages/$page_id");
}

sub get_wiki_page_files {
    my ($self, $wiki_id, $page_id) = @_;
    $self->request('GET', "/wiki/v1/wikis/$wiki_id/pages/$page_id/files");
}

# --- File Download ---

sub download_file {
    my ($self, $url, $save_path) = @_;

    my $req = HTTP::Request->new('GET' => $url);
    $req->header($self->_auth_header);

    # Handle 307 redirects manually to preserve Authorization header
    my $res = $self->{ua}->simple_request($req);
    while ($res->is_redirect) {
        $req = HTTP::Request->new('GET' => $res->header('Location'));
        $req->header($self->_auth_header);
        $res = $self->{ua}->simple_request($req);
    }

    if ($res->is_success) {
        open my $fh, '>:raw', $save_path or die "Could not open $save_path: $!\n";
        print $fh $res->content;
        close $fh;
        return 1;
    } else {
        die "Download Error from $url: " . $res->status_line . " " . $res->content . "\n";
    }
}

1;
