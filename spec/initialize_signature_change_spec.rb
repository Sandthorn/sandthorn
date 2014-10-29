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
