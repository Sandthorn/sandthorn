require 'spec_helper'
require 'sandthorn/bounded_context'

module Sandthorn
  describe BoundedContext do
    it 'should respond to `aggregate_types`' do
      expect(BoundedContext).to respond_to(:aggregate_types)
    end
  end

  describe "::aggregate_types" do
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

    it "aggregate_types should include AnAggregate" do
      expect(TestModule.aggregate_types).to include(TestModule::AnAggregate)
    end

    it "aggregate_types should not include NotAnAggregate" do
      expect(TestModule.aggregate_types).not_to include(TestModule::NotAnAggregate)
    end

    it "aggregate_types should include DeepAnAggregate in a nested Module" do
      expect(TestModule.aggregate_types).to include(TestModule::Deep::DeepAggregate)
    end
  end
end
