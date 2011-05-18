# $Id: Makefile.PL 2170 2009-10-08 12:00:00Z kamelkev $
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'CSS::Simple',
    PMLIBDIRS => [ 'lib' ],
    PREREQ_PM => {
	'Carp' => 0,
        'Tie::IxHash' => 0
    },
    VERSION_FROM => 'lib/CSS/Simple.pm',
    AUTHOR => 'Kevin Kamel <kamelkev@mailermailer.com>',
    ABSTRACT => 'Interface through which to read/write/manipulate CSS files while respecting the cascade order',
    LICENSE => 'perl',
);


sub MY::postamble {
  return <<'MAKE_FRAG';
all :: README

README: lib/CSS/Simple.pm
	pod2text $> > README
MAKE_FRAG
}
