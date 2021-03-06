require 'spec_helper'

module Sandthorn
  module AggregateRoot
    class DirtyClass
      include Sandthorn::AggregateRoot
      attr_reader :name, :age
      attr :age
      attr_writer :writer
      
      def initialize args = {}
        @name = args.fetch(:name, nil)
        @age = args.fetch(:age, nil)
        @writer = args.fetch(:writer, nil)
      end

      def change_name value
        unless name == value
          @name = value
          commit
        end
      end

      def change_age value
        unless age == value
          @age = value
          commit
        end
      end

      def change_writer value
        unless writer == value
          @writer = value
          commit
        end
      end

      def no_state_change_only_empty_event
        commit
      end
    end

    describe "::event_store" do
      let(:klass) { Class.new { include Sandthorn::AggregateRoot } }
      it "is available as a class method" do
        expect(klass).to respond_to(:event_store)
      end
      it "sets the event store as a class level variable and returns it" do
        klass.event_store(:other)
        expect(klass.event_store).to eq(:other)
      end
    end

    describe "::snapshot" do
      let(:klass) { Class.new { include Sandthorn::AggregateRoot } }
      it "is available as a class method" do
        expect(klass).to respond_to(:snapshot)
      end
      it "sets the snapshot to true and returns it" do
        klass.snapshot(true)
        expect(klass.snapshot).to eq(true)
      end
    end

    describe "when get all aggregates from DirtyClass" do
      
      before(:each) do
        @first = DirtyClass.new.save
        @middle = DirtyClass.new.save
        @last = DirtyClass.new.save
      end

      let(:subject) { DirtyClass.all.map{ |s| s.id} }
      let(:ids) { [@first.id, @middle.id, @last.id] }

      context "all" do
        it "should all the aggregates" do
          expect(subject.length).to eq(3)
        end

        it "should include correct aggregates" do
          expect(subject).to match_array(ids)
        end
      end

    end


    describe "when making a change on a aggregate" do
      let(:dirty_object) { 
        o = DirtyClass.new
        o
      }

      context "new with args" do

        let(:subject) { DirtyClass.new(name: "Mogge", age: 35, writer: true) }
        it "should set the values" do
          expect(subject.name).to eq("Mogge")
          expect(subject.age).to eq(35)
          expect{subject.writer}.to raise_error NoMethodError
        end
      end

      context "when changing name (attr_reader)" do
        
        it "should get new_name" do
          dirty_object.change_name "new_name"
          expect(dirty_object.name).to eq("new_name")
        end

        it "should generate one event on new" do
          expect(dirty_object.aggregate_events.length).to eq(1)
        end

        it "should generate 2 events new and change_name" do
          dirty_object.change_name "new_name"
          expect(dirty_object.aggregate_events.length).to eq(2)
        end
      end

      context "when changing age (attr)" do
        it "should get new_age" do
          dirty_object.change_age "new_age"
          expect(dirty_object.age).to eq("new_age")
        end
      end

      context "when changing writer (attr_writer)" do
        it "should raise error" do
          expect{dirty_object.change_writer "new_writer"}.to raise_error NameError
        end
      end

      context "save" do
        it "should not have events on aggregate after save" do
          expect(dirty_object.save.aggregate_events.length).to eq(0)
        end

        it "should have aggregate_originating_version == 0 pre save" do
          expect(dirty_object.aggregate_originating_version).to eq(0)
        end

        it "should have aggregate_originating_version == 1 post save" do
          expect(dirty_object.save.aggregate_originating_version).to eq(1)
        end
      end

      context "find" do
        before(:each) { dirty_object.save }
        it "should find by id" do
          expect(DirtyClass.find(dirty_object.id).id).to eq(dirty_object.id)
        end

        it "should hold changed name" do
          dirty_object.change_name("morgan").save
          expect(DirtyClass.find(dirty_object.id).name).to eq("morgan")
        end

        it "should raise error if trying to find id that not exist" do
          expect{DirtyClass.find("666")}.to raise_error Sandthorn::Errors::AggregateNotFound
        end
      end


    end

    describe "event data" do

      let(:dirty_object) { 
        o = DirtyClass.new :name => "old_value", :age => 35
        o.save
      }

      let(:dirty_object_after_find) { DirtyClass.find dirty_object.id }

      context "after find" do

        it "should set the old_value on the event" do
          dirty_object_after_find.change_name "new_name"
          expect(dirty_object_after_find.aggregate_events.last[:event_data][:name][:old_value]).to eq("old_value")
        end

      end

      context "old_value should be set" do
      
        it "should set the old_value on the event" do
          dirty_object.change_name "new_name"
          expect(dirty_object.aggregate_events.last[:event_data][:name][:old_value]).to eq("old_value")
        end

        it "should not change aggregate_id" do
          dirty_object.change_name "new_name"
          expect(dirty_object.aggregate_events.last[:event_data]["attribute_name"]).not_to eq("aggregate_id")
        end

        it "should not change age attribute if age method is not runned" do
          dirty_object.change_name "new_name"
          dirty_object.aggregate_events.each do |event|
            expect(event[:event_data]["age"].nil?).to be_truthy
          end
        end

        it "should not change age attribute if age attribute is the same" do
          dirty_object.change_age 35
          dirty_object.aggregate_events.each do |event|
            expect(event[:event_data]["age"].nil?).to be_truthy
          end
        end

        it "should set old_value and new_value on age change" do
          dirty_object.change_age 36
          expect(dirty_object.aggregate_events.last[:event_data][:age][:old_value]).to eq(35)
          expect(dirty_object.aggregate_events.last[:event_data][:age][:new_value]).to eq(36)
        end
      end
    end

    context "events should be created event if no state change is made" do
      let(:dirty_object) do
        DirtyClass.new.save.tap do |o|
          o.no_state_change_only_empty_event
        end
      end

      it "should have the event no_state_change_only_empty_event" do
        expect(dirty_object.aggregate_events.first[:event_name]).to eq("no_state_change_only_empty_event")
      end

      it "should have event_data set to empty hash" do
        expect(dirty_object.aggregate_events.first[:event_data]).to eq({})
      end

    end
  end
end
