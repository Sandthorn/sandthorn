require "forwardable"

module Sandthorn
  class EventStores
    extend Forwardable
    include Enumerable

    def_delegators :stores, :each

    def initialize(stores = nil)
      @store_map = {}
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

    private

    attr_reader :store_map

    def add_initial(store)
      if event_store?(store)
        self.default_store = store
      elsif many_event_stores?(store)
        add_many(store)
      end
    end

    def many_event_stores?(store)
      store.respond_to?(:each_pair)
    end

    def event_store?(store)
      store.respond_to?(:get_events)
    end
  end
end
