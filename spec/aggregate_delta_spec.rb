require 'spec_helper'
require 'uuidtools'
require 'sandthorn/aggregate_root_dirty_hashy'



class PersonTest
    include Sandthorn::AggregateRoot::DirtyHashy
    attr_reader :name
    attr_reader :age
    attr_reader :relationship_status
    attr_reader :my_array
    attr_reader :my_hash

  def initialize name, age, relationship_status
    @name = name
    @age = age
    @relationship_status = relationship_status
    @my_array = []
    @my_hash = {}
  end

    def change_name new_name
      @name = new_name
      record_event new_name
    end

    def change_relationship new_relationship
      @relationship_status = new_relationship
      record_event new_relationship
    end

    def add_to_array element
      @my_array << element
      record_event element
    end

    def add_to_hash name,value
      @my_hash[name] = value
      record_event name,value
    end
end

describe 'Property Delta Event Sourcing' do
  let(:person) { PersonTest.new "Lasse",40,:married}

  it 'should be able to set name' do
    person.change_name  "Klabbarparen"
    person.name.should eql("Klabbarparen")
    #puts person.aggregate_events
  end

  it 'should be able to build from events' do
    person.change_name  "Klabbarparen"
    builded = PersonTest.aggregate_build person.aggregate_events
    builded.name.should eql(person.name)
    builded.aggregate_id.should eql(person.aggregate_id)
  end

  it 'should not have any events when built up' do
    person.change_name "Mattias"
    builded = PersonTest.aggregate_build person.aggregate_events
    builded.aggregate_events.should be_empty
  end

  it 'should detect change on array' do
    person.add_to_array "Foo"
    person.add_to_array "bar"

    builded = PersonTest.aggregate_build person.aggregate_events
    builded.my_array.should include "Foo"
    builded.my_array.should include "bar"
  end

  it 'should detect change on hash' do
    person.add_to_hash :foo, "bar"
    person.add_to_hash :bar, "foo"

    builded = PersonTest.aggregate_build person.aggregate_events
    builded.my_hash[:foo].should eql("bar")
    builded.my_hash[:bar].should eql("foo")

    person.add_to_hash :foo, "BAR"

    #events = person.aggregate_events
    #events << builded.aggregate_events
    #puts events

    builded2 = PersonTest.aggregate_build person.aggregate_events
    builded2.my_hash[:foo].should eql("BAR")
  end
end