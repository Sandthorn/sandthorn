require 'spec_helper'

module Sandthorn
  class StatelessEventsSpec
    include AggregateRoot

    stateless_events :one_event, :some_other_event
    attr_reader :name

    def initialize name
      @name = name
    end

  end

  describe "::stateless_events" do
    
    let(:args) do
      {first: "first", other: [1,2,3]}
    end

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
        StatelessEventsSpec.one_event(subject.aggregate_id, args)
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

      it "should have staeless data in deltas in event" do
        expect(last_event[:event_data][:attribute_deltas]).to eql ([{:attribute_name=>"first", :old_value => nil, :new_value => "first"}, { :attribute_name => "other", :old_value => nil, :new_value => [1, 2, 3]}])
      end

      it "should have same name attribute after reload" do
        expect(subject.name).to eql(reloaded_subject.name)
      end
    end

    context "when adding stateless_events to none existing aggregate" do

      before do
        StatelessEventsSpec.one_event(aggregate_id, args)
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

    context "overriding properties with stateless data" do
      let(:subject) do
        StatelessEventsSpec.new("name").save
      end

      let(:reloaded_subject) do
        StatelessEventsSpec.find subject.aggregate_id
      end

      let(:args) do
        {name: "ghost"}
      end

      before do
        StatelessEventsSpec.one_event(subject.aggregate_id, args)
      end

      it "should override the name via the stateless event" do
        expect(subject.name).not_to eql(reloaded_subject.name)
      end
    end
  end
end