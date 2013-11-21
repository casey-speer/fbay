# Fbay

Fbay: a simple auction manager ruby gem backed by mongodb

## Prereqs

Assumes MacOS

MongoDB:

`brew install mongo`

Bundler:

`gem install bundler`

## Installation

To install and test locally (outside of app context):

Clone the repo and then from within the gem directory,

`bundle install`

## Usage

To run the tests and verify requirements, from within the gem directory:

`bundle exec rspec spec/fbay_spec.rb`

To manually play with the gem through irb, from within gem directory:

`bundle console`

Add an Item:

`Fbay.add_item( item_name, reserve_price_in_cents )`

Add an auction participant:

`Fbay.add_participant( participant_name )`

Start an auction on an item:

`Fbay.start_auction( item_name )`

Call an auction by item name:

`Fbay.call_auction( item_name )`

Bid on an item:

`Fbay.bid( item_name, participant_name, amount_in_cents )`

Get item/auction status:

`Fbay.item_status( item_name )`
