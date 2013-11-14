# Top-level module with auction controls and convenience methods
# for common actions

module Fbay
  def self.add_item( name, reserve )
    Item.create( :name => name, :reserve_price_in_cents => reserve )
  end

  def self.add_participant( name )
    Participant.create( :name => name )
  end

  def self.start_auction( item_name )
    item = Item.find_by_name( item_name )
    return false unless item && item.available?
    Auction.create( :item => item )
  end

  def self.call_auction( item_name )
    item = Item.find_by_name( item_name )
    return false unless item && item.at_auction?
    item.active_auction.call
  end

  def self.bid( item_name, participant_name, amount_in_cents )
    participant = Participant.find_by_name( participant_name )
    item = Item.find_by_name( item_name )
    return false unless item && participant && item.at_auction?
    participant.bid_on( item, amount_in_cents )
  end

  def self.item_status( item_name )
    item = Item.find_by_name( item_name )
    return false unless item
    status = {}

    if item.last_auction
      status[:last_auction] = { :status => item.last_auction.state }
    else
      status[:last_auction] = {}
    end

    winning_bid = item.winning_bid
    if winning_bid
      status[:sale] = { 
        :price_in_cents => winning_bid.amount_in_cents,
        :participant_name => winning_bid.participant.name
      }
    else
      status[:sale] = {}
    end

    status
  end
end
