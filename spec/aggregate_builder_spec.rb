require "spec_helper"

class AnAggregate 
  include Sandthorn::AggregateRoot

  attr_reader :name

  def initialize
    @name = nil
  end

  def foo new_name
    @name = new_name
    record_event new_name
  end
end

module Sandthorn
  describe AggregateBuilder do
    before do
      @aggregate = AnAggregate.new.save
    end
    let(:builder) { AggregateBuilder.new AnAggregate }
    let(:build) { builder.build(@aggregate.id) }

    it "should return the aggregate" do
      expect(build.id).to eql @aggregate.id
    end

    it "should have correct aggregate_version" do
      expect(build.aggregate_current_event_version).to eql @aggregate.aggregate_current_event_version
    end

    context "build from sequence_number" do
      before(:each) do
        @agg = AnAggregate.new.save
        @first_sequence_number = Sandthorn.get_aggregate_events(AnAggregate, @agg.id).first[:sequence_number]
        @agg.foo("new_name")
        @agg.save()
        @second_sequence_number = Sandthorn.get_aggregate_events(AnAggregate, @agg.id).last[:sequence_number]
        @agg.foo("new_name_last")
        @agg.save()
        @last_sequence_number = Sandthorn.get_aggregate_events(AnAggregate, @agg.id).last[:sequence_number]
      end

      let(:first_version) { builder.build(@agg.id, sequence_number: @first_sequence_number) }
      let(:second_version) { builder.build(@agg.id, sequence_number: @second_sequence_number) }
      let(:current_version) { builder.build(@agg.id, sequence_number: @last_sequence_number) }

      it "should get the first version of the aggregate" do
        expect(first_version.aggregate_current_event_version).to eql 1
        expect(first_version.name).to be_nil
      end

      it "should get the secound version of the aggregate" do
        expect(second_version.aggregate_current_event_version).to eql 2
        expect(second_version.name).to eql "new_name"
      end

      it "should get the current version of the aggregate" do
        expect(current_version.aggregate_current_event_version).to eql 3
        expect(current_version.name).to eql "new_name_last"
      end

    end

    context "build from aggregate_version" do
      before(:each) do
        @agg = AnAggregate.new
        @agg.foo("new_name")
        @agg.foo("new_name_last")
        @agg.save()
      end

      let(:first_version) { builder.build_from_version(@agg.id, 1)}
      let(:second_version) { builder.build_from_version(@agg.id, 2) }
      let(:current_version) { builder.build_from_version(@agg.id, 3) }

      it "should get the first version of the aggregate" do
        expect(first_version.aggregate_current_event_version).to eql 1
        expect(first_version.name).to be_nil
      end

      it "should get the secound version of the aggregate" do
        expect(second_version.aggregate_current_event_version).to eql 2
        expect(second_version.name).to eql "new_name"
      end

      it "should get the current version of the aggregate" do
        expect(current_version.aggregate_current_event_version).to eql 3
        expect(current_version.name).to eql "new_name_last"
      end

    end
  end
end