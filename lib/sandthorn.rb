require "sandthorn/version"
require "sandthorn/errors"
require "sandthorn/event"
require "sandthorn/aggregate_root"
require "sandthorn/event_stores"
require "yaml"
require "securerandom"

module Sandthorn
  class << self
    extend Forwardable

    def_delegators :configuration, :event_stores, :serialize, :deserialize, :serialize_snapshot, :deserialize_snapshot

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

    def get_aggregate_events aggregate_type, aggregate_id
      event_store_for(aggregate_type).get_aggregate_events aggregate_id
    end

    def save_events aggregate_events, aggregate_id, aggregate_type
      event_store_for(aggregate_type).save_events aggregate_events, aggregate_id, *aggregate_type
    end

    def get_aggregate aggregate_id, aggregate_type
      event_store_for(aggregate_type).get_aggregate_events_from_snapshot aggregate_id
    end

    def save_snapshot(
        aggregate_type: missing_key(:aggregate_type),
        aggregate_snapshot: missing_key(:aggregate_snapshot),
        aggregate_id: missing_key(:aggregate_id)
    )
      event_store_for(aggregate_type).save_snapshot(aggregate_snapshot, aggregate_id)
    end

    def get_aggregate_list_by_type aggregate_type
      event_store_for(aggregate_type).get_aggregate_ids(aggregate_type: aggregate_type)
    end

    def get_events(event_store: :default, aggregate_types: [], take: 0, after_sequence_number: 0)
      event_store = find_event_store(event_store)
      events = event_store.get_events aggregate_types: aggregate_types, take: take, after_sequence_number: after_sequence_number
      events.map do |event|
        event[:event_args] = deserialize event[:event_data]
        event.delete(:event_data)
        Event.new(event)
      end
    end

    def obsolete_snapshots type_names: [], min_event_distance: 0
      obsolete = event_stores.flat_map { |event_store| event_store.obsolete_snapshots(aggregate_types: type_names, max_event_distance: min_event_distance) }
      obsolete.map do |single_obsolete|
        type = Kernel.const_get single_obsolete[:aggregate_type]
        type.aggregate_find(single_obsolete[:aggregate_id]).tap do |agg|
          yield agg if block_given?
        end
      end
    end

    def find_event_store(name)
      event_stores.by_name(name)
    end

    private

    def event_store_for(aggregate_type)
      event_stores.by_name(aggregate_type.event_store).tap do |store|
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

      def serializer=(block)
        @serializer = block if block.is_a? Proc
      end

      def deserializer=(block)
        @deserializer = block if block.is_a? Proc
      end

      def serializer
        @serializer || default_serializer
      end

      def deserializer
        @deserializer || default_deserializer
      end

      def default_serializer
        -> (data) { YAML.dump(data) }
      end

      def default_deserializer
        -> (data) { YAML.load(data) }
      end

      def serialize(data)
        serializer.call(data)
      end

      def deserialize(data)
        deserializer.call(data)
      end

      def snapshot_serializer=(block)
        @snapshot_serializer = block if block.is_a? Proc
      end

      def snapshot_deserializer=(block)
        @snapshot_deserializer = block if block.is_a? Proc
      end

      def snapshot_serializer
        @snapshot_serializer || default_serializer
      end

      def snapshot_deserializer
        @snapshot_deserializer || default_deserializer
      end

      def serialize_snapshot(data)
        snapshot_serializer.call(data)
      end

      def deserialize_snapshot data
        snapshot_deserializer.call(data)
      end

      alias_method :event_stores=, :event_store=
    end
  end
end
