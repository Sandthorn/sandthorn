require "sandthorn/version"
require "sandthorn/errors"
require "sandthorn/event"
require "sandthorn/aggregate_root"
require "sandthorn/event_stores"
require 'yaml'
require 'securerandom'

module Sandthorn
  class << self
    extend Forwardable

    def_delegators :configuration, :event_stores

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

    def serialize data
      #Marshal.dump(data)
      YAML::dump(data)
      #Oj.dump(data)
      #MessagePack.pack(data, symbolize_keys: true)
    end

    def deserialize data
      #Marshal.load(data)
      YAML::load(data)
      #Oj.load(data)
      #MessagePack.unpack(data, symbolize_keys: true)
    end

    def generate_aggregate_id
      SecureRandom.uuid
    end

    def get_aggregate_events aggregate_id, aggregate_type
      event_store_for(aggregate_type).get_aggregate_events aggregate_id, aggregate_type
    end

    def save_events aggregate_events, originating_aggregate_version, aggregate_id, aggregate_type
      event_store_for(aggregate_type).save_events aggregate_events, originating_aggregate_version, aggregate_id, *aggregate_type
    end

    def get_aggregate aggregate_id, aggregate_type
      event_store_for(aggregate_type).get_aggregate aggregate_id, aggregate_type
    end

    def save_snapshot aggregate_snapshot, aggregate_id, aggregate_type
      event_store_for(aggregate_type).save_snapshot aggregate_snapshot, aggregate_id, aggregate_type
    end

    def get_aggregate_list_by_type aggregate_type
      event_store_for(aggregate_type).get_aggregate_list_by_typename aggregate_type
    end

    def get_events event_store: :default, aggregate_types: [], take: 0, after_sequence_number: 0
      event_store = find_event_store(event_store)
      events = event_store.get_events aggregate_types: aggregate_types, take: take, after_sequence_number: after_sequence_number
      events.map do |event|
        event[:event_args] = deserialize event[:event_data]
        event.delete(:event_data)
        Event.new(event)
      end
    end

    def obsolete_snapshots type_names: [], min_event_distance: 0
      obsolete = event_stores.flat_map { |event_store| event_store.obsolete_snapshots(class_names: type_names, max_event_distance: min_event_distance) }
      obsolete.map do |single_obsolete|
        type = Kernel.const_get single_obsolete[:aggregate_type]
        aggregate = type.aggregate_find(single_obsolete[:aggregate_id]).tap do |agg|
          yield agg if block_given?
        end
      end
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
      alias_method :event_stores=, :event_store=
    end
  end
end
