require 'spec_helper'
require 'sandthorn/event_inspector'

module Sandthorn
  class EventsSpec
    include AggregateRoot

    events :name_changed, :some_other_event, :third_event
    attr_reader :name

    def change_name(name)
      if @name != name
        name_changed(name) { @name = name }
      end
    end

    def some_other one, two
      some_other_event one, two
    end

    def old_way_event event_params
      commit event_params
    end
  end

  describe "::events" do

    let(:subject) do
      EventsSpec.new.extend EventInspector
    end

    it "should not expose events methods" do
      expect(subject).not_to respond_to(:name_changed)
    end
    
    it "should make the events methods private" do
      expect(subject.private_methods).to include(:name_changed)
    end

    describe ".change_name" do
    
      before do
        subject.change_name "new name"
      end

      it "should set the name instance variable" do
        expect(subject.name).to eql "new name"
      end
    
      it "should store the event params as methods args" do
        expect(subject.has_event?(:name_changed)).to be_truthy
      end

      it "should store the args to the event" do
        expect(subject.aggregate_events[1][:event_args][:method_args][0]).to eql("new name")
      end

      it "should store the event_name" do
        expect(subject.aggregate_events[1][:event_name]).to eql("name_changed")
      end
    end

    describe ".some_other" do
    
      before do
        subject.some_other 1, 2
      end
    
      it "should store the event" do
        expect(subject.has_event?(:some_other_event)).to be_truthy
      end

      it "should store the args to the event" do
        expect(subject.aggregate_events[1][:event_args][:method_args]).to eql([1,2])
      end
    end

    describe ".old_way_event" do
      
      before do
        subject.old_way_event "hej"
      end

      it "should store the event the old way" do
        expect(subject.has_event?(:old_way_event)).to be_truthy
      end

      it "should store the args to the event" do
        expect(subject.aggregate_events[1][:event_args][:method_args][0]).to eql("hej")
      end
    end
  end
end