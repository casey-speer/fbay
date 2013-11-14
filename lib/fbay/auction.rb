module Fbay
  class Auction
    include MongoMapper::Document
    include Fbay::Utils::SetState

    key :state, Symbol, :in => [:in_progress, :success, :failed], :default => :in_progress
    key :completed_at, Date
    timestamps!

    belongs_to :item, :class_name => "Fbay::Item"
    many :bids, :class_name => "Fbay::Bid"

    after_create do
      item.mark_at_auction
    end

    def mark_in_progress
      set_state( :in_progress )
    end

    def in_progress?
      state == :in_progress
    end
    
    def mark_success
      set_state( :success )
    end

    def mark_failed
      set_state( :failed )
    end

    def high_bid
      bids.sort( :amount_in_cents ).last
    end

    def winning_bid
      if high_bid && high_bid.amount_in_cents >= item.reserve_price_in_cents 
        high_bid
      else
        nil
      end
    end

    def call
      return false unless in_progress?
      # sort bids to make this simpler
      if winning_bid
        mark_success
        item.mark_sold
      else
        mark_failed
        item.mark_available
      end
      completed_at = Time.now
      save
    end
  end
end
