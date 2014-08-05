require 'spec_helper'

class AnAggregate
  include Sandthorn::AggregateRoot
  attr_accessor :test_block_count
  def initialize
    @test_block_count = false
  end
  def touch; touched; end
  def touched; commit; end
end

describe Sandthorn do
  before(:each) {
    @aggregate = AnAggregate.new
    @aggregate.touch
    @aggregate.save
  }

  context "when doing snapshots" do
    it "retrieves a list of obsolete snapshots" do
      obsolete_aggregates = Sandthorn.obsolete_snapshots type_names: [AnAggregate], min_event_distance: 0
      expect(obsolete_aggregates).to_not be_empty
    end

    it "accepts a block that is applied to each aggregate" do
      obsolete_aggregates = []
      Sandthorn.obsolete_snapshots type_names: [AnAggregate], min_event_distance: 0 do |aggr|
        aggr.test_block_count = true
        obsolete_aggregates << aggr
      end
      ap obsolete_aggregates.all? { |aggregate| aggregate.test_block_count == true }
      expect(obsolete_aggregates.all? { |aggregate| aggregate.test_block_count == true }).to be_truthy
    end

    it "only retrieves aggregates older than min_event_distance" do
      obsolete_aggregates = Sandthorn.obsolete_snapshots type_names: [AnAggregate], min_event_distance: 10
      expect(obsolete_aggregates).to be_empty
    end
  end
end
