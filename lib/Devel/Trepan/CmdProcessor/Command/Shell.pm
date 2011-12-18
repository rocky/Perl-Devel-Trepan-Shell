# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use feature ":5.10";  # Includes "state" feature.

use Devel::Trepan::CmdProcessor::Command;
package Devel::Trepan::CmdProcessor::Command::Shell;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
unless (defined @ISA) {
    eval <<"EOE";
use constant ALIASES    => ('re.pl');
use constant CATEGORY   => 'support';
use constant SHORT_HELP => 'Run a shell via re.pl';
use constant NEED_STACK => 0;
use constant MIN_ARGS   => 0;  # Need at least this many
use constant MAX_ARGS   => 0;  # Need at most this many - undef -> unlimited.
EOE
}

use strict;
our @ISA = @CMD_ISA;  # value inherited from parent
use vars @CMD_VARS;   # value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} 

Run a command shell via Devel::REPL
HELP

# sub complete($$)
# {
#     my ($self, $prefix) = @_;
#     my @completions = sort ('.', DB::LineCache::file_list());
#     Devel::Trepan::Complete::complete_token(\@completions, $prefix);
# }

use Devel::REPL;
# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    state $repl;
    unless (defined($repl)) {
	$repl = Devel::REPL->new;
	$repl->load_plugin('MultiLine::PPI'); # for indent depth
	$repl->load_plugin('Packages');       # for current package
	$repl->load_plugin('FancyPrompt');
	$repl->fancy_prompt(sub {
	    my $self = shift;
	    # sprintf 're.pl(%s):%03d%s> ',
	    #          $self->can('current_package')
            #                     ? $self->current_package : 'main',
	    #          $self->lines_read,
	    #          $self->can('line_depth') ? ':' . $self->line_depth : '';
	    'trepan.pl>> '});
    }
    $repl->run;
}

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc);
    $cmd->run([$NAME]);
}

1;
