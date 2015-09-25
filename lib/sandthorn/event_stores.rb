require 'forwardable'

module Sandthorn
  class EventStores
    extend Forwardable
    include Enumerable

    def_delegators :stores, :each

    def initialize(stores = nil)
      @store_map = Hash.new
      add_initial(stores)
    end

    def add(name, event_store)
      store_map[name] = event_store
    end
    alias_method :[]=, :add

    def add_many(stores)
      stores.each_pair do |name, store|
        add(name, store)
      end
    end

    def by_name(name)
      store_map[name] || default_store
    end
    alias_method :[], :by_name

    def default_store
      store_map.fetch(:default)
    end

    def default_store=(store)
      store_map[:default] = store
    end

    def stores
      store_map.values
    end

    def map_aggregate_type_to_event_store(aggregate_type, event_store)
      aggregate_type.event_store(event_store)
    end

    def map_aggregate_types_to_event_store(aggregate_types = [], event_store)
      aggregate_types.each do |aggregate_type|
        map_aggregate_type_to_event_store(aggregate_type, event_store)
      end
    end

    private

    attr_reader :store_map

    def add_initial(store)
      if is_event_store?(store)
        self.default_store = store
      elsif is_many_event_stores?(store)
        add_many(store)
      end
    end

    def is_many_event_stores?(store)
      store.respond_to?(:each_pair)
    end

    def is_event_store?(store)
      store.respond_to?(:get_events)
    end

  end
end