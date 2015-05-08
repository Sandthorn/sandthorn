require "spec_helper"

module Sandthorn
  module AggregateRoot
    class DirtyClass
      include Sandthorn::AggregateRoot
      attr_reader :name, :age
      attr_reader :sex
      attr_writer :writer

      def initialize(args = {})
        @name = args.fetch(:name, nil)
        @sex = args.fetch(:sex, nil)
        @writer = args.fetch(:writer, nil)
      end

      def change_name(value)
        unless name == value
          @name = value
          commit
        end
      end

      def change_sex(value)
        unless sex == value
          @sex = value
          commit
        end
      end

      def change_writer(value)
        unless writer == value
          @writer = value
          commit
        end
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

    describe "when get all aggregates from DirtyClass" do
      before(:each) do
        @first = DirtyClass.new.save
        @middle = DirtyClass.new.save
        @last = DirtyClass.new.save
      end

      let(:subject) { DirtyClass.all.map(&:id) }
      let(:ids) { [@first.id, @middle.id, @last.id] }

      context "all" do
        it "should all the aggregates" do
          expect(subject.length).to eql 3
        end

        it "should include correct aggregates" do
          expect(subject).to match_array(ids)
        end
      end
    end

    describe "when making a change on a aggregate" do
      let(:dirty_obejct) do
        o = DirtyClass.new
        o
      end

      context "new with args" do
        let(:subject) { DirtyClass.new(name: "Mogge", sex: "hen", writer: true) }
        it "should set the values" do
          expect(subject.name).to eql "Mogge"
          expect(subject.sex).to eql "hen"
          expect { subject.writer }.to raise_error
        end
      end

      context "when changing name (attr_reader)" do
        it "should get new_name" do
          dirty_obejct.change_name "new_name"
          expect(dirty_obejct.name).to eql "new_name"
        end

        it "should generate one event on new" do
          expect(dirty_obejct.aggregate_events.length).to eql 1
        end

        it "should generate 2 events new and change_name" do
          dirty_obejct.change_name "new_name"
          expect(dirty_obejct.aggregate_events.length).to eql 2
        end
      end

      context "when changing sex (attr)" do
        it "should get new_sex" do
          dirty_obejct.change_sex "new_sex"
          expect(dirty_obejct.sex).to eql "new_sex"
        end
      end

      context "when changing writer (attr_writer)" do
        it "should raise error" do
          expect { dirty_obejct.change_writer "new_writer" }.to raise_error
        end
      end

      context "save" do
        it "should not have events on aggregete after save" do
          expect(dirty_obejct.save.aggregate_events.length).to eql 0
        end

        it "should have aggregate_originating_version == 0 pre save" do
          expect(dirty_obejct.aggregate_originating_version).to eql 0
        end

        it "should have aggregate_originating_version == 1 post save" do
          expect(dirty_obejct.save.aggregate_originating_version).to eql 1
        end
      end

      context "find" do
        before(:each) { dirty_obejct.save }
        it "should find by id" do
          expect(DirtyClass.find(dirty_obejct.id).id).to eql dirty_obejct.id
        end

        it "should hold changed name" do
          dirty_obejct.change_name("morgan").save
          expect(DirtyClass.find(dirty_obejct.id).name).to eql "morgan"
        end

        it "should raise error if trying to find id that not exist" do
          expect { DirtyClass.find("666") }.to raise_error
        end
      end
    end

    describe "event data" do
      let(:dirty_obejct) do
        o = DirtyClass.new name: "old_value", sex: "hen"
        o.save
      end

      let(:dirty_obejct_after_find) { DirtyClass.find dirty_obejct.id }

      context "after find" do
        it "should set the old_value on the event" do
          dirty_obejct_after_find.change_name "new_name"
          expect(dirty_obejct_after_find.aggregate_events.last[:event_args][:attribute_deltas].first[:old_value]).to eql "old_value"
        end
      end

      context "old_value should be set" do
        it "should set the old_value on the event" do
          dirty_obejct.change_name "new_name"
          expect(dirty_obejct.aggregate_events.last[:event_args][:attribute_deltas].first[:old_value]).to eql "old_value"
        end

        it "should not change aggregate_id" do
          dirty_obejct.change_name "new_name"
          expect(dirty_obejct.aggregate_events.last[:event_args][:attribute_deltas].last[:attribute_name]).not_to eql "aggregate_id"
        end

        it "should not change sex attribute if sex method is not runned" do
          dirty_obejct.change_name "new_name"
          dirty_obejct.aggregate_events.each do |event|
            event[:event_args][:attribute_deltas].each do |attribute_delta|
              expect(attribute_delta[:attribute_name]).not_to eql "sex"
            end
          end
        end

        it "should not change sex attribute if sex attribute is the same" do
          dirty_obejct.change_sex "hen"
          dirty_obejct.aggregate_events.each do |event|
            event[:event_args][:attribute_deltas].each do |attribute_delta|
              expect(attribute_delta[:attribute_name]).not_to eql "sex"
            end
          end
        end

        it "should set old_value and new_value on sex change" do
          dirty_obejct.change_sex "shemale"
          expect(dirty_obejct.aggregate_events.last[:event_args][:attribute_deltas].first[:old_value]).to eql "hen"
          expect(dirty_obejct.aggregate_events.last[:event_args][:attribute_deltas].first[:new_value]).to eql "shemale"
        end
      end
    end
  end
end
