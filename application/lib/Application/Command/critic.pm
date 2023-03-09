package Application::Command::critic;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw( getopt );

use English;
use Path::Tiny qw( path );
use Perl::Critic;

has description => 'Run perlcritic';
has usage       => sub { shift->extract_usage };

has files   => sub { shift->_build_files };
has profile => '.perlcriticrc';

has critic => sub { return Perl::Critic->new(-profile => shift->profile) };

sub _build_files {
    my $self = shift;

    my @files;
    path('.')->visit(
        sub {
            my $file = $_;
            if ($file->is_file && ($file =~ /\.(?:pl|pm|PL)\z/)) {
                push @files, $file->canonpath;
            }
        },
        {recurse => 1},
    );

    @files = sort @files;
    return \@files;
}

sub criticize {
    my ($self, @args) = @_;

    getopt(\@args, 'f|file=s' => \my @files, 'p|profile=s' => sub { $self->profile($_[1]) },);

    $self->files(\@files) if @files;

    my $success;
    foreach my $file (@{$self->files}) {
        $success = $self->_criticize_file($file);
    }

    exit 1 unless $success;
}

sub _criticize_file {
    my ($self, $file) = @_;

    my @violations = $self->critic->critique($file);

    if (@violations) {
        print "perlcritic has identified following problems in $file:\n" . ' ' x 4;

        local $OUTPUT_FIELD_SEPARATOR = ' ' x 4;
        say @violations;

        return 0;
    }

    return 1;
}

sub run { shift->criticize(@_) }

1;

=encoding utf8

=head1 NAME

=for stopwords perlriticrc

Application::Command::critic - Automatically re-format code according to declared in .perlriticrc

=head1 SYNOPSIS

    Usage: APPLICATION critic [OPTIONS]

        ./application.pl critic
        ./application.pl critic -f lib/Application/Controller/Example.pm -f lib/Application/Controller/AnotherExample.pm
        ./application.pl critic -p ./.alternativeprofilerc

    Options:
        -f, --file <path>       Specify files to be cleaned up, defaults to all *.pl, *.pm, *.PL and *.t files

        -p, --profile <path>    Specify path to alternative profile file, default to .perlcriticrc

        -h, --help              Show this summary of available options

        -v, --verbose           Will output more details during the run if set

        --check-only            Will check if any of the files requires a change

=head1 DESCRIPTION

L<Application::Command::critic> run Perl::critic against the code.

This is a command provided in the Development and Test builds.

=head1 ATTRIBUTES

L<Application::Command::critic> inherits all attributes from L<Mojolicious::Command> and implements the following new
ones.

=head2 description

    my $description = $critic->description;
    $critic         = $critic->description('Foo');

Short description of this command, used for the command list.

=head2 usage

    my $usage = $critic->usage;
    $critic   = $critic->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Application::Command::critic> inherits all methods from L<Mojolicious::Command> and implements the following new
ones.

=head2 criticize

    $critic->criticize(@ARGV);

critic files L<Application::Command::critic> with parameters from command line arguments.

=head2 run

    $critic->run(@ARGV);

Run this command.

=cut
