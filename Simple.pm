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
    my $selector = $1;
    my $props = $2;

    $selector =~ s/\s{2,}/ /g;

    if (!defined($self->_get_ordered()->FETCH($selector))) {
      $self->_get_ordered()->STORE($selector, {});
    }

    # Split into properties
    my $properties = {};
    foreach ( grep { /\S/ } split /\;/, $props ) {
      unless ( /^\s*([\w._-]+)\s*:\s*(.*?)\s*$/ ) {
        croak "Invalid or unexpected property '$_' in style '$selector'";
      }

      #store the property for later
      $$properties{lc $1} = $2;
    }
    
    #store the properties within this selector
    $self->_get_ordered()->STORE($selector,$properties);
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

=cut

sub write {
  my ($self,$params) = @_;

  $self->_check_object();

  my $contents = '';

  foreach my $selector ( $self->_get_ordered()->Keys ) {

    #grab the properties that make up this particular selector
    my $properties = $self->_get_ordered()->FETCH($selector);

    $contents .= "$selector {\n";
    foreach my $property ( sort keys %{ $properties } ) {
      $contents .= "\t" . lc($property) . ": ".$properties->{$property}. ";\n";
    }
    $contents .= "}\n";
  }

  return $contents;
}

####################################################################
#                                                                  #
# The following are all get/set methods for manipulating the       #
# stored stylesheet                                                #
#                                                                  #
# Provides a nicer interface than dealing with TIE                 #
#                                                                  #
####################################################################

=pod

=item get_styles( params )

Get a hash that represents the various properties for this particular selector

This method requires you to pass in a params hash that contains scalar
css data. For example:

$self->get_styles({selector => '.foo'});

=cut

sub get_styles {
  my ($self,$params) = @_;

  $self->_check_object();

  return($self->_get_ordered()->FETCH($$params{selector}));
}

=pod

=item check_selector( params )

Determine if a selector exists within the stored rulesets

This method requires you to pass in a params hash that contains scalar
css data. For example:

$self->check_selector({selector => '.foo'});

=cut

sub check_selector {
  my ($self,$params) = @_;

  $self->_check_object();

  return($self->_get_ordered()->EXISTS($$params{selector}));
}

=pod

=item add_selector( params )

Add a selector and associated properties to the stored rulesets

In the event that this particular ruleset already exists, invoking this method will
simply replace the item. This is important - if you are modifying an existing rule 
using this method than the previously existing selectivity will continue to persist.
Delete the selector first if you want to ignore the previous selectivity.

This method requires you to pass in a params hash that contains scalar
css data. For example:

$self->add_selector({selector => '.foo', properties => {color => 'red' }});

=cut

sub add_selector {
  my ($self,$params) = @_;

  $self->_check_object();

  #if we existed already, invoke REPLACE to preserve selectivity
  if ($self->check_selector({selector => $$params{selector}})) {
    my ($index) = $self->_get_ordered()->Indices( $$params{selector} );
    $self->_get_ordered()->REPLACE($index,$$params{selector},$$params{properties});
  }
  #new element, stick it onto the end of the rulesets
  else {
    #store the properties, potentially overwriting properties that were there
    $self->_get_ordered()->STORE($$params{selector},$$params{properties});
  }

  return();
}

=pod

=item add_properties( params )

Add properties to an existing selector.

In the event that this method is invoked with a selector that doesn't exist then the call
is just translated to an add_selector call, thus creating the rule at the end of the ruleset.

This method requires you to pass in a params hash that contains scalar
css data. For example:

$self->add_selector({selector => '.foo', properties => {color => 'red' }});

=cut

sub add_properties {
  my ($self,$params) = @_;

  $self->_check_object();

  if ($self->check_selector({selector => $$params{selector}})) {
    my $styles = $self->get_selector({selector => $$params{selector}});

    #merge the passed styles into the previously existing styles for this selector
    my $properties = $$params{properties};
    foreach my $property (keys %{$properties}) {
      $$styles{$property} = $$properties{$property};
    }

    #overwrite the existing properties for this selector with the new hybrid style
    $self->add_selector({selector => $$params{selector}, properties => $styles});
  }
  else {
    $self->add_selector({selector => $$params{selector}, properties => $$params{properties}});
  }

  return();
}

=pod

=item delete_selector( params )

Delete a selector from the ruleset

This method requires you to pass in a params hash that contains scalar
css data. For example:

$self->delete_selector({selector => '.foo' });

=cut

sub delete_selector {
  my ($self,$params) = @_;

  $self->_check_object();

  #store the properties, potentially overwriting properties that were there
  $self->_get_ordered()->DELETE($$params{selector});

  return();
}

=pod

=item delete_property( params )

Delete a property from a specific selectors rules

This method requires you to pass in a params hash that contains scalar
css data. For example:

$self->delete_property({selector => '.foo', property => 'color' });

=back

=cut

sub delete_property {
  my ($self,$params) = @_;

  $self->_check_object();

  #get the properties so we can remove the requested property from the hash
  my $styles = $self->get_styles({selector => $$params{selector}});

  delete $$styles{$$params{property}};

  $self->add_selector({selector => $$params{selector}, properties => $styles});

  return();
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

