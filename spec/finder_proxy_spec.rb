require 'spec_helper'

module Sandthorn
  describe FinderProxy do
    class FooAggregate
      include AggregateRoot
      def inc
        record_event
      end
    end

    let(:sequence_number) { 10 }

    let(:at_sequence_number) do
      FinderProxy.new(FooAggregate, sequence_number: sequence_number)
    end

    describe "#find" do
      context "when given a single id" do
        context "when given a sequence number" do
          it "calls aggregate_build_from on the aggregate type with the correct args" do
            expect(FooAggregate).to receive(:aggregate_build_to).with("foo", sequence_number: sequence_number)
            at_sequence_number.find("foo")
          end
        end
      end
      context "when given an aggregate that doesn't exist" do
        it "returns nil" do
          expect(at_sequence_number.find("foo")).to be_nil
        end
      end
    end

    describe "#find!" do
      context "when given an aggregate that doesn't exist" do
        it "raises an error" do
          expect { at_sequence_number.find!("foo") }.to raise_error(Errors::AggregateNotFound)
        end
      end
      context "when given multiple aggregates and at least one doesn't exist" do
        let!(:aggregate) do
          FooAggregate.new.save
        end
        it "raises an error" do
          expect { at_sequence_number.find!([aggregate.id, "foo"])}.to raise_error(Errors::AggregateNotFound)
        end
      end
    end

    describe "#all" do
      before do
        Timecop.freeze(1999, 1, 1)
        aggregates_tmp = []
        3.times do
          aggregate = FooAggregate.new
          3.times { aggregate.inc }
          aggregates_tmp << aggregate.save
        end
        @last_sequence_number = Sandthorn.get_aggregate_events(FooAggregate, aggregates_tmp.last.aggregate_id).last[:sequence_number]
      end
      it "returns all available aggregates at the given point" do
        aggregates = FinderProxy.new(FooAggregate, sequence_number: @last_sequence_number).all
        expect(aggregates.length).to eq(3)
      end

      context "when an aggregate has no events at that time" do
        let!(:newer_aggregate) do
          Timecop.freeze(Time.new(2015,1,1))
          FooAggregate.new.save
        end
        it "doesn't return that aggregate" do
          aggregates = FinderProxy.new(FooAggregate, sequence_number: 1).all
          aggregate_ids = aggregates.map(&:id)
          expect(aggregate_ids).to_not include newer_aggregate.id
        end
      end
    end
  end
end
