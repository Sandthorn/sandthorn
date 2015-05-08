# require 'spec_helper'
# require 'sandthorn/event_inspector'
# require 'sandthorn/aggregate_root_dirty_hashy'

# class InspectorAggregate
#   include Sandthorn::AggregateRoot::DirtyHashy

#   attr_reader :foo_bar

#   def initialize args = {}
#     @foo_bar = args.fetch(:foo_bar, nil)
#   end

#   def this_is_an_event args = nil
#     record_event args
#   end
#   def another_event
#     record_event
#   end
#   def new_damaged_item_was_added hello
#     record_event hello
#   end
# end

# module Sandthorn
#   describe EventInspector do
#     let(:aggregate) {InspectorAggregate.new.extend EventInspector}

#     context "when using extract_trace_info from an event" do
#       let(:trace_info) {{user_id: "foo", ip: "bar"}}
#       let(:subject) do
#         aggregate.aggregate_trace trace_info do |traced|
#           traced.this_is_an_event
#         end
#         aggregate
#       end
#       context "and unsaved aggregate" do
#         it "should extract exact traceinfo from event" do
#           all_trace = subject.events_with_trace_info
#           all_trace.last[:trace].should eql trace_info
#         end
#       end
#       context "and saved aggregate" do
#         it "should extract exact traceinfo from event" do
#           subject.save
#           all_trace = subject.events_with_trace_info
#           all_trace.last[:trace].should eql trace_info
#         end
#       end
#     end
#     context "when inspecting non saved events" do
#       context "with no tracing information" do
#         let(:subject) { aggregate.this_is_an_event;aggregate }

#         it "should have the new event" do
#           subject.has_event?(:new).should be_true
#         end

#         it "should report true on has_unsaved_event? :this_is_an_event" do
#           subject.has_unsaved_event?(:this_is_an_event).should be_true
#         end
#         it "should report false on has_unsaved_event? :no_event_here" do
#           subject.has_unsaved_event?(:no_event_here).should be_false
#         end
#       end
#       context "with tracing information" do
#         let(:subject) do
#           aggregate.aggregate_trace user_id: 123, ip: "1234" do |traced|
#             traced.this_is_an_event "my name"
#           end
#           aggregate
#         end

#         it "should report true on has_unsaved_event? :this_is_an_event" do
#           subject.has_unsaved_event?(:this_is_an_event, trace: {user_id: 123, ip: "1234"}).should be_true
#         end
#         it "should report false on has_unsaved_event? :no_event_here" do
#           subject.has_unsaved_event?(:this_is_an_event, trace: {user_id: 321}).should be_false
#           subject.has_unsaved_event?(:this_is_an_event, trace: {another_user_id: 123}).should be_false
#         end
#       end
#     end
#     context "when inspecting saved events" do
#       context "with no tracing information" do
#         let(:subject) { aggregate.this_is_an_event;aggregate.save;aggregate }

#         it "should report true on has_unsaved_event? :this_is_an_event" do
#           subject.has_saved_event?(:this_is_an_event).should be_true
#         end
#         it "should report false on has_unsaved_event? :no_event_here" do
#           subject.has_saved_event?(:no_event_here).should be_false
#         end
#       end
#       context "with tracing information" do
#         let(:subject) do
#           aggregate.aggregate_trace user_id: 123, ip: "1234" do |traced|
#             traced.this_is_an_event "my name"
#           end
#           aggregate.save
#           aggregate
#         end

#         it "should report true on has_unsaved_event? :this_is_an_event" do
#           subject.has_saved_event?(:this_is_an_event, trace: {user_id: 123, ip: "1234"}).should be_true
#         end
#         it "should report false on has_unsaved_event? :no_event_here" do
#           subject.has_saved_event?(:this_is_an_event, trace: {user_id: 321}).should be_false
#           subject.has_saved_event?(:this_is_an_event, trace: {another_user_id: 123}).should be_false
#         end
#         it "should be able to check complex trace" do
#           subject.aggregate_trace client_ip: "10", user_id: "123" do |trace|
#             trace.new_damaged_item_was_added "foobar"
#             trace.save
#           end
#           subject.has_saved_event?(:new_damaged_item_was_added, trace: {user_id: "123", client_ip: "10"})
#         end
#       end
#     end
#     context "when inspecting any events" do
#       context "with no tracing information" do
#         let(:subject) { aggregate.this_is_an_event;aggregate.save;aggregate.another_event;aggregate }

#         it "should report true on has_unsaved_event? :this_is_an_event" do
#           subject.has_event?(:this_is_an_event).should be_true
#           subject.has_event?(:another_event).should be_true
#         end
#         it "should report false on has_unsaved_event? :no_event_here" do
#           subject.has_event?(:no_event_here).should be_false
#         end
#       end
#       context "with tracing information" do
#         let(:subject) do
#           aggregate.aggregate_trace user_id: 123, ip: "1234" do |traced|
#             traced.this_is_an_event "my name"
#             traced.save
#             traced.another_event
#           end
#           aggregate
#         end

#         it "should report true on has_unsaved_event? :this_is_an_event" do
#           subject.has_event?(:this_is_an_event, trace: {user_id: 123, ip: "1234"}).should be_true
#           subject.has_event?(:another_event, trace: {user_id: 123, ip: "1234"}).should be_true
#         end
#         it "should report false on has_unsaved_event? :no_event_here" do
#           subject.has_event?(:this_is_an_event, trace: {user_id: 321}).should be_false
#           subject.has_event?(:another_event, trace: {ip: "123"}).should be_false
#         end
#       end
#     end
#   end
# end
