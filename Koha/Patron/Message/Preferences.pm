package Koha::Patron::Message::Preferences;

# Copyright Koha-Suomi Oy 2016
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use Koha::Database;
use Koha::Patron::Message::Preference;
use Koha::Patron::Message::Transports;

use base qw(Koha::Objects);

=head1 NAME

Koha::Patron::Message::Preferences - Koha Patron Message Preferences object class

=head1 API

=head2 Class Methods

=cut

=head3 get_options

my $messaging_options = Koha::Patron::Message::Preferences->get_options

Returns an ARRAYref of HASHrefs on available messaging options.

=cut

sub get_options {
    my ($self) = @_;

    my $transports = Koha::Patron::Message::Transports->search(undef,
        {
            join => ['message_attribute'],
            '+select' => ['message_attribute.message_name', 'message_attribute.takes_days'],
            '+as' => ['message_name', 'takes_days'],
        });

    my $choices;
    while (my $transport = $transports->next) {
        my $name = $transport->get_column('message_name');
        $choices->{$name}->{'message_attribute_id'} = $transport->message_attribute_id;
        $choices->{$name}->{'message_name'}         = $name;
        $choices->{$name}->{'takes_days'}           = $transport->get_column('takes_days');
        $choices->{$name}->{'has_digest'}           = 1 if $transport->is_digest;
        $choices->{$name}->{'transport_'.$transport->get_column('message_transport_type')} = ' ';
    }

    my @return = values %$choices;
    @return = sort { $a->{message_attribute_id} <=> $b->{message_attribute_id} } @return;

    return \@return;
}

=head3 type

=cut

sub _type {
    return 'BorrowerMessagePreference';
}

sub object_class {
    return 'Koha::Patron::Message::Preference';
}

=head1 AUTHOR

Lari Taskula <lari.taskula@jns.fi>

=cut

1;
