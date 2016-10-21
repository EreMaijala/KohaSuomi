#!/usr/bin/env perl

# Copyright 2016 Koha-Suomi Oy
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

use Test::More tests => 9;
use Test::Mojo;
use Test::MockModule;
use t::lib::TestBuilder;

use C4::Auth;
use C4::Context;

use Koha::Database;
use Koha::Patron;

my $mock = Test::MockModule->new('Koha::REST::V1::Patron');
$mock->mock(get => sub {
    my ($c, $args, $cb) = @_;

    # return 404 because it has a generic response schema that is unlikely to change
    return $c->$cb({ error => "is_owner_access" }, 404) if $c->stash('is_owner_access');
    return $c->$cb({ error => "is_guarantor_access" }, 404) if $c->stash('is_guarantor_access');
    return $c->$cb({ error => "librarian_access" }, 404);
});
my $builder = t::lib::TestBuilder->new();

my $dbh = C4::Context->dbh;
$dbh->{AutoCommit} = 0;
$dbh->{RaiseError} = 1;

$ENV{REMOTE_ADDR} = '127.0.0.1';
my $t = Test::Mojo->new('Koha::REST::V1');

my $categorycode = $builder->build({ source => 'Category' })->{ categorycode };
my $branchcode = $builder->build({ source => 'Branch' })->{ branchcode };
my $guarantor = $builder->build({
    source => 'Borrower',
    value => {
        branchcode   => $branchcode,
        categorycode => $categorycode,
        flags        => 0,
    }
});
my $borrower = $builder->build({
    source => 'Borrower',
    value => {
        branchcode   => $branchcode,
        categorycode => $categorycode,
        flags        => 0,
        guarantorid    => $guarantor->{borrowernumber},
    }
});
my $librarian = $builder->build({
    source => 'Borrower',
    value => {
        branchcode   => $branchcode,
        categorycode => $categorycode,
        flags        => 16,
    }
});

my $session = create_session($borrower);
my $session2 = create_session($guarantor);
my $lib_session = create_session($librarian);

# User without permissions, but is the owner of the object
my $tx = $t->ua->build_tx(GET => "/api/v1/patrons/" . $borrower->{borrowernumber});
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$t->request_ok($tx)
  ->status_is(404)
  ->json_is('/error', 'is_owner_access');

# User without permissions, but is the guarantor of the owner of the object
$tx = $t->ua->build_tx(GET => "/api/v1/patrons/" . $borrower->{borrowernumber});
$tx->req->cookies({name => 'CGISESSID', value => $session2->id});
$t->request_ok($tx)
  ->status_is(404)
  ->json_is('/error', 'is_guarantor_access');

# User with permissions
$tx = $t->ua->build_tx(GET => "/api/v1/patrons/" . $librarian->{borrowernumber});
$tx->req->cookies({name => 'CGISESSID', value => $lib_session->id});
$t->request_ok($tx)
  ->status_is(404)
  ->json_is('/error', 'librarian_access');

$dbh->rollback;

sub create_session {
    my ($patron) = @_;

    my $session = C4::Auth::get_session('');
    $session->param('number', $patron->{ borrowernumber });
    $session->param('id', $patron->{ userid });
    $session->param('ip', '127.0.0.1');
    $session->param('lasttime', time());
    $session->flush;

    return $session;
}
