# BEGIN LICENSE BLOCK
# 
# Copyright (c) 1996-2002 Jesse Vincent <jesse@bestpractical.com>
# 
# (Except where explictly superceded by other copyright notices)
# 
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# 
# Unless otherwise specified, all modifications, corrections or
# extensions to this work which alter its source code become the
# property of Best Practical Solutions, LLC when submitted for
# inclusion in the work.
# 
# 
# END LICENSE BLOCK
package RT::Interface::Email::Auth::MailFrom;
use RT::Interface::Email qw(ParseSenderAddressFromHead CreateUser);

# This is what the ordinary, non-enhanced gateway does at the moment.

sub GetCurrentUser {
    my ($Item, $CurrentUser, $PrivStat) = @_;

    # We don't need to do any external lookups
    my ($Address, $Name) = ParseSenderAddressFromHead($Item->head);
    my $CurrentUser = RT::CurrentUser->new();
    $CurrentUser->LoadByEmail($Address);

    unless ($CurrentUser->Id) {
        $CurrentUser->LoadByName($Address);
    }

    # If still no joy, better make one
    unless ($CurrentUser->Id) {
        $CurrentUser = CreateUser(undef, $Address, $Name, $Item);
    }
    
    return ($CurrentUser, 1);
}

1;
