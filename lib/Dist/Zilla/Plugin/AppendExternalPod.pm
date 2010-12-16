use strict;
use warnings;
package Dist::Zilla::Plugin::AppendExternalPod;
# ABSTRACT: No abstract given for Dist::Zilla::Plugin::AppendExternalPod

use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class qw(Dir File);
with(
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::FilePruner',
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ ':InstallModules', ':ExecFiles' ],
  },
);


use Path::Class;
use namespace::autoclean;

=attr pod_dir

This is the directory containing Pod to append.  The default is F<pod>.
Files within this directory that have the same relative names as
modules and executables will have their contents appended.  E.g.
F<pod/lib/Foo.pm> will be appended to F<lib/Foo.pm>

=cut

has pod_dir => (
  is   => 'ro',
  isa  => Dir,
  lazy => 1,
  coerce   => 1,
  required => 1,
  default  => sub { dir(shift->zilla->root, 'pod')->absolute->stringfy },
);

=attr prune_pod_dir

This is a boolean that indicates whether the C<pod_dir> should also be
pruned from the distribution.

=cut

has prune_pod_dir => (
  is   => 'ro',
  isa  => 'Bool',
  default  => 1,
);

sub prune_files {
  my ($self) = @_;

  return unless $self->prune_pod_dir;

  my $pod_dir = $self->pod_dir;

  for my $file ($self->zilla->files->flatten) {
    next unless $file =~ m{\A$pod_dir\/}; 
    $self->log_debug([ 'pruning %s', $file->name ]);
    $self->zilla->prune_file($file);
  }

  return;
}

sub munge_files {
  my ($self) = @_;

  my $pod_dir = $self->pod_dir;

  for my $file ( @{ $self->found_files } ) {
    my $pod_file = file($pod_dir, $file->name);
    next unless -e $pod_file;
    $self->munge_file($file, $pod_file);
  }
}

sub munge_file {
  my ($self, $file, $pod_file) = @_;
  $self->log_debug(
    [ 'appending Pod from %s to %s', $pod_file->stringify, $file->name ]
  );
  $file->content($file->content . "\n" . $pod_file->slurp(iomode => ':utf8'));
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=for Pod::Coverage method_names_here

=begin wikidoc

= SYNOPSIS

  [AppendExternalPod]
  pod_dir = pod       ; default
  prune_pod_dir = 1   ; default

= DESCRIPTION

This [Dist::Zilla] plugin appends files in a directory to files being
gathered for the distribution.

=end wikidoc

=cut

