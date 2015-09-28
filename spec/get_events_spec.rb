require 'spec_helper'

class AnAggregate 
	include Sandthorn::AggregateRoot
end

class AnotherAggregate
  include Sandthorn::AggregateRoot
  event_store :should_override_this
end

describe Sandthorn do

  describe "::get_events" do
    context "when getting events using Sandthorn.get_events for an aggregate type" do
      before do
        AnAggregate.new.save
      end
      let(:events) { Sandthorn.get_events aggregate_types: [AnAggregate] }
      it "should return events" do
        expect(events).to_not be_empty
      end
    end

    context "when there are many event stores configured" do
      before do
        setup_secondary_db
      end

      let!(:agg) do
        AnAggregate.new.save
      end

      let!(:other_agg) do
        AnotherAggregate.new.save
      end

      shared_examples(:default_event_store) do
        it "returns events from the default event store" do
          events = Sandthorn.get_events
          expect(events).to all(have_aggregate_type("AnAggregate"))
        end
      end

      context "when no explicit event store is used" do
        it_behaves_like :default_event_store
      end

      context "when given an explicit event store" do
        context "and that event store exists" do
          it "returns events from the chosen event store" do
            events = Sandthorn.get_events(event_store: :other)
            expect(events).to all(have_aggregate_type("AnotherAggregate"))
          end
        end

        context "and that event store does not exist" do
          it_behaves_like :default_event_store
        end
      end

    end
  end

  def setup_secondary_db
    url = "sqlite://spec/db/other_db.sqlite3"
    driver = SandthornDriverSequel.driver_from_url(url: url)
    Sandthorn.event_stores.add(:other, driver)
    Sandthorn.event_stores.map_types(other: [AnotherAggregate])
    migrator = SandthornDriverSequel::Migration.new url: url
    SandthornDriverSequel.migrate_db url: url
    migrator.send(:clear_for_test)
  end
end