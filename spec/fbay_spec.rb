require 'spec_helper'

describe Fbay do
  # note let is lazy evaluated for each example
  let( :item ) { Fbay::Item.create( :name => "miley's secret diary", :reserve_price_in_cents => 10000000 ) } 

  it 'should have a version number' do
    Fbay::VERSION.should_not be_nil
  end

  it 'should add an item for auction' do
    Fbay.add_item( "finest twerking videos", 1000000 )
    Fbay::Item.count.should == 1
  end

  it 'should add a participant' do
    Fbay.add_participant( "walter white" )
    Fbay::Participant.count.should == 1
  end

  context( :running_auction ) do
    let( :participant ) { Fbay::Participant.create( :name => "walter white" ) }

    before do
      Fbay.start_auction( item.name )
    end

    it 'should start an auction on an item' do
      Fbay::Auction.count.should == 1
      expect( Fbay::Auction.first.state ).to eq( :in_progress )
      expect( item.reload.state ).to eq( :at_auction )
    end

    it 'should call an auction' do
      Fbay.call_auction( item.name )
      expect( Fbay::Auction.first.state ).not_to eq( :in_progress )
      expect( item.reload.state ).to eq( :available )
    end

    it "bids on an item" do
      Fbay.bid( item.name, participant.name, 1000 ) 
      expect( Fbay::Bid.count ).to eq( 1 )
      bid = Fbay::Bid.last
      expect( bid.auction ).to eq( item.active_auction )
      expect( bid.participant ).to eq( participant )
      expect( bid.amount_in_cents ).to eq( 1000 )
    end

    it 'should query item and return item status' do
      status = Fbay.item_status( item.name )
      expect( status[:last_auction][:status] ).to eq( :in_progress )
      expect( status[:sale] ).to eq( {} )
    end
  end

  context( :successful_auction ) do
    let( :participant ) { Fbay::Participant.create( :name => "walter white" ) }

    before do
      Fbay.start_auction( item.name )
      Fbay.add_participant( participant.name )
      Fbay.bid( item.name, participant.name, 1000000000 ) 
      Fbay.call_auction( item.name )
    end

    it 'disallows auctions on sold items' do
      Fbay.call_auction( item.name )
      Fbay.start_auction( item.name ).should be_false
      Fbay::Auction.count.should == 1
    end

    it 'should show updated status' do
      status = Fbay.item_status( item.name )
      expect( status[:last_auction][:status] ).to eq( :success )
      expect( status[:sale][:price_in_cents] ).to eq( 1000000000 )
      expect( status[:sale][:participant_name] ).to eq( participant.name )
    end
  end

  context( :failed_auction ) do
    let( :participant ) { Fbay::Participant.create( :name => "walter white" ) }

    before do
      Fbay.start_auction( item.name )
      Fbay.add_participant( participant.name )
      Fbay.bid( item.name, participant.name, 1000 ) 
      Fbay.call_auction( item.name )
    end

    it 'allows new auctions on an item' do
      Fbay.start_auction( item.name )
      Fbay::Auction.count.should == 2
    end

    it 'should show updated status' do
      status = Fbay.item_status( item.name )
      expect( status[:last_auction][:status] ).to eq( :failed )
      expect( status[:sale] ).to eq( {} )
    end
  end
end

describe Fbay::Item do
  let!( :item ) { Fbay::Item.create( :name => "miley's secret diary", :reserve_price_in_cents => 10000000 ) } 

  it 'validates name, reserve price, and state' do
    # validate presence of name, reserve_price_in_cents; ensure valid state
    bad_item = Fbay::Item.create( :name => "", :state => :disappeared ) 
    expect( bad_item.errors.keys ).to include( :name, :reserve_price_in_cents, :state )

    # validate name uniqueness
    bad_item_2 = Fbay::Item.create( :name => item.name, :reserve_price_in_cents => 10000000 )
    expect( bad_item_2.errors[:name] ).not_to be_nil 
  end

  it 'sets and queries state' do
    expect( item.state ).to eq( :available )

    item.mark_at_auction
    expect( item.state ).to eq( :at_auction )
    item.at_auction?.should be_true

    item.mark_sold
    expect( item.state ).to eq( :sold )

    item.mark_available
    expect( item.state ).to eq( :available )
    item.available?.should be_true
  end

  context( :with_auction ) do
    let!(:in_progress_auction) { Fbay::Auction.create( :item => item ) }
    let!( :participant ) { Fbay::Participant.create( :name => "walter white" ) }

    it 'returns auction info' do
      expect( item.active_auction ).to eq( in_progress_auction )
      expect( item.last_auction ).to eq( in_progress_auction )
      Fbay.bid( item.name, participant.name, 1000000000 ) 
      Fbay.call_auction( item.name )
      expect( item.winning_bid.amount_in_cents ).to eq( 1000000000 )
    end
  end
