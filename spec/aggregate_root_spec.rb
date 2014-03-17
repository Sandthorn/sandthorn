require 'spec_helper'
require 'sandthorn/aggregate_root_dirty_hashy'

module Sandthorn
  module AggregateRoot
    class DirtyClass
      include Sandthorn::AggregateRoot::DirtyHashy
      attr_reader :name, :age
      attr :sex
      attr_writer :writer
      
      def initialize args = {}
        @name = args.fetch(:name, nil)
        @sex = args.fetch(:sex, nil)
        @writer = args.fetch(:writer, nil)
      end

      def change_name value
        unless name == value
          @name = value
          commit
        end
      end

      def change_sex value
        unless sex == value
          @sex = value
        end
      end

      def change_writer value
        unless writer == value
          @writer = value
        end
      end

      
    end


    describe "when making a change on a aggregate" do
      let(:dirty_obejct) { 
        o = DirtyClass.new
        o
      }

      context "new with args" do

        let(:subject) { DirtyClass.new(name: "Mogge", sex: "hen", writer: true) }
        it "should set the values" do
          expect(subject.name).to eql "Mogge"
          expect(subject.sex).to eql "hen"
          expect{subject.writer}.to raise_error
        end
      end

      context "when changing name (attr_reader)" do
        
        it "should get new_name" do
          dirty_obejct.change_name "new_name"
          dirty_obejct.name.should eql "new_name"
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
          dirty_obejct.sex.should eql "new_sex"
        end
      end

      context "when changing writer (attr_writer)" do
        it "should raise error" do
          expect{dirty_obejct.change_writer "new_writer"}.to raise_error
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
          expect{DirtyClass.find("666")}.to raise_error
        end
      end
    end
  end
end