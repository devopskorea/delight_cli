package Delight::Dooray;

use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP;
use Encode qw(encode_utf8 decode :fallback_all);

# JSON::PP for encoding (utf8: character strings → UTF-8 bytes for API)
my $JSON_UTF8 = JSON::PP->new->utf8;
# JSON::PP for decoding raw bytes (server response is UTF-8 JSON bytes)
my $JSON_DEC  = JSON::PP->new->utf8;

# --- Helpers (replace URI::Escape and LWP::MediaTypes) ---

# Percent-encode bytes that aren't RFC3986 unreserved.
sub _uri_escape {
    my ($s) = @_;
    return '' unless defined $s;
    my $bytes = utf8::is_utf8($s) ? Encode::encode_utf8($s) : $s;
    $bytes =~ s/([^A-Za-z0-9\-._~])/sprintf("%%%02X", ord($1))/ge;
    return $bytes;
}

sub _uri_unescape {
    my ($s) = @_;
    return $s unless defined $s;
    $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $s;
}

# Tiny MIME-type lookup by file extension (replaces LWP::MediaTypes).
my %MIME = (
    txt  => 'text/plain',
    md   => 'text/markdown',
    html => 'text/html',
    htm  => 'text/html',
    css  => 'text/css',
    csv  => 'text/csv',
    json => 'application/json',
    xml  => 'application/xml',
    yaml => 'application/yaml',
    yml  => 'application/yaml',
    pdf  => 'application/pdf',
    zip  => 'application/zip',
    gz   => 'application/gzip',
    tar  => 'application/x-tar',
    png  => 'image/png',
    jpg  => 'image/jpeg',
    jpeg => 'image/jpeg',
    gif  => 'image/gif',
    svg  => 'image/svg+xml',
    webp => 'image/webp',
    mp3  => 'audio/mpeg',
    mp4  => 'video/mp4',
);
sub _guess_mime {
    my ($path) = @_;
    if ($path && $path =~ /\.([A-Za-z0-9]+)$/) {
        my $ext = lc $1;
        return $MIME{$ext} if $MIME{$ext};
    }
    return 'application/octet-stream';
}

# Decompress if Content-Encoding indicates gzip. Returns bytes either way.
sub _maybe_gunzip {
    my ($bytes, $encoding) = @_;
    return $bytes unless defined $bytes && length($bytes);
    return $bytes unless defined $encoding && $encoding =~ /gzip/i;
    require IO::Uncompress::Gunzip;
    my $out;
    IO::Uncompress::Gunzip::gunzip(\$bytes => \$out) or return $bytes;
    return $out;
}

# Dooray API sometimes returns double-encoded UTF-8 for non-ASCII text.
# After decode, strings contain UTF-8 byte values as Latin-1 codepoints.
# This recursively decodes the second UTF-8 layer.
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
        ua     => HTTP::Tiny->new(timeout => 60, agent => 'delight/0.1 '),
        # Separate UA for file downloads — we follow redirects manually to preserve auth.
        ua_no_redir => HTTP::Tiny->new(timeout => 120, agent => 'delight/0.1 ', max_redirect => 0),
        token  => $args{token},
        domain => $args{domain} || 'https://api.dooray.com',
    }, $class;
}

