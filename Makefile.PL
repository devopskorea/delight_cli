use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Delight',
    AUTHOR           => 'imyagirl',
    VERSION          => '0.1.0',
    ABSTRACT         => 'A command-line interface for Dooray!',
    LICENSE          => 'artistic_2',
    EXE_FILES        => ['bin/delight'],
    test             => { TESTS => 'samples/*.pl' },
    PREREQ_PM        => {
        'YAML::XS'              => 0,
        'JSON::XS'              => 0,
        'File::HomeDir'         => 0,
        'LWP::UserAgent'        => 0,
        'HTTP::Request'         => 0,
        'HTTP::Request::Common' => 0,
        'LWP::MediaTypes'       => 0,
        'URI::Escape'           => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Delight-*' },
);
