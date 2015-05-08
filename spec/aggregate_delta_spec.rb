require "spec_helper"

class PersonTest
  include Sandthorn::AggregateRoot
  attr_reader :name
  attr_reader :age
  attr_reader :relationship_status
  attr_reader :my_array
  attr_reader :my_hash

  def initialize(name, age, relationship_status)
    @name = name
    @age = age
    @relationship_status = relationship_status
    @my_array = []
    @my_hash = {}
  end

  def change_name(new_name)
    @name = new_name
    record_event new_name
  end

  def change_relationship(new_relationship)
    @relationship_status = new_relationship
    record_event new_relationship
  end

  def add_to_array(element)
    @my_array << element
    record_event element
  end

  def add_to_hash(name, value)
    @my_hash[name] = value
    record_event name, value
  end
end

describe "Property Delta Event Sourcing" do
  let(:person) { PersonTest.new "Lasse", 40, :married }

  it "should be able to set name" do
    person.change_name "Klabbarparen"
    expect(person.name).to eql("Klabbarparen")
    # puts person.aggregate_events
  end

  it "should be able to build from events" do
    person.change_name "Klabbarparen"
    builded = PersonTest.aggregate_build person.aggregate_events
    expect(builded.name).to eql(person.name)
    expect(builded.aggregate_id).to eql(person.aggregate_id)
  end

  it "should not have any events when built up" do
    person.change_name "Mattias"
    builded = PersonTest.aggregate_build person.aggregate_events
    expect(builded.aggregate_events).to be_empty
  end

  it "should detect change on array" do
    person.add_to_array "Foo"
    person.add_to_array "bar"

    builded = PersonTest.aggregate_build person.aggregate_events
    expect(builded.my_array).to include "Foo"
    expect(builded.my_array).to include "bar"
  end

  it "should detect change on hash" do
    person.add_to_hash :foo, "bar"
    person.add_to_hash :bar, "foo"

    builded = PersonTest.aggregate_build person.aggregate_events
    expect(builded.my_hash[:foo]).to eql("bar")
    expect(builded.my_hash[:bar]).to eql("foo")

    person.add_to_hash :foo, "BAR"

    # events = person.aggregate_events
    # events << builded.aggregate_events
    # puts events

    builded2 = PersonTest.aggregate_build person.aggregate_events
    expect(builded2.my_hash[:foo]).to eql("BAR")
  end
end
