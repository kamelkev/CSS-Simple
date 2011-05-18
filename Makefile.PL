# $Id: Makefile.PL 2170 2009-10-08 12:00:00Z kamelkev $
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'CSS::Simple',
    PMLIBDIRS => [ 'lib' ],
    PREREQ_PM => {
	'Carp' => 0,
        'Tie::IxHash' => 0
    },
    dist => {
	PREOP => 'pod2text lib/CSS/Simple.pm > README; ln -f README $(DISTVNAME)/README',
    },
    VERSION_FROM => 'lib/CSS/Simple.pm',
    AUTHOR => 'Kevin Kamel <kamelkev@mailermailer.com>',
    ABSTRACT => 'Interface through which to read/write/manipulate CSS files while respecting the cascade order',
    LICENSE => 'perl',
);
