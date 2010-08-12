# BEGIN BPS TAGGED BLOCK {{{
# 
# COPYRIGHT:
# 
# This software is Copyright (c) 1996-2010 Best Practical Solutions, LLC
#                                          <jesse@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
# 
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}

# This Action will open the BASE if a dependent is resolved.
package RT::Action::AutoOpen;

use strict;
use warnings;
use base qw(RT::Action);

=head1 DESCRIPTION

AutoOpen in RT 3.8 sets status of a ticket to 'open' without considering
custom statuses and possibility that there is no 'open' status in the system.
This extension overrides behavior of the action.

Status is not changed if there is no active statuses in the schema.

Status is not changed if the current status is first active for ticket's status
schema. For example if ticket's status is 'processing' and active statuses are
'processing', 'on hold' and 'waiting' then status is not changed, but for ticket
with status 'on hold' other rules are checked.

Status is not changed if it's initial and creator of the current transaction
is one of requestors.

Status is not changed if message's head has field C<RT-Control> with C<no-autoopen>
substring.

Status is set to the first possible active status. It means that if ticket's
status is X then RT finds all possible transitions from this status and selects
first active status in the list.

=cut

sub Prepare {
    my $self = shift;

    my $ticket = $self->TicketObj;
    my $schema = $ticket->QueueObj->status_schema;
    my $status = $ticket->Status;

    my @active = $schema->active;
    # no change if no active statuses in the schema
    return 1 unless @active;

    # no change if the ticket is already has first status from the list of active
    return 1 if lc $status eq lc $active[0];

    # no change if the ticket is in initial status and the message is a mail
    # from a requestor
    return 1 if $schema->is_initial($status) && $self->TransactionObj->IsInbound;

    if ( my $msg = $self->TransactionObj->Message->First ) {
        return 1 if ($msg->GetHeader('RT-Control') || '') =~ /\bno-autoopen\b/i;
    }

    my ($next) = grep $schema->is_active($_), $schema->transitions($status);

    $self->{'set_status_to'} = $next;

    return 1;
}

sub Commit {
    my $self = shift;

    return 1 unless my $new_status = $self->{'set_status_to'};

    my ($val, $msg) = $self->TicketObj->SetStatus( $new_status );
    unless ( $val ) {
        $RT::Logger->error( "Couldn't auto-open ticket: ". $msg );
        return 0;
    }
    return 1;
}

eval "require RT::Action::AutoOpen_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/AutoOpen_Vendor.pm});
eval "require RT::Action::AutoOpen_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Action/AutoOpen_Local.pm});

1;
