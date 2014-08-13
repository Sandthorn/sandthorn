require 'spec_helper'
require 'sandthorn/event_inspector'
require 'sandthorn/aggregate_root_snapshot'

class UsualSuspect
  include Sandthorn::AggregateRoot

  def initialize full_name
    @full_name = full_name
    @charges = []
  end

  def charge_suspect_of_crime! crime_name
    suspect_was_charged crime_name
  end
  
  private
  def suspect_was_charged crime_name
    @charges << crime_name
    record_event crime_name
  end
end

class Simple
  include Sandthorn::AggregateRoot
end
module Go
  def go
    @foo = "bar"
    record_event
  end
end

describe "using a traced change" do
  context "when extending an instance with aggregate_root" do
    it "should record tracing if specified" do
      simple = Simple.new
      simple.extend Sandthorn::EventInspector
      simple.extend Sandthorn::AggregateRootSnapshot
      
      simple.extend Go
      simple.aggregate_trace "123" do |traced|
        traced.go
      end
      simple.events_with_trace_info.last[:trace].should eql("123")
    end
  end
  context "when not tracing" do
    it "should not have any trace event info at all on new" do
      suspect = UsualSuspect.new "Ronny"
      event = suspect.aggregate_events.first
      event[:trace].should be_nil
    end
    it "should not have any trace event info at all on regular event" do
      suspect = UsualSuspect.new "Ronny"
      event = suspect.aggregate_events.first
      event[:trace].should be_nil
    end
  end
  context "when changing aggregate in a traced context" do
    let(:suspect) {UsualSuspect.new("Conny").extend Sandthorn::EventInspector}
    it "should record modififier in the event" do
      suspect.aggregate_trace "Ture Sventon" do |s|
        s.charge_suspect_of_crime! "Theft"
      end
      event = suspect.events_with_trace_info.last
      event[:trace].should eql "Ture Sventon"
    end

    it "should record optional other tracing information" do
      trace_info = {ip: "127.0.0.1", client: "Mozilla"}
      suspect.aggregate_trace trace_info do |s| 
        s.charge_suspect_of_crime! "Murder"       
      end
      event = suspect.events_with_trace_info.last
      event[:trace].should eql trace_info 
    end
  end
  context "when initializing a new aggregate in a traced context" do
    it "should record modifier in the new event" do
      UsualSuspect.aggregate_trace "Ture Sventon" do
        suspect = UsualSuspect.new("Sonny").extend Sandthorn::EventInspector
        event = suspect.events_with_trace_info.first
        event[:trace].should eql "Ture Sventon"
      end
    end
    it "should record tracing for all events in the trace block" do
      trace_info = {gender: :unknown, occupation: :master} 
      UsualSuspect.aggregate_trace trace_info do
        suspect = UsualSuspect.new("Sonny").extend Sandthorn::EventInspector
        suspect.charge_suspect_of_crime! "Hit and run"
        event = suspect.events_with_trace_info.last
        event[:trace].should eql trace_info
      end
    end
    it "should record tracing for all events in the trace block" do
      trace_info = {user_aggregate_id: "foo-bar-x", gender: :unknown, occupation: :master} 
      UsualSuspect.aggregate_trace trace_info do
        suspect = UsualSuspect.new("Conny").extend Sandthorn::EventInspector
        suspect.charge_suspect_of_crime! "Desception"
        event = suspect.events_with_trace_info.last
        event[:trace].should eql trace_info
      end
    end
    it "should only record info within block" do
      fork do
        UsualSuspect.aggregate_trace "Ture Sventon" do
          suspect = UsualSuspect.new("Sonny").extend Sandthorn::EventInspector
          event = suspect.events_with_trace_info.first
          event[:trace].should eql "Ture Sventon"
          sleep 1
        end
      end
      sleep 0.5
      s2 = UsualSuspect.new("Ronny").extend Sandthorn::EventInspector
      event = s2.events_with_trace_info.first
      event[:trace].should be_nil
    end
  end 

end