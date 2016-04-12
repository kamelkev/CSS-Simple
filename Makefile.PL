use ExtUtils::MakeMaker;

my $pkg = 'CSS::Simple';
my $module = 'lib/CSS/Simple.pm';

WriteMakefile1(
    NAME => $pkg,
    PMLIBDIRS => [ 'lib' ],
    PREREQ_PM => {
	'Carp' => 0,
        'Tie::IxHash' => 0
    },
    TEST_REQUIRES => {
      'Test::More' => 0,
    },
    'test' => {
	TESTS => join(' ', map { glob } qw( t/*.t t/*/*.t )),
    },
    VERSION_FROM => $module,
    AUTHOR => 'Kevin Kamel <kamelkev@mailermailer.com>',
    ABSTRACT => 'Interface through which to read/write/manipulate CSS files while respecting the cascade order',
    LICENSE => 'perl',
    META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'git://github.com/kamelkev/CSS-Simple.git',
          web => 'https://github.com/kamelkev/CSS-Simple',
        },
      },
    },
);

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
  my %params=@_;
  my $eumm_version=$ExtUtils::MakeMaker::VERSION;
  $eumm_version=eval $eumm_version;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  die "License not specified" if not exists $params{LICENSE};
  if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
    $params{META_ADD}->{author}=$params{AUTHOR};
    $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
  }
  if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
    $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
    delete $params{TEST_REQUIRES};
  }
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
    delete $params{BUILD_REQUIRES};
  }
  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;

  WriteMakefile(%params);
}

sub MY::postamble {
  package MY;

  my $postamble = "all :: README\n\nREADME: $module\n\tpod2text $module > README";

  return $postamble;
}
