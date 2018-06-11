require "sandthorn/version"
require "sandthorn/errors"
require "sandthorn/aggregate_root"
require "sandthorn/event_stores"
require "sandthorn/snapshot_store"
require 'yaml'
require 'securerandom'

module Sandthorn
  class << self
    extend Forwardable

    def_delegators :configuration, :event_stores
    def_delegators :configuration, :snapshot?
    def_delegators :configuration, :snapshot_store

    def default_event_store
      event_stores.default_store
    end

    def default_event_store=(store)
      event_stores.default_store = store
    end

    def configure
      yield(configuration) if block_given?
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def generate_aggregate_id
      SecureRandom.uuid
    end

    def save_events aggregate_events, aggregate_id, aggregate_type
      event_store_for(aggregate_type).save_events aggregate_events, aggregate_id, *aggregate_type
    end

    def all aggregate_type
      event_store_for(aggregate_type).all(aggregate_type)
    end

    def find aggregate_id, aggregate_type, after_aggregate_version = 0
      event_store_for(aggregate_type).find(aggregate_id, aggregate_type, after_aggregate_version)
    end

    def save_snapshot aggregate
      snapshot_store.save aggregate.aggregate_id, aggregate
    end

    def find_snapshot aggregate_id
      return snapshot_store.find aggregate_id
    end

    def find_event_store(name)
      event_stores.by_name(name)
    end

    private

    def event_store_for(aggregate_type)
      event_store = event_stores.by_name(aggregate_type.event_store).tap do |store|
        yield(store) if block_given?
      end
    end

    def missing_key(key)
      raise ArgumentError, "missing keyword: #{key}"
    end

    class Configuration
      extend Forwardable

      def_delegators :default_store, :event_stores, :default_store=

      def initialize
        yield(self) if block_given?
      end

      def event_stores
        @event_stores ||= EventStores.new
      end

      def event_store=(store)
        @event_stores = EventStores.new(store)
      end

      def map_types= data
        @event_stores.map_types data
      end

      def snapshot_store
        @snapshot_store ||= SnapshotStore.new
      end

      def snapshot_types= aggregate_types
        aggregate_types.each do |aggregate_type|
          aggregate_type.snapshot(true)
        end
      end

      alias_method :event_stores=, :event_store=
    end
  end
end
