use strict;
use warnings;

package Config::Role;
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Moose config attribute loaded from config file

use File::HomeDir;
use Path::Class::Dir;
use Config::Any;
use MooseX::Types::Path::Class;

=method config_filename

Required method on the composing class. Should return a string with the name
of the configuration file name.

=cut

requires 'config_filename';

=attr config_file

The filename the configuration is read from. A Path::Class::File object.
Allows coercion from Str.

=cut

has 'config_file' => (
    is         => 'ro',
    isa        => 'Path::Class::File',
    coerce     => 1,
    lazy_build => 1,
);

sub _build_config_file {
    my ($self) = @_;
    my $home = File::HomeDir->my_data;
    my $conf_file = Path::Class::Dir->new($home)->file(
        $self->config_filename
    );
    return $conf_file;
}

=attr config_files

The collection of filenames the configuration is read from. Array reference
of L<Path::Class::File> objects.  Allows coercion from Str.

=cut

has 'config_files' => (
    is         => 'ro',
    isa        => 'ArrayRef[Path::Class::File]',
    coerce     => 1,
    lazy_build => 1,
);
sub _build_config_files {
    my ($self) = @_;
    return [ $self->config_file ];
}

=attr config

A hash reference that holds the compiled configuration read from the
specified files.

=cut

has 'config' => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_config {
    my ($self) = @_;
    my $cfg = Config::Any->load_files({
        use_ext => 1,
        files   => $self->config_files,
    });
    foreach my $config_entry ( @{ $cfg } ) {
        my ($filename, $config) = %{ $config_entry };
        return $config;
    }
    return {};
}

1;

__END__

=head1 SYNOPSIS

    package My::Class;
    use Moose;

    # Read configuration from ~/.my_class.ini, available in $self->config
    has 'config_filename' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
    sub _build_config_filename { '.my_class.ini' }
    with 'Config::Role';

    # Fetch a value from the configuration, allow constructor override
    has 'username' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
    sub _build_api_key { return (shift)->config->{'username'}; }

    sub make_request {
        my ($self) = @_;
        my $response = My::Class::Request->make(
            username => $self->username,
            ...
        );
        ...
    }


=head1 DESCRIPTION

Config::Role is a very basic role you can add to your Moose class that
allows it to take configuration data from a file located in your home
directory instead of always requiring parameters to be specified in the
constructor.

The synopsis shows how you can read the value of C<username> from the file
C<.my_class.ini> located in the home directory of the current user.  The
location of the file is determined by whatever C<< File::HomeDir->my_data >>
returns for your particular platform.

The config file is loaded by using L<Config::Any>'s C<load_files()> method.
It will load the files specified in the C<config_files> attribute.  By default
this is an array reference that contains the absolute filename from the
C<config_file> attribute.

The C<<Config::Any->load_files()>> flag C<use_ext> is set to a true value, so you
can use any configuration file format supported by L<Config::Any> by just
specifying the common filename extension for the format.


=head1 SEMANTIC VERSIONING

This module uses semantic versioning concepts from L<http://semver.org/>.


=head1 SEE ALSO

=for :list
* L<Moose>
* L<File::HomeDir>
* L<Config::Any>
* L<Path::Class::File>
