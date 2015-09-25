require 'spec_helper'

module Sandthorn
  describe EventStores do
    let(:stores) { EventStores.new }

    before do
      class AnAggregate 
        include Sandthorn::AggregateRoot
      end
    end
    

    describe "#initialize" do
      context "when given a single event_store" do
        it "sets it as the default event store" do
          store = double(get_events: true)
          allow(store).to receive(:get_events)
          stores = EventStores.new(store)
          expect(stores.default_store).to eq(store)
        end
      end

      context "when given number of stores" do
        it "adds them all" do
          stores = {
              default: double,
              other: double
          }
          repo = EventStores.new(stores)
          expect(repo.by_name(:default)).to eq(stores[:default])
          expect(repo.by_name(:other)).to eq(stores[:other])
        end
      end
    end

    describe "enumerable" do
      let(:store) { double }
      let(:other_store) { double }
      it "should respond to each" do
        expect(stores).to respond_to(:each)
      end

      it "should yield each store" do
        stores.add_many(
          foo: store,
          bar: other_store
        )
        expect { |block| stores.each(&block) }.to yield_successive_args(store, other_store)
      end
    end

    describe "#default_store=" do
      it "sets the default" do
        store = double
        stores = EventStores.new
        stores.default_store = store
        expect(stores.default_store).to eq(store)
      end
    end

    describe "#by_name" do
      context "when the store exists" do
        it "returns the store" do
          store = double
          stores.add(:foo, store)
          expect(stores.by_name(:foo)).to eq(store)
        end
      end

      context "when the store does not exist" do
        it "returns the default store" do
          store = double
          stores.default_store = store
          expect(stores.by_name(:unknown)).to eq(store)
        end
      end
    end

    describe "#add" do
      it "adds the store under the given name" do
        store = double
        stores.add(:foo, store)
        expect(stores[:foo]).to eq(store)
      end
    end

    describe "#mapp_aggregate_type_to_event_store" do

      let(:klass) {
        class AnAggregate 
          include Sandthorn::AggregateRoot
        end
      }

      it "mapps the aggregate_type to the event_store" do
        store = double
        stores.add(:foo, store)
        stores.mapp_aggregate_type_to_event_store(klass, :foo)
        expect(klass.event_store).to eq(:foo)
      end
    end

    describe "#mapp_aggregate_types_to_event_store" do

      let(:klass) {
        class AnAggregate 
          include Sandthorn::AggregateRoot
        end
      }

      it "mapps an array of aggregate_types to event_stores" do
        store = double
        stores.add(:foo, store)
        stores.mapp_aggregate_types_to_event_store([{ aggregate_type: klass, event_store: :foo }])
        expect(klass.event_store).to eq(:foo)
      end
    end
  end
end
