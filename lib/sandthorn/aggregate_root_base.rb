module Sandthorn
  module AggregateRoot
    module Base
      attr_reader :aggregate_id
      attr_reader :aggregate_events
      attr_reader :aggregate_current_event_version
      attr_reader :aggregate_originating_version
      attr_reader :aggregate_stored_serialized_object
      attr_reader :aggregate_trace_information

      alias_method :id, :aggregate_id

      def aggregate_base_initialize
        @aggregate_current_event_version = 0
        @aggregate_originating_version = 0
        @aggregate_events = []
      end

      def save # rubocop:disable MethodLength
        aggregate_events.each do |event|
          event[:event_data] = Sandthorn.serialize event[:event_args]
          event[:event_args] = nil # Not send extra data over the wire
        end

        unless aggregate_events.empty?
          Sandthorn.save_events(
            aggregate_events,
            aggregate_id,
            self.class
          )
          @aggregate_events = []
          @aggregate_originating_version = @aggregate_current_event_version
        end

        self
      end

      def ==(other)
        other.respond_to?(:aggregate_id) && aggregate_id == other.aggregate_id
      end

      def aggregate_trace(args)
        @aggregate_trace_information = args
        yield self if block_given?
        @aggregate_trace_information = nil
      end

      def commit(*args) # rubocop:disable MethodLength
        aggregate_attribute_deltas = get_delta

        unless aggregate_attribute_deltas.empty?
          method_name = caller_locations(1, 1)[0].label.gsub(/block ?(.*) in /, "")
          increase_current_aggregate_version!

          data = {
            method_name: method_name,
            method_args: args,
            attribute_deltas: aggregate_attribute_deltas
          }
          trace_information = @aggregate_trace_information
          unless trace_information.nil? || trace_information.empty?
            data.merge!(trace: trace_information)
          end

          @aggregate_events << ({
            aggregate_version: @aggregate_current_event_version,
            event_name: method_name,
            event_args: data
          })
        end

        self
      end

      alias_method :record_event, :commit

      module ClassMethods
        @aggregate_trace_information = nil
        def aggregate_trace(args)
          @aggregate_trace_information = args
          yield self
          @aggregate_trace_information = nil
        end

        def event_store(event_store = nil)
          if event_store
            @event_store = event_store
          else
            @event_store
          end
        end

        def all
          aggregate_id_list = Sandthorn.get_aggregate_list_by_type(self)
          find aggregate_id_list
        end

        def find(id)
          return aggregate_find id unless id.respond_to?(:each)
          id.map { |e| aggregate_find e }
        end

        def aggregate_find(aggregate_id) # rubocop:disable AbcSize, MethodLength
          events = Sandthorn.get_aggregate(aggregate_id, self)
          unless events && !events.empty?
            fail Sandthorn::Errors::AggregateNotFound
          end

          if first_event_snapshot?(events)
            transformed_snapshot_event = events.first.merge(event_args: Sandthorn.deserialize_snapshot(events.first[:event_data]))
            events.shift
          end

          transformed_events = events.map do |e|
            e.merge(event_args: Sandthorn.deserialize(e[:event_data]))
          end
          events = [transformed_snapshot_event] + transformed_events
          aggregate_build(events.compact)
        end

        def new(*args)
          super.tap do |aggregate|
            aggregate.aggregate_trace(@aggregate_trace_information) do |aggr|
              aggr.aggregate_base_initialize
              aggr.aggregate_initialize
              aggr.send :set_aggregate_id, Sandthorn.generate_aggregate_id
              aggr.send :commit, *args
              return aggr
            end
          end
        end

        def aggregate_build(events) # rubocop:disable AbcSize, MethodLength
          current_aggregate_version = 0

          if first_event_snapshot?(events)
            aggregate = start_build_from_snapshot events
            current_aggregate_version = aggregate.aggregate_originating_version
            events.shift
          else
            aggregate = create_new_empty_aggregate
          end

          attributes = build_instance_vars_from_events events
          current_aggregate_version = events.last[:aggregate_version] unless events.empty?
          aggregate.send :clear_aggregate_events
          aggregate.send :set_orginating_aggregate_version!, current_aggregate_version
          aggregate.send :set_current_aggregate_version!, current_aggregate_version
          aggregate.send :aggregate_initialize
          aggregate.send :set_instance_variables!, attributes
          aggregate
        end

        private

        def build_instance_vars_from_events(events)
          events.each_with_object({}) do |event, instance_vars|
            event_args = event[:event_args]
            attribute_deltas = event_args[:attribute_deltas]
            next if attribute_deltas.nil?
            deltas = attribute_deltas.each_with_object({}) do |delta, acc|
              acc[delta[:attribute_name]] = delta[:new_value]
            end
            instance_vars.merge! deltas
          end
        end

        def first_event_snapshot?(events)
          events.first[:event_name].to_sym == :aggregate_set_from_snapshot
        end

        def start_build_from_snapshot(events)
          events.first[:event_args][0]
        end

        def create_new_empty_aggregate
          allocate
        end
      end

      private

      def set_instance_variables!(attributes)
        attributes.each_pair do |k, v|
          instance_variable_set "@#{k}", v
        end
      end

      def extract_relevant_aggregate_instance_variables
        instance_variables.select do |variable|
          equals_aggregate_id = variable.to_s == "@aggregate_id"
          does_not_contain_aggregate = !variable.to_s.start_with?("@aggregate_")

          equals_aggregate_id || does_not_contain_aggregate
        end
      end

      def set_orginating_aggregate_version!(aggregate_version)
        @aggregate_originating_version = aggregate_version
      end

      def increase_current_aggregate_version!
        @aggregate_current_event_version += 1
      end

      def set_current_aggregate_version!(aggregate_version)
        @aggregate_current_event_version = aggregate_version
      end

      def clear_aggregate_events
        @aggregate_events = []
      end

      def aggregate_clear_current_event_version!
        @aggregate_current_event_version = 0
      end

      def set_aggregate_id(aggregate_id)
        @aggregate_id = aggregate_id
      end
    end
  end
end
