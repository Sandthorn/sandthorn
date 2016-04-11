require 'spec_helper'

# class DefaultAttributes
#   include Sandthorn::AggregateRoot
#   def initialize
#   end
# end


describe "when the initialize-method changes" do

  before do
    class DefaultAttributes
      include Sandthorn::AggregateRoot
      def initialize
      end
    end

  end

  #Make sure the DefaultAttributes class are reset on every test
  after do
    Object.send(:remove_const, :DefaultAttributes)
  end

  it "should not have an array attribute on first version of the DefaultAttributes class" do
    aggregate = DefaultAttributes.new
    expect(aggregate.respond_to?(:array)).to be_falsy
  end

  context "default_attributes" do

    def add_default_attributes
      DefaultAttributes.class_eval do
        attr_reader :array
        define_method :default_attributes, lambda { @array = [] }
        define_method :add_item, lambda { |item|
          @array << item
          commit
        }
      end
    end

    it "should have an set the array attribute to [] on new" do
      add_default_attributes
      aggregate = DefaultAttributes.new
      expect(aggregate.array).to eql []
    end

    it "should have set the array attribute to [] on rebuilt when attribute is intruduced after `new`" do
      aggregate = DefaultAttributes.new
      add_default_attributes
      rebuilt_aggregate = DefaultAttributes.aggregate_build(aggregate.aggregate_events)
      expect(rebuilt_aggregate.array).to eql []
    end

    it "should set the array attribute to ['banana'] on rebuilt" do
      add_default_attributes
      aggregate = DefaultAttributes.new
      aggregate.add_item 'banana'
      rebuilt_aggregate = DefaultAttributes.aggregate_build(aggregate.aggregate_events)
      expect(rebuilt_aggregate.array).to eql ['banana']
    end

  end
end
