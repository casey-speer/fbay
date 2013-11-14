module Fbay
  class Item
    include MongoMapper::Document
    include Utils::SetState

    key :name, String, :required => true, :unique => true
    key :reserve_price_in_cents,  Integer, :required => true
    key :state, Symbol, :in => [:available, :at_auction, :sold], :default => :available

    validates_numericality_of :reserve_price_in_cents, :greater_than => 0

    many :auctions, :class_name => "Fbay::Auction"
    many :bids, :class_name => "Fbay::Bid"

    def mark_available
      set_state( :available )
    end
    
    def mark_at_auction
      set_state( :at_auction )
    end

    def mark_sold
      set_state( :sold )
    end

    def available?
      state == :available
    end

    def at_auction?
      state == :at_auction
    end

    def active_auction
      auctions.first( :state => :in_progress )
    end

    def last_auction
      auctions.sort( :created_at ).last
    end

    def winning_bid
      return nil unless last_auction
      last_auction.winning_bid
    end
  end
end
