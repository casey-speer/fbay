module Fbay
  class Bid
    include MongoMapper::Document

    key :amount_in_cents, Integer
    timestamps!

    belongs_to :auction, :class_name => "Fbay::Auction"
    belongs_to :item, :class_name => "Fbay::Item"
    belongs_to :participant, :class_name => "Fbay::Participant"

    validates_numericality_of :amount_in_cents, :greater_than => 0
    validate :valid_amount

    def valid_amount
      if auction.high_bid && amount_in_cents <= auction.high_bid.amount_in_cents
        errors.add( :amount_in_cents, "amount must be greater than the highest bid" )
      end
    end
  end
end
