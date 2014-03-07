require 'spec_helper'
require 'sandthorn/aggregate_root_dirty_hashy'
require 'benchmark'

module Sandthorn
  module AggregateRoot
    class TestClass
      include Sandthorn::AggregateRoot::DirtyHashy
      attr_reader :name
      
      
      def initialize args = {}
      end

      def change_name value
        unless name == value
          @name = value
          commit
        end
      end

    end

    describe "benchmark" do

      let(:test_object) { 
        o = TestClass.new().save
        o
      }
      n = 500
      it "should new, change_name, save and find 500 aggregates" do

        Benchmark.bm do |x|
          x.report("new change save find") { for i in 1..n; s = TestClass.new().change_name("benchmark").save(); TestClass.find(s.id);  end }
        end

      end
      it "should find 500 aggregates" do
        Benchmark.bm do |x|
          x.report("find") { for i in 1..n; TestClass.find(test_object.id);  end }
        end
      end
      it "should commit 500 actions" do
        Benchmark.bm do |x|
          x.report("commit") { for i in 1..n; test_object.change_name "#{i}";  end }
        end
      end
      it "should commit and save 500 actions" do
        Benchmark.bm do |x|
          x.report("commit save") { for i in 1..n; test_object.change_name("#{i}").save;  end }
        end
      end
    end
  end
end