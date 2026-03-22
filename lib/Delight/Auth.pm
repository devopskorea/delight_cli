package Delight::Auth;

use strict;
use warnings;
use LWP::Authen::OAuth2;
use Config::Tiny;
use File::HomeDir;
use File::Spec;
use JSON::MaybeXS;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        config_path => File::Spec->catfile(File::HomeDir->my_home, '.delight_cli.ini'),
        %args
    }, $class;
    $self->load_config();
    return $self;
}

sub load_config {
    my ($self) = @_;
    if (-e $self->{config_path}) {
        $self->{config} = Config::Tiny->read($self->{config_path});
    } else {
        $self->{config} = Config::Tiny->new();
    }
}

sub save_config {
    my ($self) = @_;
    $self->{config}->write($self->{config_path});
}

sub get_oauth2 {
    my ($self) = @_;
    
    my $client_id = $self->{config}->{auth}->{client_id};
    my $client_secret = $self->{config}->{auth}->{client_secret};
    
    unless ($client_id && $client_secret) {
        die "Error: client_id and client_secret must be configured. Run 'delight auth setup'\n";
    }

    return LWP::Authen::OAuth2->new(
        client_id     => $client_id,
        client_secret => $client_secret,
        service_provider => 'Google',
        redirect_uri => 'urn:ietf:wg:oauth:2.0:oob', # Out-of-band for CLI
    );
}

sub login {
    my ($self) = @_;
    my $oauth2 = $self->get_oauth2();
    
    print "Go to the following URL to authorize the application:\n";
    print $oauth2->authorization_url(scope => 'https://www.googleapis.com/auth/drive.readonly') . "\n";
    print "\nEnter the authorization code: ";
    
    my $code = <STDIN>;
    chomp $code;
    
    my $token = $oauth2->get_access_token($code);
    if ($token) {
        $self->{config}->{auth}->{access_token} = $token->access_token;
        $self->{config}->{auth}->{refresh_token} = $token->refresh_token;
        $self->{config}->{auth}->{expires_at} = time + $token->expires_in;
        $self->save_config();
        print "Successfully logged in!\n";
    } else {
        die "Failed to obtain access token.\n";
    }
}

sub get_token {
    my ($self) = @_;
    return $self->{config}->{auth}->{access_token};
}

1;
