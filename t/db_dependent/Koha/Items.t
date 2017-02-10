#!/usr/bin/perl

# Copyright 2016 Koha Development team
#
# This file is part of Koha
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use Test::More tests => 7;

use C4::Circulation;
use Koha::Item;
use Koha::Item::Transfer::Limits;
use Koha::Items;
use Koha::Database;

use t::lib::TestBuilder;
use t::lib::Mocks;

my $schema = Koha::Database->new->schema;
$schema->storage->txn_begin;

my $builder     = t::lib::TestBuilder->new;
my $biblioitem  = $builder->build( { source => 'Biblioitem' } );
my $library     = $builder->build( { source => 'Branch' } );
my $nb_of_items = Koha::Items->search->count;
my $new_item_1  = Koha::Item->new(
    {   biblionumber     => $biblioitem->{biblionumber},
        biblioitemnumber => $biblioitem->{biblioitemnumber},
        homebranch       => $library->{branchcode},
        holdingbranch    => $library->{branchcode},
        barcode          => "a_barcode_for_t",
    }
)->store;
my $new_item_2 = Koha::Item->new(
    {   biblionumber     => $biblioitem->{biblionumber},
        biblioitemnumber => $biblioitem->{biblioitemnumber},
        homebranch       => $library->{branchcode},
        holdingbranch    => $library->{branchcode},
        barcode          => "another_barcode_for_t",
    }
)->store;

like( $new_item_1->itemnumber, qr|^\d+$|, 'Adding a new item should have set the itemnumber' );
is( Koha::Items->search->count, $nb_of_items + 2, 'The 2 items should have been added' );

my $retrieved_item_1 = Koha::Items->find( $new_item_1->itemnumber );
is( $retrieved_item_1->barcode, $new_item_1->barcode, 'Find a item by id should return the correct item' );

subtest 'get_transfer' => sub {
    plan tests => 3;

    my $transfer = $new_item_1->get_transfer();
    is( $transfer, undef, 'Koha::Item->get_transfer should return undef if the item is not in transit' );

    my $library_to = $builder->build( { source => 'Branch' } );

    C4::Circulation::transferbook( $library_to->{branchcode}, $new_item_1->barcode );

    $transfer = $new_item_1->get_transfer();
    is( ref($transfer), 'Koha::Item::Transfer', 'Koha::Item->get_transfer should return a Koha::Item::Transfers object' );

    is( $transfer->itemnumber, $new_item_1->itemnumber, 'Koha::Item->get_transfer should return a valid Koha::Item::Transfers object' );
};

subtest 'biblio' => sub {
    plan tests => 2;

    my $biblio = $retrieved_item_1->biblio;
    is( ref( $biblio ), 'Koha::Biblio', 'Koha::Item->bilio should return a Koha::Biblio' );
    is( $biblio->biblionumber, $retrieved_item_1->biblionumber, 'Koha::Item->biblio should return the correct biblio' );
};

subtest 'can_be_transferred' => sub {
    plan tests => 8;

    t::lib::Mocks::mock_preference('UseBranchTransferLimits', 1);
    t::lib::Mocks::mock_preference('BranchTransferLimitsType', 'itemtype');

    my $library1 = $builder->build( { source => 'Branch' } )->{branchcode};
    my $library2 = $builder->build( { source => 'Branch' } )->{branchcode};
    my $item  = Koha::Item->new({
        biblionumber     => $biblioitem->{biblionumber},
        biblioitemnumber => $biblioitem->{biblioitemnumber},
        homebranch       => $library1,
        holdingbranch    => $library1,
        itype            => 'test',
        barcode          => "newbarcode",
    })->store;
    $nb_of_items++;

    is(Koha::Item::Transfer::Limits->search({
        fromBranch => $library1,
        toBranch => $library2,
    })->count, 0, 'There are no transfer limits between libraries.');
    ok($item->can_be_transferred({ to => $library2 }),
       'Item can be transferred between libraries.');

    my $limit = Koha::Item::Transfer::Limit->new({
        fromBranch => $library1,
        toBranch => $library2,
        itemtype => $item->effective_itemtype,
    })->store;
    is(Koha::Item::Transfer::Limits->search({
        fromBranch => $library1,
        toBranch => $library2,
    })->count, 1, 'Given we have added a transfer limit,');
    is($item->can_be_transferred({ to => $library2 }), 0,
       'Item can no longer be transferred between libraries.');
    is($item->can_be_transferred({ to => $library2, $library1 }), 0,
       'We get the same result also if we pass the from-library parameter.');
    eval { $item->can_be_transferred({ to => undef }); };
    is(ref($@), 'Koha::Exceptions::Library::BranchcodeNotFound', 'Exception thrown when no library given.');
    eval { $item->can_be_transferred({ to => 'heaven' }); };
    is(ref($@), 'Koha::Exceptions::Library::BranchcodeNotFound', 'Exception thrown when invalid library is given.');
    eval { $item->can_be_transferred({ to => $library2, from => 'hell' }); };
    is(ref($@), 'Koha::Exceptions::Library::BranchcodeNotFound', 'Exception thrown when invalid library is given.');
};

$retrieved_item_1->delete;
is( Koha::Items->search->count, $nb_of_items + 1, 'Delete should have deleted the item' );

$schema->storage->txn_rollback;

1;
