require 'spec_helper'

class AnAggregate
  include Sandthorn::AggregateRoot
  def touch; touched; end
  def touched; commit; end
end

describe Sandthorn do
  before(:each) {
    @aggregate = AnAggregate.new
    @aggregate.touch
    @aggregate.save
  }

  describe "::obsolete_snapshot" do
    it "retrieves a list of obsolete snapshots" do
      obsolete_aggregates = Sandthorn.obsolete_snapshots type_names: [AnAggregate], min_event_distance: 0
      expect(obsolete_aggregates).to_not be_empty
    end

    it "accepts a block that is applied to each aggregate" do
      obsolete_aggregates = Sandthorn.obsolete_snapshots type_names: [AnAggregate], min_event_distance: 0
      expect do |block|
        Sandthorn.obsolete_snapshots type_names: [AnAggregate], min_event_distance: 0, &block
      end.to yield_successive_args(*obsolete_aggregates)
    end

    it "only retrieves aggregates older than min_event_distance" do
      obsolete_aggregates = Sandthorn.obsolete_snapshots type_names: [AnAggregate], min_event_distance: 10
      expect(obsolete_aggregates).to be_empty
    end
  end
end
