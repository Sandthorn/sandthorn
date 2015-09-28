require 'spec_helper'
require 'sandthorn/bounded_context'

module Sandthorn
  describe BoundedContext do
    it 'should respond to `aggregate_list`' do
      expect(BoundedContext).to respond_to(:aggregate_list)
    end
  end

  describe "::aggregate_list" do
    module TestModule
      include Sandthorn::BoundedContext
      class AnAggregate 
        include Sandthorn::AggregateRoot
      end

      class NotAnAggregate
      end

      module Deep
        class DeepAggregate
          include Sandthorn::AggregateRoot
        end
      end
    end

    it "aggregate_list should include AnAggregate" do
      expect(TestModule.aggregate_list).to include(TestModule::AnAggregate)
    end

    it "aggregate_list should not include NotAnAggregate" do
      expect(TestModule.aggregate_list).not_to include(TestModule::NotAnAggregate)
    end

    it "aggregate_list should include DeepAnAggregate in a nested Module" do
      expect(TestModule.aggregate_list).to include(TestModule::Deep::DeepAggregate)
    end
  end
end
