require 'spec_helper'

module Sandthorn
  class ConstructorEventsSpec
    include AggregateRoot

    constructor_events :created_event
    attr_reader :name


    def self.create name
      created_event(name) { @name = name }
    end

  end

  describe "::constructor_events" do

    let(:subject) do
      ConstructorEventsSpec.create("name").save
    end

    context "interface" do

      it "should not expose constructor_events methods" do
        expect(subject).not_to respond_to(:created_event)
      end

      it "should create the constructor event on the class" do
        expect(ConstructorEventsSpec.private_methods).to include(:created_event)
      end

    end
  end

  describe "::create" do
    let(:aggregate_id) do
      a = ConstructorEventsSpec.create("create_name")
      a.save
      a.aggregate_id
    end

    it "should create an ConstructorEventsSpec aggregate" do
      expect(ConstructorEventsSpec.find(aggregate_id)).to be_a ConstructorEventsSpec
    end

    it "should set instance variable in aggregate" do
      expect(ConstructorEventsSpec.find(aggregate_id).name).to eql "create_name"
    end

    it "should have created an created_event" do
      expect(Sandthorn.find(aggregate_id, ConstructorEventsSpec).first[:event_name]).to eql "created_event"
    end

    it "should have set the attribute_delta name" do
      expect(Sandthorn.find(aggregate_id, ConstructorEventsSpec).first[:event_data]["name"].nil?).to be_falsy
      expect(Sandthorn.find(aggregate_id, ConstructorEventsSpec).first[:event_data]["name"][:new_value]).to eql "create_name"
    end
  end
end