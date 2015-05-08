require "spec_helper"
require "date"

class Hello
  attr_reader :foo_bar
  attr_accessor :change_me

  def initialize(foo_bar)
    @foo_bar = foo_bar
  end

  def set_foo_bar(value)
    @foo_bar = value
  end
end

class IAmComplex
  include Sandthorn::AggregateRoot
  attr_reader :a_date
  attr_reader :hello

  def set_hello!(hello)
    set_hello_event hello
  end

  def set_foo_bar_on_hello(value)
    @hello.set_foo_bar value
    commit value
  end

  def initialize(date)
    @a_date = date
  end

  private

  def set_hello_event(hello)
    @hello = hello
    commit hello
  end
end

describe "when using complex types in events" do
  before(:each) do
    aggr = IAmComplex.new Date.new 2012, 01, 20
    aggr.set_hello! Hello.new "foo"
    @events = aggr.aggregate_events
  end
  it "should be able to build from events" do
    aggr = IAmComplex.aggregate_build @events
    expect(aggr.a_date).to be_a(Date)
    expect(aggr.hello).to be_a(Hello)
  end

  it "should detect hello changing" do
    aggr = IAmComplex.aggregate_build @events
    hello = aggr.hello
    hello.change_me = ["Fantastisk"]
    aggr.set_hello! hello
    hello.change_me << "Otroligt"
    aggr.set_hello! hello
    builded = IAmComplex.aggregate_build aggr.aggregate_events
    expect(builded.hello.change_me).to include "Fantastisk"
    expect(builded.hello.change_me).to include "Otroligt"
  end

  it "should detect foo_bar chaning in hello" do
    aggr = IAmComplex.aggregate_build @events
    aggr.set_foo_bar_on_hello "morgan"
    builded = IAmComplex.aggregate_build aggr.aggregate_events
    expect(builded.hello.foo_bar).to eql "morgan"
  end
end
