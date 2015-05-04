require "spec_helper"
require "benchmark"

module Sandthorn
  module AggregateRoot
    class TestClass
      include Sandthorn::AggregateRoot
      attr_reader :name

      def initialize(args = {})
      end

      def change_name(value)
        unless name == value
          @name = value
          commit
        end
      end
    end

    describe "benchmark", benchmark: true do
      let(:test_object) {
        TestClass.new.save
      }
      n = 500
      it "should new, change_name, save and find 500 aggregates" do
        Benchmark.bm do |x|
          x.report("new change save find") do
            n.times do
              s = TestClass.new.change_name("benchmark").save
              TestClass.find(s.id)
            end
          end
        end
      end
      it "should find 500 aggregates" do
        Benchmark.bm do |x|
          x.report("find") do
            n.times { TestClass.find(test_object.id) }
          end
        end
      end
      it "should commit 500 actions" do
        Benchmark.bm do |x|
          x.report("commit") do
            n.times { test_object.change_name(i.to_s) }
          end
        end
      end
      it "should commit and save 500 actions" do
        Benchmark.bm do |x|
          x.report("commit save") do
            n.times { test_object.change_name(i.to_s).save }
          end
        end
      end
    end
  end
end
