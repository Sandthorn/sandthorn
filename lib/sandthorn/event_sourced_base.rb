module Sandthorn
  module EventSourced
    module Base

      attr_reader :id
      attr_reader :events
      attr_reader :current_event_version
      attr_reader :originating_version
      attr_reader :aggregate_stored_serialized_object #USED?
      attr_reader :trace_information

      alias :aggregate_id :id

      def base_initialize
        @current_event_version = 0
        @originating_version = 0
        @events = []
      end

      def save
        events.each do |event|
          event[:event_data] = Sandthorn.serialize event[:event_args]
          event[:event_args] = nil #Not send extra data over the wire
        end

        unless events.empty?
          Sandthorn.save_events(
            events,
            id,
            self.class
          )
          @events = []
          @originating_version = @current_event_version
        end

        self
      end

      def ==(other)
        other.respond_to?(:id) && id == other.id
      end

      def trace args
        @trace_information = args
        yield self if block_given?
        @trace_information = nil
      end

      def commit *args
        attribute_deltas = get_delta

        unless attribute_deltas.empty?
          method_name = caller_locations(1,1)[0].label.gsub(/block ?(.*) in /, "")
          increase_current_version!

          data = {
            method_name: method_name,
            method_args: args,
            attribute_deltas: attribute_deltas
          }
          trace_information = @trace_information
          unless trace_information.nil? || trace_information.empty?
            data.merge!({ trace: trace_information })
          end

          @events << ({
            aggregate_version: @current_event_version,
            event_name: method_name,
            event_args: data
          })
        end

        self
      end

      alias :record_event :commit

      module ClassMethods

        @@event_sourced_attributes = []
        def event_sourced_attributes=(array)
          @@event_sourced_attributes = array.map do |attribute|
            "@#{attribute}"
          end
          @@event_sourced_attributes << "@id" #To be removed from here at some point, I hope
        end

        def event_sourced_attributes
          @@event_sourced_attributes  
        end

        @@trace_information = nil
        def trace args
          @@trace_information = args
          yield self
          @@trace_information = nil
        end

        def event_store(event_store = nil)
          if event_store
            @event_store = event_store
          else
            @event_store
          end
        end

        def all
          id_list = Sandthorn.get_aggregate_list_by_type(self)
          find id_list
        end

        def find id
          return aggregate_find id unless id.respond_to?(:each)
          return id.map { |e| aggregate_find e }
        end

        def aggregate_find id
          events = Sandthorn.get_aggregate(id, self)
          unless events && !events.empty?
            raise Sandthorn::Errors::AggregateNotFound
          end
          
          if first_event_snapshot?(events)
            transformed_snapshot_event = events.first.merge(event_args: Sandthorn.deserialize_snapshot(events.first[:event_data]))
            events.shift
          end

          transformed_events = events.map do |e|
            e.merge(event_args: Sandthorn.deserialize(e[:event_data]))
          end
          aggregate_build ([transformed_snapshot_event] + transformed_events).compact
        end

        def new *args
          super.tap do |aggregate|
            aggregate.trace @@trace_information do |aggr|
              aggr.base_initialize
              aggr.aggregate_initialize event_sourced_attributes
              aggr.send :set_id, Sandthorn.generate_id
              aggr.send :commit, *args
              return aggr
            end
          end
        end

        def aggregate_build events
          current_aggregate_version = 0

          if first_event_snapshot?(events)
            aggregate = start_build_from_snapshot events
            current_aggregate_version = aggregate.originating_version
            events.shift
          else
            aggregate = create_new_empty_aggregate
          end

          attributes = build_instance_vars_from_events events
          current_aggregate_version = events.last[:aggregate_version] unless events.empty?
          aggregate.send :clearevents_
          aggregate.send :set_orginating_aggregate_version!, current_aggregate_version
          aggregate.send :set_current_aggregate_version!, current_aggregate_version
          aggregate.send :aggregate_initialize, event_sourced_attributes
          aggregate.send :set_instance_variables!, attributes
          aggregate
        end

        private

        def build_instance_vars_from_events events
          events.each_with_object({}) do |event, instance_vars|
            event_args = event[:event_args]
            event_name = event[:event_name]
            attribute_deltas = event_args[:attribute_deltas]
            unless attribute_deltas.nil?
              deltas = attribute_deltas.each_with_object({}) do |delta, acc|
                acc[delta[:attribute_name]] = delta[:new_value]
              end
              instance_vars.merge! deltas
            end
          end
        end

        def first_event_snapshot? events
          events.first[:event_name].to_sym == :aggregate_set_from_snapshot
        end

        def start_build_from_snapshot events
          snapshot = events.first[:event_args][0]
        end

        def create_new_empty_aggregate
          allocate
        end
      end

      private

      def set_instance_variables! attributes
        attributes.each_pair do |k,v|
          self.instance_variable_set "@#{k}", v
        end
      end

      def set_orginating_aggregate_version! aggregate_version
        @originating_version = aggregate_version
      end

      def increase_current_version!
        @current_event_version += 1
      end

      def set_current_aggregate_version! aggregate_version
        @current_event_version = aggregate_version
      end

      def clearevents_
        @events = []
      end

      def aggregate_clear_current_event_version!
        @current_event_version = 0
      end

      def set_id id
        @id = id
      end

    end
  end
end
