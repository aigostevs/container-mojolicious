package Application::Command::test;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';

use Path::Tiny qw( path );
use TAP::Harness;

has description => 'Run tests';
has usage       => sub { shift->extract_usage };

has files     => sub { shift->_build_files };
has libraries => sub { shift->_build_libraries };
has timer     => 0;
has verbosity => 0;

sub _build_files {
    my $self = shift;

    my @files;
    path('.')->visit(
        sub {
            my $file = $_;
            if ($file->is_file && ($file =~ /\.(?:t)\z/)) {
                push @files, $file->canonpath;
            }
        },
        {recurse => 1},
    );

    @files = sort @files;
    return \@files;
}

sub _build_libraries {
    my $self = shift;

    my @libraries = qw(lib);
    return \@libraries;
}

sub test {
    my ($self, @args) = @_;

    getopt(
        \@args,
        'f|file=s'    => \my @files,
        'l|library=s' => \my @libraries,

        't|timer'     => sub { $self->timer($_[1]) },
        'v|verbose=i' => sub { $self->verbosity($_[1]) },
    );

    $self->files(\@files)         if @files;
    $self->libraries(\@libraries) if @libraries;

    my $harness = TAP::Harness->new(
        {color => 1, lib => [@{$self->libraries}], timer => $self->timer, verbosity => $self->verbosity,});

    exit $harness->runtests(@{$self->files})->exit;
}

sub run { shift->test(@_) }

1;

=encoding utf8

=head1 NAME

Application::Command::test - Run tests

=head1 SYNOPSIS

    Usage: APPLICATION test [OPTIONS]

        ./application.pl test
        ./application.pl test -f application/t/Example.t -f application/t/AnotherExample.t
        ./application.pl test -l ./lib -l ../other_lib
        ./application.pl test -t
        ./application.pl test -v -1

    Options:
        -f, --file <path>       Specify tests to be ran, defaults to all *.t files
        -l, --library <path>    Specify libraries to be included in the run, defaults to ./lib

        -h, --help              Show this summary of available options

        -t, --timer             Measure tests execution time
        -v, --verbose           Specify verbosity level according to TAP::Harness->new( verbosity );

=head1 DESCRIPTION

L<Application::Command::test> run tests with TAP::Harness.

This is a command provided in the Development and Test builds.

=head1 ATTRIBUTES

L<Application::Command::test> inherits all attributes from L<Mojolicious::Command> and implements the following new
ones.

=head2 description

    my $description = $test->description;
    $test           = $test->description('Foo');

Short description of this command, used for the command list.

=head2 usage

    my $usage = $test->usage;
    $test     = $test->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Application::Command::test> inherits all methods from L<Mojolicious::Command> and implements the following new
ones.

=head2 test

    $test->test(@ARGV);

Run unit tests L<Application::Command::test> with parameters from command line arguments.

=head2 run

    $test->run(@ARGV);

Run this command.

=cut
