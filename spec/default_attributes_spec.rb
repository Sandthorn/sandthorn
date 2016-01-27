require 'spec_helper'

class DefaultAttributes
  include Sandthorn::AggregateRoot
  def initialize 
  end
end


describe "when the initialize-method changes" do

  it "should not have an array attribute on first version of the DefaultAttributes class" do
    aggregate = DefaultAttributes.new
    expect(aggregate.respond_to?(:array)).to be_falsy
  end

  context "default_attributes" do

    def add_default_attributes
      DefaultAttributes.class_eval do
        attr_reader :array
        define_method :default_attributes, lambda { @array = [] }
      end
    end

    it "should have set the array attribute to [] on rebuilt " do
      aggregate = DefaultAttributes.new
      add_default_attributes
      rebuilt_aggregate = DefaultAttributes.aggregate_build(aggregate.aggregate_events)
      expect(rebuilt_aggregate.array).to eql []
    end

    it "should have an set the array attribute to [] on new" do
      add_default_attributes
      aggregate = DefaultAttributes.new
      expect(aggregate.array).to eql []
    end
  end
end
