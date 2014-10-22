module Sandthorn
  class EventStores

    def initialize(stores = nil)
      @stores = Hash.new
      add_initial(stores)
    end

    def add(name, event_store)
      stores[name] = event_store
    end
    alias_method :[]=, :add

    def add_many(stores)
      stores.each_pair do |name, store|
        add(name, store)
      end
    end

    def by_name(name)
      stores[name] || default_store
    end
    alias_method :[], :by_name

    def default_store
      stores.fetch(:default)
    end

    def default_store=(store)
      stores[:default] = store
    end

    private

    attr_reader :stores

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