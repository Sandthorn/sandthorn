require "spec_helper"

class AnAggregate
  include Sandthorn::AggregateRoot
  def touch
    touched
  end
  def touched
    commit
  end
end

module Outer
  module Inner
    class OtherAggregate < AnAggregate; end
  end
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

    context "when the aggregate has been declared in a module" do
      before do
        Outer::Inner::OtherAggregate.new.tap do |agg|
          agg.touch
          agg.save
        end
      end

      it "doesn't crash" do
        obsolete_aggregates = Sandthorn.obsolete_snapshots type_names: [Outer::Inner::OtherAggregate], min_event_distance: 0
        expect(obsolete_aggregates).to all(be_a_kind_of(Outer::Inner::OtherAggregate))
      end
    end
  end

  describe "::save_snapshot" do
    context "when a keyword is missing" do
      it "raises an ArgumentError" do
        expect { Sandthorn.save_snapshot }.to raise_error(ArgumentError)
      end
    end
  end
end
