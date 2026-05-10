use strict;
use warnings;
use ExtUtils::MakeMaker;

# delight only uses Perl core modules. No CPAN deps required.
# Core modules used:
#   HTTP::Tiny, JSON::PP, Encode, File::Spec, File::Path, Getopt::Long,
#   POSIX, Time::Piece, Fcntl, SDBM_File, IPC::Open2, IO::Uncompress::Gunzip.
WriteMakefile(
    NAME      => 'Delight',
    AUTHOR    => 'imyagirl',
    VERSION   => '0.1.0',
    ABSTRACT  => 'A command-line interface for Dooray!',
    LICENSE   => 'artistic_2',
    EXE_FILES => ['bin/delight'],
    test      => { TESTS => 'samples/*.pl' },
    PREREQ_PM => {},
    MIN_PERL_VERSION => '5.14.0',  # HTTP::Tiny + JSON::PP in core since 5.14
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Delight-*' },
);
