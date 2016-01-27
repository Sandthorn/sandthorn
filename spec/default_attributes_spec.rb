require 'spec_helper'

class DefaultAttributes
  include Sandthorn::AggregateRoot
  def initialize 
  end
end
def add_default_attributes
  DefaultAttributes.class_eval do
    attr_reader :array
    define_method :default_attributes, lambda { @array = [] }
  end
end
describe "when the initialize-method changes" do
  it "should be possible to replay anyway" do
    aggregate = DefaultAttributes.new 
    events = aggregate.aggregate_events
    add_default_attributes
    with_change = DefaultAttributes.new
    expect(with_change.array).to eql []
    replayed = DefaultAttributes.aggregate_build(events)
    expect(replayed.array).to eql []
  end
end
