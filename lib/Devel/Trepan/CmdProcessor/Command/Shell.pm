# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use feature ":5.10";  # Includes "state" feature.

## FIXME: figure out how to put in a spearate file.
package Devel::REPL::Plugin::TrepanShell;

use Devel::REPL::Plugin;
use namespace::clean -except => [ 'meta' ];

has 'history' => (
   isa => 'ArrayRef', is => 'rw', required => 1, lazy => 1,
   default => sub { [] }
);

around 'read' => sub {
   my $orig = shift;
   my ($self, @args) = @_;
   my $line = $self->$orig(@args);
   if (defined $line) {
      if ($line =~ m/^\.(.*)$/) {
         $Devel::REPL::Plugin::TrepanShell::DEBUGGER_COMMAND = $1;
	 return undef;
      }
   }
   return $line;
};

use rlib '../../../..';
package Devel::Trepan::CmdProcessor::Command::Shell;
use vars qw($DEBUGGER_COMMAND);
use Devel::Trepan::CmdProcessor::Command;
use English;
no strict;
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

	$repl->load_plugin('FancyPrompt');
	$repl->fancy_prompt(sub {
	    my $self = shift;
	    # sprintf 're.pl(%s):%03d%s> ',
	    #          $self->can('current_package')
            #                     ? $self->current_package : 'main',
	    #          $self->lines_read,
	    #          $self->can('line_depth') ? ':' . $self->line_depth : '';
	    "\ntrepan.pl>> "});
	
	$repl->load_plugin('LexEnv');         # 'my' variables should persist.
	$repl->load_plugin('MultiLine::PPI'); # for indent depth
	$repl->load_plugin('Packages');       # for current package
	$repl->load_plugin('TrepanShell');       # for current package
    }
    
    my $proc = $self->{proc};
    while (!$proc->{leave_cmd_loop}) {
	$DEBUGGER_COMMAND='';
	eval {
	    $repl->run;
	}; 
	if ($EVAL_ERROR) { 
	    $self->errmsg($EVAL_ERROR);
	}
	my $cmd = $Devel::REPL::Plugin::TrepanShell::DEBUGGER_COMMAND;
	if ($cmd) {
	    $proc->run_command($cmd);
	}
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc);
    $cmd->run([$NAME]);
}

1;