sub _auth_value { return "dooray-api " . ($_[0]->{token} // '') }

sub _file_api_url {
    my ($self, $path) = @_;
    (my $domain = $self->{domain}) =~ s|https://api\.|https://file-api.|;
    return "$domain/uploads$path";
}

sub request {
    my ($self, $method, $path, $params) = @_;
    my $url = $self->{domain} . $path;
    my %headers = (
        'Authorization' => $self->_auth_value,
        'Accept'        => 'application/json',
        'Accept-Encoding' => 'identity',  # ask server not to gzip; simpler decode
    );
    my %opts = (headers => \%headers);
    if ($params) {
        $headers{'Content-Type'} = 'application/json';
        $opts{content} = $JSON_UTF8->encode($params);
    }

    my $res = $self->{ua}->request($method, $url, \%opts);

    my $body = _maybe_gunzip($res->{content}, $res->{headers}{'content-encoding'});

    if ($res->{success}) {
        return { header => { isSuccessful => 1 } } unless defined $body && length $body;
        my $data = $JSON_DEC->decode($body);
        _fix_double_utf8($data);
        return $data;
    } else {
        my $status = "$res->{status} $res->{reason}";
        if (defined $body && length $body) {
            my $data = eval { $JSON_DEC->decode($body) };
            if ($data && $data->{header}{resultMessage}) {
                my $rm = $data->{header}{resultMessage};
                $rm =~ s/\+/ /g;
                $rm = _uri_unescape($rm);
                $rm = Encode::decode('UTF-8', $rm) if !utf8::is_utf8($rm);
                $status .= " - $rm";
            } else {
                $status .= " " . (eval { decode('UTF-8', $body, FB_DEFAULT) } // $body);
            }
        }
        die "API Error ($method $path): $status\n";
    }
}

# --- Common / Members ---

sub whoami        { $_[0]->request('GET', '/common/v1/members/me') }
sub list_projects { $_[0]->request('GET', '/project/v1/projects') }

sub search_members {
    my ($self, $name) = @_;
    $self->request('GET', "/common/v1/members?name=" . _uri_escape($name));
}

sub search_members_by_email {
    my ($self, $email) = @_;
    $self->request('GET', "/common/v1/members?externalEmailAddresses=$email");
}

# --- Project Settings ---

sub list_workflows {
    my ($self, $project_id) = @_;
    $self->request('GET', "/project/v1/projects/$project_id/workflows");
}

sub list_milestones {
    my ($self, $project_id) = @_;
    $self->request('GET', "/project/v1/projects/$project_id/milestones");
}

sub list_tags {
    my ($self, $project_id) = @_;
    $self->request('GET', "/project/v1/projects/$project_id/tags");
}

sub list_project_members {
    my ($self, $project_id) = @_;
    $self->request('GET', "/project/v1/projects/$project_id/members");
}

sub set_post_done {
    my ($self, $project_id, $post_id) = @_;
    $self->request('POST', "/project/v1/projects/$project_id/posts/$post_id/set-done", {});
}

sub set_post_workflow {
    my ($self, $project_id, $post_id, $workflow_id) = @_;
    $self->request('POST', "/project/v1/projects/$project_id/posts/$post_id/set-workflow", { workflowId => $workflow_id });
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

sub get_post {
    my ($self, $post_id) = @_;
    $self->request('GET', "/project/v1/posts/$post_id");
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

# Build a multipart/form-data body manually (no HTTP::Request::Common).
sub _build_multipart {
    my ($file_path, $name, $mime) = @_;

    open my $fh, '<:raw', $file_path or die "Cannot open $file_path: $!\n";
    my $file_bytes = do { local $/; <$fh> };
    close $fh;

    my $boundary = '----delight-' . sprintf("%x%x", time, $$);
    my $name_bytes = utf8::is_utf8($name) ? Encode::encode_utf8($name) : $name;
    # Sanitize filename for header (strip CR/LF and double-quote)
    (my $filename = $name_bytes) =~ tr/\r\n"//d;

    my $body = '';
    $body .= "--$boundary\r\n";
    $body .= qq{Content-Disposition: form-data; name="file"; filename="$filename"\r\n};
    $body .= "Content-Type: $mime\r\n\r\n";
    $body .= $file_bytes;
    $body .= "\r\n--$boundary\r\n";
    $body .= qq{Content-Disposition: form-data; name="name"\r\n\r\n};
    $body .= $name_bytes;
    $body .= "\r\n--$boundary--\r\n";

    return ($boundary, $body);
}

sub _file_upload_request {
    my ($self, $method, $url, $file_path, $name) = @_;

    my $mime = _guess_mime($file_path);
    my ($boundary, $body) = _build_multipart($file_path, $name, $mime);

    my $res = $self->{ua}->request($method, $url, {
        headers => {
            'Authorization' => $self->_auth_value,
            'Content-Type'  => "multipart/form-data; boundary=$boundary",
        },
        content => $body,
    });

    if ($res->{success}) {
        my $data = $JSON_DEC->decode($res->{content});
        _fix_double_utf8($data);
        return $data;
    }
    die "Upload Error: $res->{status} $res->{reason} " . ($res->{content} // '') . "\n";
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

sub get_wiki_page {
    my ($self, $page_id) = @_;
    $self->request('GET', "/wiki/v1/pages/$page_id");
}

sub get_wiki_page_files {
    my ($self, $wiki_id, $page_id) = @_;
    $self->request('GET', "/wiki/v1/wikis/$wiki_id/pages/$page_id/files");
}

# --- File Download ---
# Follows redirects manually so the Authorization header is re-applied
# (HTTP::Tiny strips auth on cross-host redirects).
sub download_file {
    my ($self, $url, $save_path) = @_;
    my %headers = ('Authorization' => $self->_auth_value);

    my $hops = 0;
    while ($hops++ < 10) {
        my $res = $self->{ua_no_redir}->request('GET', $url, { headers => \%headers });
        if ($res->{status} >= 300 && $res->{status} < 400 && $res->{headers}{location}) {
            $url = $res->{headers}{location};
            next;
        }
        if ($res->{success}) {
            open my $fh, '>:raw', $save_path or die "Could not open $save_path: $!\n";
            print $fh $res->{content};
            close $fh;
            return 1;
        }
        die "Download Error from $url: $res->{status} $res->{reason} " . ($res->{content} // '') . "\n";
    }
    die "Too many redirects downloading $url\n";
}

1;
