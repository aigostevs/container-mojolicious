package Application::Command::tidy;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw( getopt );

use autodie;

use Path::Tiny qw( path );
use Perl::Tidy;

has description => 'Run perltidy';
has usage       => sub { shift->extract_usage };

has files      => sub { shift->_build_files };
has profile    => '.perltidyrc';
has check_only => 0;

sub _build_files {
    my $self = shift;

    my @files;
    path('.')->visit(
        sub {
            my $file = $_;
            if ($file->is_file && ($file =~ /\.(?:pl|pm|PL|t)\z/)) {
                push @files, $file->canonpath;
            }
        },
        {recurse => 1},
    );

    @files = sort @files;
    return \@files;
}

sub _load_file {
    my ($self, $filename) = @_;

    return unless -f $filename;

    my $content = path($filename)->slurp_utf8;
    return $content;
}

sub tidy {
    my ($self, @args) = @_;

    getopt(
        \@args,
        'f|file=s'    => \my @files,
        'p|profile=s' => sub { $self->profile($_[1]) },

        'check-only' => sub { $self->check_only($_[1]) },
    );

    $self->files(\@files) if @files;

    my $success;
    foreach my $file (@{$self->files}) {
        $success = $self->_tidy_file($file);
    }

    # In case we are running with --check-only
    exit 1 unless $success;
}

sub _tidy_file {
    my ($self, $file) = @_;

    my $original = $self->_load_file($file);
    my $tidy     = '';

    my $stderr = '';

    Perl::Tidy::perltidy(
        source      => \$original,
        destination => \$tidy,
        stderr      => \$stderr,
        perltidyrc  => $self->profile,
        argv        => '',
    );

    if ($stderr) {
        say "perltidy encountered following problem(s) while processing $file";
        say $stderr;
        exit 1;
    }

    unless ($original eq $tidy) {
        if ($self->check_only) {
            say "File $file violates current policies";
            return 0;
        }

        my $fh = path($file)->filehandle('>');
        print {$fh} $tidy;
        close($fh);

        say "File $file was tidied";
    }

    return 1;
}

sub run { shift->tidy(@_) }

1;

=encoding utf8

=head1 NAME

=for stopwords perltidyrc

Application::Command::tidy - Automatically re-format code according to declared in .perltidyrc

=head1 SYNOPSIS

    Usage: APPLICATION tidy [OPTIONS]

        ./application.pl tidy
        ./application.pl tidy -f lib/Application/Controller/Example.pm -f lib/Application/Controller/AnotherExample.pm
        ./application.pl tidy -p ./.alternativeprofilerc
        ./application.pl tidy --check-only

    Options:
        -f, --file <path>       Specify files to be cleaned up, defaults to all *.pl, *.pm, *.PL and *.t files

        -p, --profile <path>    Specify path to alternative profile file, default to .perltidyrc

        -h, --help              Show this summary of available options

        --check-only            Will check if any of the files requires a change

=head1 DESCRIPTION

L<Application::Command::tidy> run Perl::Tidy against the code.

This is a command provided in the Development and Test builds.

=head1 ATTRIBUTES

L<Application::Command::tidy> inherits all attributes from L<Mojolicious::Command> and implements the following new
ones.

=head2 description

    my $description = $tidy->description;
    $tidy           = $tidy->description('Foo');

Short description of this command, used for the command list.

=head2 usage

    my $usage = $tidy->usage;
    $tidy     = $tidy->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Application::Command::tidy> inherits all methods from L<Mojolicious::Command> and implements the following new
ones.

=head2 tidy

    $tidy->tidy(@ARGV);

Tidy files L<Application::Command::tidy> with parameters from command line arguments.

=head2 run

    $tidy->run(@ARGV);

Run this command.

=cut