end

describe Fbay::Auction do
  let( :item ) { Fbay::Item.create( :name => "miley's secret diary", :reserve_price_in_cents => 10000000 ) } 
  let!( :auction ) { Fbay::Auction.create( :item => item ) } 

  it 'sets the item state on creation' do
    expect( auction.item.state ).to eq( :at_auction )
  end

  it 'validates state' do
    bad_auction = Fbay::Auction.create( :item => item, :state => :vanished ) 
    expect( bad_auction.errors.keys ).to include( :state )
  end

  it 'sets and queries state' do
    expect( auction.state ).to eq( :in_progress )

    auction.mark_success
    expect( auction.state ).to eq( :success )

    auction.mark_failed
    expect( auction.state ).to eq( :failed )

    auction.mark_in_progress
    expect( auction.state ).to eq( :in_progress )
    expect( auction.in_progress? ).to be_true
  end

  context( :with_successful_bid ) do
    let( :participant ) { Fbay::Participant.create( :name => "walter white" ) }
    before do
      Fbay.bid( item.name, participant.name, 1000000000 ) 
      auction.call
    end

    it "calls the auction and sets success" do
      expect( auction.state ).to eq( :success )
      expect( auction.item.state ).to eq( :sold )
    end

    it 'returns high and winning bid' do
      expect( auction.winning_bid.amount_in_cents ).to eq( 1000000000 ) 
      expect( auction.high_bid.amount_in_cents ).to eq( 1000000000 )
    end
  end

  context( :with_nonsuccessful_bid ) do
    let( :participant ) { Fbay::Participant.create( :name => "walter white" ) }
    before do
      Fbay.bid( item.name, participant.name, 1000 ) 
      auction.call
    end

    it "calls the auction and sets failed" do
      expect( auction.state ).to eq( :failed )
      expect( auction.item.state ).to eq( :available )
    end

    it 'returns high and winning bid' do
      expect( auction.winning_bid ).to be_nil
      expect( auction.high_bid.amount_in_cents ).to eq( 1000 )
    end
  end
end

describe Fbay::Bid do
  let( :item ) { Fbay::Item.create( :name => "miley's secret diary", :reserve_price_in_cents => 10000000 ) } 
  let( :auction ) { Fbay::Auction.create( :item => item ) } 
  let( :participant ) { Fbay::Participant.create( :name => "walter white" ) }

  it 'validates amount greater than 0' do
    bid = Fbay::Bid.create( :item => item, :auction => auction, :amount_in_cents => -1, :participant => participant )
    expect( bid.errors.keys ).to include( :amount_in_cents )
  end

  it "validates amount is greater than highest bid" do
    bid = Fbay::Bid.create( :item => item, :auction => auction, :amount_in_cents => 1000, :participant => participant )
    expect( bid.errors.size ).to eq( 0 )
    expect( Fbay::Bid.count ).to eq( 1 ) 

    bid_2 = Fbay::Bid.create( :item => item, :auction => auction, :amount_in_cents => 1000, :participant => participant )
    expect( bid_2.errors.keys ).to include( :amount_in_cents )
    expect( Fbay::Bid.count ).to eq( 1 ) 
  end
end

describe Fbay::Participant do
  let( :item ) { Fbay::Item.create( :name => "miley's secret diary", :reserve_price_in_cents => 10000000 ) } 
  let( :participant ) { Fbay::Participant.create( :name => "walter white" ) }
  let!( :auction ) { Fbay::Auction.create( :item => item ) } 

  it "can bid on an auction" do
    participant.bid_on( item, 10000000000 )
    expect( Fbay::Bid.count ).to eq( 1 )
  end
end
