module Fbay
  class Participant
    include MongoMapper::Document

    key :name, String

    many :bids, :class_name => "Fbay::Bid"

    def bid_on( item, amount_in_cents )
      return false unless item.at_auction?
      Bid.create( :item => item, :auction => item.active_auction, :amount_in_cents => amount_in_cents, :participant => self )
    end
  end
end
