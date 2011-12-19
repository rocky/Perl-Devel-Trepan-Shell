#!/usr/bin/env perl
# Call trepan.pl with our shell command via the --cmddir option.
# Useful in testing without installing.

# The usual boilerplate...
use strict; use warnings; use English qw( -no_match_vars );

use File::Basename; use File::Spec;
use constant TREPAN_DIR => 
    File::Spec->catfile(dirname(__FILE__), 'lib', 'Devel', 'Trepan',
			'CmdProcessor', 'Command');
use rlib TREPAN_DIR;

my @ARGS = ('trepan.pl', '--cmddir', TREPAN_DIR, @ARGV);
if ($OSNAME eq 'MSWin32') {
    # I don't understand why but Strawberry Perl has trouble with exec.
    system @ARGS;
    exit $?;
} else {
    exec { $ARGS[0]} @ARGS;
}

