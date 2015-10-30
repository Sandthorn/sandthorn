require 'spec_helper'

module Sandthorn
  class ClassEventsSpec
    include AggregateRoot

    class_events :one_event, :some_other_event, :created_event
    attr_reader :name

    def initialize name
      @name = name
    end

    def self.create name
      created_event(nil, name) { @name = name }
    end

    def self.call_one_event aggregate_id = nil, hash = {}, value = 0
      one_event(aggregate_id, hash, value)
    end
    
  end

  describe "::class_events" do

    let(:subject) do
      ClassEventsSpec.new("name").save
    end

    context "interface" do

      it "should not expose class_events methods" do
        expect(subject).not_to respond_to(:one_event)
      end
      
      it "should create the events on the class" do
        expect(ClassEventsSpec.private_methods).to include(:one_event)
      end

    end

    context "when adding class_events to existing aggregate" do

      before do
        ClassEventsSpec.call_one_event(subject.aggregate_id, args, 1)
      end

      let(:args) do
        {first: "first", other: [1,2,3]}
      end

      let(:last_event) do
        Sandthorn.get_aggregate_events(ClassEventsSpec, subject.aggregate_id).last
      end

      let(:reloaded_subject) do
        ClassEventsSpec.find subject.aggregate_id
      end

      it "should add one_event last on the aggregate" do
        expect(last_event[:event_name]).to eql "one_event" 
      end

      it "should not have any deltas in event" do
        expect(Sandthorn.deserialize(last_event[:event_data])[:attribute_deltas]).to eql []
      end

      it "should store class_events arguments" do
        expect(Sandthorn.deserialize(last_event[:event_data])[:method_args].first).to eql(args)
        expect(Sandthorn.deserialize(last_event[:event_data])[:method_args].last).to eql(1)
      end

      it "should have same name attribute after reload" do
        expect(subject.name).to eql(reloaded_subject.name)
      end
    end

    context "when adding class_events to none existing aggregate" do
      let(:aggregate_id) do
        a = ClassEventsSpec.call_one_event()
        a.save
        a.aggregate_id
      end

      let(:events) do
        Sandthorn.get_aggregate_events(ClassEventsSpec, aggregate_id)
      end

      it "should store one event" do
        expect(events.length).to be 1
      end

      it "should have correct aggregate_id in event" do
        expect(events.first[:aggregate_id]).to eql aggregate_id
      end

      it "should have event name one_event" do
        expect(events.first[:event_name]).to eql "one_event"
      end
    end

    describe "::create" do
      let(:aggregate_id) do
        a = ClassEventsSpec.create("create_name")
        a.save
        a.aggregate_id
      end

      it "should create an ClassEventsSpec aggregate" do
        expect(ClassEventsSpec.find(aggregate_id)).to be_a ClassEventsSpec
      end

      it "should set instance variable in aggregate" do
        expect(ClassEventsSpec.find(aggregate_id).name).to eql "create_name"
      end

      it "should have created an created_event" do
        expect(Sandthorn.get_aggregate_events(ClassEventsSpec, aggregate_id).first[:event_name]).to eql "created_event"
      end

      it "should have set the method_args to create_name" do
        expect(Sandthorn.deserialize(Sandthorn.get_aggregate_events(ClassEventsSpec, aggregate_id).first[:event_data])[:method_args].first).to eql "create_name"
      end
    end
  end
end