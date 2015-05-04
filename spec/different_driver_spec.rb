# require 'spec_helper'
# require 'sandthorn_driver_sequel'

# module UnknownModule
#   class Foo
#     include Sandthorn::AggregateRoot
#   end
# end
# module Sandthorn
#   class TestContextSwitching
#     attr_reader :foo
#     include Sandthorn::AggregateRoot
#     def change_foo value
#       unless foo == value
#         @foo = foo
#         foo_was_changed
#       end
#     end
#     private
#     def foo_was_changed
#       record_event
#     end
#   end
#   class AnotherContext < TestContextSwitching
#   end
#   describe "when using different contexts configuration" do
#     before(:each) do
#       Sandthorn.configuration = configuration
#       migrate

#     end
#     let(:configuration) do
#       c = []
#       setup.each do |s|
#         c << { aggregate_pattern: s[:aggregate_pattern], driver: SandthornDriverSequel::SequelDriver.new(url: s[:url], context: s[:context]) }
#       end
#       c
#     end
#     let(:migrate) do
#       setup.each do |s|
#         migrator = SandthornDriverSequel::Migration.new url: s[:url], context: s[:context]
#         migrator.migrate!
#         migrator.send(:clear_for_test)
#       end
#     end
#     let(:setup) do
#       [
#         { url: spec_db, context: :context_test, aggregate_pattern: Sandthorn::TestContextSwitching },
#         { url: spec_db, context: :nil, aggregate_pattern: Sandthorn }
#       ]
#     end
#     let(:create_in_context_test) { t = TestContextSwitching.new; t.change_foo :hello_context_1; t.aggregate_save; t;}
#     let(:create_in_default_context) { t = AnotherContext.new; t.change_foo :hello_default_context; t.aggregate_save; t;}
#     def exists_in_context? aggregate, context = nil
#       driver = SandthornDriverSequel::SequelDriver.new url: spec_db
#       table = "aggregates"
#       table = "#{context}_#{table}" if context
#       driver.execute do |db|
#         return db[table.to_sym].where(aggregate_id: aggregate.aggregate_id).any?
#       end
#     end
#     context "when trying to access an aggregate in a non configured context" do
#       it "should raise configuration error" do
#         expect { UnknownModule::Foo.find "boo" }.to raise_exception Sandthorn::Errors::ConfigurationError
#       end
#     end
#     context "when saving the aggregates" do
#       context "it should find the aggregates in separate contexts" do
#         it "should find TestContextSwitching aggregate in test-context only" do
#           expect(exists_in_context?(create_in_context_test, :context_test)).to be_true
#           expect(exists_in_context?(create_in_context_test)).to be_false
#         end
#         it "should find AnotherContext aggregate in default-context only" do
#           expect(exists_in_context?(create_in_default_context)).to be_true
#           expect(exists_in_context?(create_in_default_context, :context_test)).to be_false
#         end
#       end
#     end
#     context "getting events should respect context" do
#       before(:each) {create_in_context_test;create_in_default_context; }
#       context "when getting for specific context" do
#         let(:events) { Sandthorn.get_events classes: [Sandthorn::TestContextSwitching], after_sequence_number: 0 }
#         it "should have events" do
#           expect(events.length).to eq 2
#         end
#       end
#       context "when getting for all contexts" do
#         let(:events) { Sandthorn.get_events after_sequence_number: 0 }
#         it "should not be possible if multiple contexts" do
#           expect{events}.to raise_exception(Sandthorn::Errors::Error)
#         end
#       end
#       context "when getting for both classes" do
#         let(:events) { Sandthorn.get_events classes: [Sandthorn::TestContextSwitching, Sandthorn::AnotherContext], after_sequence_number: 0 }
#         it "should not be possible if multiple contexts" do
#           expect{events}.to raise_exception(Sandthorn::Errors::Error)
#         end
#       end
#     end
#   end
# end
