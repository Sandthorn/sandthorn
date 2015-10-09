require 'spec_helper'

class InitChange
  include Sandthorn::AggregateRoot
  attr_reader :foo
  def initialize foo: nil
    @foo = foo
  end
end
def change_init
  InitChange.class_eval do
    define_method :initialize, lambda { @foo = :foo }
  end
end


describe "when the initialize-method changes" do

  it "should be possible to replay anyway" do
    aggregate = InitChange.new foo: :bar
    events = aggregate.aggregate_events
    change_init
    with_change = InitChange.new
    expect(with_change.foo).to eql :foo
    replayed = InitChange.aggregate_build(events)
    expect(replayed.foo).to eql :bar
  end
end

describe "when a new attribute is added with a default value" do

  it "should set the new attribute with its default value on already created aggregates" do
    aggregate = InitChange.new
    events = aggregate.aggregate_events
    
    class InitChange
      include Sandthorn::AggregateRoot
      attr_reader :foo, :bar
      def initialize foo: nil
        @foo = foo
        @bar = []
      end
    end

    with_change = InitChange.new foo: :foo
    expect(with_change.bar).to eql([])

    replayed = InitChange.aggregate_build(events)
    expect(replayed.bar).to eql([])

  end

end
