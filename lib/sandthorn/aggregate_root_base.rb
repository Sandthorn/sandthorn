module Sandthorn
  module AggregateRoot
    module Base

      attr_reader :aggregate_id
      attr_reader :aggregate_events
      attr_reader :aggregate_current_event_version
      attr_reader :aggregate_originating_version
      attr_reader :aggregate_stored_serialized_object

      alias :id :aggregate_id


      def aggregate_base_initialize
        @aggregate_current_event_version = 0
        @aggregate_originating_version = 0
        @aggregate_events = []
      end

      def save
        aggregate_events.each do |event|
          event[:event_data] = Sandthorn.serialize event[:event_args]
          event[:event_args] = nil #Not send extra data over the wire
        end
        unless aggregate_events.empty?
          Sandthorn.save_events( aggregate_events, aggregate_originating_version, aggregate_id, self.class.name)
          @aggregate_events = []
          @aggregate_originating_version = @aggregate_current_event_version
        end
        self
      end

      def commit *args
        increase_current_aggregate_version!
        method_name = caller[0][/\`.*\'/][1..-2]
        aggregate_attribute_deltas = get_delta
        
        unless aggregate_attribute_deltas.empty?
          data = {:method_name => method_name, :method_args => args, :attribute_deltas => aggregate_attribute_deltas}
          data.merge!({trace: @aggregate_trace_information}) unless @aggregate_trace_information.nil? || @aggregate_trace_information.empty?
          @aggregate_events << ({:aggregate_version => @aggregate_current_event_version, :event_name => method_name, :event_args => data})
        end
        self
      end

      alias :record_event :commit
      

      def all
      end

      def aggregate_trace args
        @aggregate_trace_information = args
        yield self
        @aggregate_trace_information = nil
      end

      module ClassMethods

        @@aggregate_trace_information = nil
        def aggregate_trace args
          @@aggregate_trace_information = args
          @aggregate_trace_information = args
          yield self
          @@aggregate_trace_information = nil
          @aggregate_trace_information = nil
        end

        def find aggregate_id
          class_name = self.respond_to?(:name) ? self.name : self.class # to be able to extend a string for example.
          events = Sandthorn.get_aggregate(aggregate_id, class_name)
          raise Sandthorn::Errors::AggregateNotFound unless events and !events.empty?

          transformed_events = events.map { |e| e.merge(event_args: Sandthorn.deserialize(e[:event_data])) }
          aggregate_build transformed_events
        end

        def new *args
          aggregate = super
          aggregate.aggregate_base_initialize

          aggregate.aggregate_trace @@aggregate_trace_information do |aggr|
            aggr.aggregate_initialize
            aggr.send :set_aggregate_id, Sandthorn.generate_aggregate_id
            aggr.send :commit, *args
            return aggr
          end
        end

        def aggregate_build events
          first_event = events.first()
          current_aggregate_version = 0
          if first_event[:event_name] == "aggregate_set_from_snapshot"
            aggregate = first_event[:event_args][0]
            current_aggregate_version = aggregate.aggregate_originating_version
            events.shift
          else
            new_args = events.first()[:event_args][:method_args]

            if new_args.nil?
              aggregate = new
            else
              aggregate = new *new_args
            end
            aggregate.send :aggregate_clear_current_event_version!
          end

          attributes = {}
          events.each do |event|
            event_args = event[:event_args]
            event_name = event[:event_name]

            next if event_name == "aggregate_set_from_snapshot"
            next if event_name == "instance_extended_as_aggregate"

            attribute_deltas = event_args[:attribute_deltas]

            unless event[:aggregate_version].nil?
              current_aggregate_version = event[:aggregate_version]
            end

            unless attribute_deltas.nil?
              deltas = attribute_deltas.each_with_object({}) do |delta, acc|
                acc[delta[:attribute_name]] = delta[:new_value]
              end

              attributes.merge! deltas
            end
          end
          aggregate.send :clear_aggregate_events
          aggregate.send :set_orginating_aggregate_version!, current_aggregate_version
          aggregate.send :set_current_aggregate_version!, current_aggregate_version
          aggregate.send :set_instance_variables!, attributes
          aggregate
        end
      end

      private

      def set_instance_variables! attributes
        attributes.each_pair do |k,v|
          self.instance_variable_set "@#{k}", v
        end
      end

      def extract_relevant_aggregate_instance_variables
        instance_variables.select do |i|
          i.to_s != "@hashy" && (!i.to_s.start_with?("@aggregate_") || i.to_s == "@aggregate_id")
        end
      end

      def set_orginating_aggregate_version! aggregate_version
        @aggregate_originating_version = aggregate_version
      end

      def increase_current_aggregate_version!
        @aggregate_current_event_version += 1
      end

      def set_current_aggregate_version! aggregate_version
        @aggregate_current_event_version = aggregate_version
      end

      def clear_aggregate_events
        @aggregate_events = []
        @aggregate_attribute_deltas = []
      end

      def aggregate_clear_current_event_version!
        @aggregate_current_event_version = 0
      end

      def set_aggregate_id aggregate_id
        @aggregate_id = aggregate_id
      end

    end
  end
end
