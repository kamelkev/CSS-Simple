# $Id: Inliner.pm 2669 2010-08-19 22:17:42Z kamelkev $
#
# Copyright 2009 MailerMailer, LLC - http://www.mailermailer.com
#
# Based in large part on the CSS::Tiny CPAN Module
# http://search.cpan.org/~adamk/CSS-Tiny/

package CSS::Simple;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 2669 $ =~ /(\d+)/;

use Carp;
use Tie::IxHash;

=pod

=head1 NAME

CSS::Simple - Interface through which to read/write/manipulate CSS files while respecting the cascade order

=head1 SYNOPSIS

 use CSS::Simple;

 my $css = new CSS::Simple();

 $css->read({ filename => 'input.css' });

 #perform manipulations...

 $css->write({ filename => 'output.css' });

=head1 DESCRIPTION

Class for reading, manipulating and writing CSS. Unlike other CSS classes on CPAN this particular module
focuses on respecting the cascade order while providing a common sense API through which to manipulate the
parsed rules.

=head1 CONSTRUCTOR

=over 4

=item new ([ OPTIONS ])

Instantiates the CSS::Simple object. Sets up class variables that are used during file parsing/processing.

=back
=cut

sub new {
  my ($proto, $params) = @_;

  my $class = ref($proto) || $proto;

  my $css = {};

  my $self = {
              stylesheet => undef,
              css => $css,
              ordered => tie(%{$css}, 'Tie::IxHash')
             };

  bless $self, $class;
  return $self;
}

=head1 METHODS

=cut

=pod

=over 4

=item read_file( params )

Opens and reads a CSS file, then subsequently performs the parsing of the CSS file
necessary for later manipulation.

This method requires you to pass in a params hash that contains a
filename argument. For example:

$self->read_file({filename => 'myfile.css'});

=cut

sub read_file {
  my ($self,$params) = @_;

  $self->_check_object();

  unless ($params && $$params{filename}) {
    croak "You must pass in hash params that contain a filename argument";
  }

  open FILE, "<", $$params{filename} or die $!;
  my $css = do { local( $/ ) ; <FILE> } ;

  $self->read({css => $css});

  return();
}

=pod

=item read( params )

Reads css data and parses it. The intermediate data is stored in class variables.

This method requires you to pass in a params hash that contains scalar
css data. For example:

$self->read({css => $css});

=cut

sub read {
  my ($self,$params) = @_;

  $self->_check_object();

  unless ($params && $$params{css}) {
    croak "You must pass in hash params that contains the css data";
  }

  # Flatten whitespace and remove /* comment */ style comments
  my $string = $$params{css};
  $string =~ tr/\n\t/  /;
  $string =~ s!/\*.*?\*\/!!g;

  # Split into styles
  foreach ( grep { /\S/ } split /(?<=\})/, $string ) {

    unless ( /^\s*([^{]+?)\s*\{(.*)\}\s*$/ ) {
      croak "Invalid or unexpected style data '$_'";
    }

    # Split in such a way as to support grouped styles
    my $style = $1;
    my $props = $2;

    $style =~ s/\s{2,}/ /g;
    my @styles = grep { s/\s+/ /g; 1; } grep { /\S/ } split /\s*,\s*/, $style;

    foreach ( @styles ) {
      $self->_get_css()->{$_} ||= {}
    }

    # Split into properties
    foreach ( grep { /\S/ } split /\;/, $props ) {
      unless ( /^\s*([\w._-]+)\s*:\s*(.*?)\s*$/ ) {
        croak "Invalid or unexpected property '$_' in style '$style'";
      }

      foreach ( @styles ) {
        $self->_get_css->{$_}->{lc $1} = $2;
      }
    }
  }

  return();
}

=pod

=item write_file()

Write the parsed and manipulated CSS out to a file parameter

This method requires you to pass in a params hash that contains a
filename argument. For example:

$self->write_file({filename => 'myfile.css'});

=cut

sub write_file {
  my ($self,$params) = @_;

  $self->_check_object();

  unless (exists $$params{filename}) {
    croak "No filename specified for write operation";
  }

  # Write the file
  open( CSS, '>'. $$params{filename} ) or croak "Failed to open file '$$params{filename}' for writing: $!";
  print CSS $self->write();
  close( CSS );

  return();
}

=pod

=item write()

Write the parsed and manipulated CSS out to a scalar and return it

=back

=cut

sub write {
  my ($self,$params) = @_;

  $self->_check_object();

  my $contents = '';

  foreach my $style ( $self->_get_ordered()->Keys ) {
    $contents .= "$style {\n";
    foreach ( sort keys %{ $self->{$style} } ) {
      $contents .= "\t" . lc($_) . ": $self->_get_ordered()->{$style}->{$_};\n";
    }
    $contents .= "}\n";
  }

  return $contents;
}


####################################################################
#                                                                  #
# The following are all private methods and are not for normal use #
# I am working to finalize the get/set methods to make them public #
#                                                                  #
####################################################################

sub _check_object {
  my ($self,$params) = @_;

  unless ($self && ref $self) {
    croak "You must instantiate this class in order to properly use it";
  }

  return();
}

sub _get_css {
  my ($self,$params) = @_;

  $self->_check_object();

  return($self->{css});
}

sub _get_ordered {
  my ($self,$params) = @_;

  $self->_check_object();

  return($self->{ordered});
}

1;

=pod

=head1 Sponsor

This code has been developed under sponsorship of MailerMailer LLC, http://www.mailermailer.com/

=head1 AUTHOR

Kevin Kamel <C<kamelkev@mailermailer.com>>

=head1 ATTRIBUTION

This module is directly based off of Adam Kennedy's <adamk@cpan.org> CSS::Tiny module.

This particular version differs in terms of interface and the ultimate ordering of the CSS.

=head1 LICENSE

This module is a derived version of Adam Kennedy's CSS::Tiny Module.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut
