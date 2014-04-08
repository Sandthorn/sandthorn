require 'spec_helper'

class AnAggregate 
	include Sandthorn::AggregateRoot
end

describe Sandthorn do
	before(:each) { AnAggregate.new.save }
	let(:events) { Sandthorn.get_events aggregate_types: [AnAggregate] }
	context "when getting events using Sandthorn.get_events for an aggregate type" do
		it "should return raw events" do
			expect(events).to_not be_empty
		end
	end
end