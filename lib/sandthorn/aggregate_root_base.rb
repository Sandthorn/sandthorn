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
        aggregate_attribute_deltas = get_delta
        
        unless aggregate_attribute_deltas.empty?
          method_name = caller_locations(1,1)[0].label.gsub("block in ", "")
          increase_current_aggregate_version!
          data = {:method_name => method_name, :method_args => args, :attribute_deltas => aggregate_attribute_deltas}
          data.merge!({trace: @aggregate_trace_information}) unless @aggregate_trace_information.nil? || @aggregate_trace_information.empty?
          @aggregate_events << ({:aggregate_version => @aggregate_current_event_version, :event_name => method_name, :event_args => data})
        end
        self
      end

      alias :record_event :commit
      
      # def aggregate_trace args
      #   @aggregate_trace_information = args
      #   yield self
      #   @aggregate_trace_information = nil
      # end

      module ClassMethods

        # @@aggregate_trace_information = nil
        # def aggregate_trace args
        #   @@aggregate_trace_information = args
        #   @aggregate_trace_information = args
        #   yield self
        #   @@aggregate_trace_information = nil
        #   @aggregate_trace_information = nil
        # end

        def all
          aggregate_id_list = Sandthorn.get_aggregate_list_by_typename(self.name)
          find aggregate_id_list
        end

        def find id
          return aggregate_find id unless id.respond_to?(:each)
          return id.map { |e| aggregate_find e }
        end

        def aggregate_find aggregate_id
          class_name = self.respond_to?(:name) ? self.name : self.class # to be able to extend a string for example.
          events = Sandthorn.get_aggregate(aggregate_id, class_name)
          raise Sandthorn::Errors::AggregateNotFound unless events and !events.empty?

          transformed_events = events.map { |e| e.merge(event_args: Sandthorn.deserialize(e[:event_data])) }
          aggregate_build transformed_events
        end

        def new *args
          aggregate = super
          aggregate.aggregate_base_initialize
          aggr = aggregate

          #aggregate.aggregate_trace @@aggregate_trace_information do |aggr|
          aggregate.aggregate_initialize
          aggregate.send :set_aggregate_id, Sandthorn.generate_aggregate_id
          aggregate.send :commit, *args
          aggregate
          #end
        end

        def aggregate_build events
          current_aggregate_version = 0
          if first_event_snapshot?(events)
            aggregate = start_build_from_snapshot events 
            current_aggregate_version = aggregate.aggregate_originating_version
            events.shift
          else
            aggregate = start_build_from_new events
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
        def build_instance_vars_from_events events
          events.inject({}) do |instance_vars, event |
            event_args = event[:event_args]
            event_name = event[:event_name]
            attribute_deltas = event_args[:attribute_deltas]
            unless attribute_deltas.nil?
              deltas = attribute_deltas.each_with_object({}) do |delta, acc|
                acc[delta[:attribute_name]] = delta[:new_value]
              end
              instance_vars.merge! deltas
            end
            instance_vars
          end
        end
        def first_event_snapshot? events
          events.first[:event_name].to_sym == :aggregate_set_from_snapshot
        end
        def start_build_from_snapshot events
          snapshot = events.first[:event_args][0]
        end
        def start_build_from_new events
          new_args = events.first[:event_args][:method_args]
          if new_args.nil?
            aggregate = new
          else
            aggregate = new *new_args
          end
          aggregate.send :aggregate_clear_current_event_version!
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
        instance_variables.select { |i| i.to_s=="@aggregate_id" || !i.to_s.start_with?("@aggregate_") }
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
