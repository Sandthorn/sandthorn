require 'spec_helper'

module Sandthorn
  class StatelessEventsSpec
    include AggregateRoot

    stateless_events :one_event, :some_other_event
    attr_reader :name

    def initialize name
      @name = name
    end

    # def self.call_one_event aggregate_id, hash = {}, value = 0
    #   one_event(aggregate_id, hash, value)
    # end

  end

  describe "::stateless_events" do

    context "interface" do

      it "should expose stateless_events methods" do
        expect(StatelessEventsSpec).to respond_to(:one_event)
      end

    end



    context "when adding a stateless event to an existing aggregate" do

      let(:subject) do
        StatelessEventsSpec.new("name").save
      end

      before do
        StatelessEventsSpec.one_event(subject.aggregate_id, args, 1)
      end

      let(:args) do
        {first: "first", other: [1,2,3]}
      end

      let(:last_event) do
        Sandthorn.get_aggregate_events(StatelessEventsSpec, subject.aggregate_id).last
      end

      let(:reloaded_subject) do
        StatelessEventsSpec.find subject.aggregate_id
      end

      it "should add one_event last on the aggregate" do
        expect(last_event[:event_name]).to eql "one_event"
      end

      it "should not have any deltas in event" do
        expect(last_event[:event_args][:attribute_deltas]).to eql []
      end

      it "should store event arguments" do
        expect(last_event[:event_args][:method_args].first).to eql(args)
        expect(last_event[:event_args][:method_args].last).to eql(1)
      end

      it "should have same name attribute after reload" do
        expect(subject.name).to eql(reloaded_subject.name)
      end
    end

    context "when adding stateless_events to none existing aggregate" do

      before do
        StatelessEventsSpec.one_event(aggregate_id, "argument_data")
      end

      let(:aggregate_id) {"none_existing_aggregate_id"}

      let(:events) do
        Sandthorn.get_aggregate_events(StatelessEventsSpec, aggregate_id)
      end

      it "should store the stateless event as the first event" do
        expect(events.length).to be 1
      end

      it "should have correct aggregate_id in event" do
        expect(events.first[:aggregate_id]).to eql aggregate_id
      end

      it "should have event name one_event" do
        expect(events.first[:event_name]).to eql "one_event"
      end
    end

  end
end