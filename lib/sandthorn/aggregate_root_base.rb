module Sandthorn
  module AggregateRoot
    module Base

      attr_reader :aggregate_id
      attr_reader :aggregate_events
      attr_reader :aggregate_current_event_version
      attr_reader :aggregate_originating_version
      attr_reader :aggregate_trace_information

      alias :id :aggregate_id
      alias :aggregate_version :aggregate_current_event_version


      def aggregate_base_initialize
        @aggregate_current_event_version = 0
        @aggregate_originating_version = 0
        @aggregate_events = []
      end

      def save
        if aggregate_events.any?
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

      def aggregate_trace args
        @aggregate_trace_information = args
        yield self if block_given?
        @aggregate_trace_information = nil
      end

      def commit *args
        event_name = caller_locations(1,1)[0].label.gsub(/block ?(.*) in /, "")
        commit_with_event_name(event_name, args)
      end

      def default_attributes
        #NOOP
      end

      alias :record_event :commit

      module ClassMethods

        @@aggregate_trace_information = nil
        def aggregate_trace args
          @@aggregate_trace_information = args
          yield self
          @@aggregate_trace_information = nil
        end

        def event_store(event_store = nil)
          if event_store
            @event_store = event_store
          else
            @event_store
          end
        end

        def all
          Sandthorn.all(self).map { |events|
            aggregate_build events
          }
        end

        def find id
          return aggregate_find id unless id.respond_to?(:each)
          return id.map { |e| aggregate_find e }
        end

        def aggregate_find aggregate_id
          events = Sandthorn.find(aggregate_id, self)
          unless events && !events.empty?
            raise Sandthorn::Errors::AggregateNotFound
          end

          aggregate_build events
        end

        def new *args, &block
          aggregate = create_new_empty_aggregate()
          aggregate.aggregate_base_initialize
          aggregate.aggregate_initialize

          aggregate.default_attributes
          aggregate.send :initialize, *args, &block
          aggregate.send :set_aggregate_id, Sandthorn.generate_aggregate_id

          aggregate.aggregate_trace @@aggregate_trace_information do |aggr|
            aggr.send :commit, *args
            return aggr
          end

        end

        def aggregate_build events
          if first_event_snapshot?(events)
            aggregate = events.first[:aggregate]
            events.shift
          else
            aggregate = create_new_empty_aggregate
          end

          if events.any?
            current_aggregate_version = events.last[:aggregate_version]
            aggregate.send :set_orginating_aggregate_version!, current_aggregate_version
            aggregate.send :set_current_aggregate_version!, current_aggregate_version
          end

          attributes = build_instance_vars_from_events events
          aggregate.send :clear_aggregate_events

          aggregate.default_attributes
          aggregate.send :aggregate_initialize

          aggregate.send :set_instance_variables!, attributes
          aggregate
        end



        def stateless_events(*event_names)
          event_names.each do |name|
            define_singleton_method name do |aggregate_id, *args|
              event = build_event(name.to_s, args, [], nil)
              Sandthorn.save_events([event], aggregate_id, self)
              return aggregate_id

            end
          end
        end

        def constructor_events(*event_names)
          event_names.each do |name|
            define_singleton_method name do |*args, &block|

              create_new_empty_aggregate.tap  do |aggregate|
                aggregate.aggregate_base_initialize
                aggregate.aggregate_initialize
                aggregate.send :set_aggregate_id, Sandthorn.generate_aggregate_id
                aggregate.instance_eval(&block) if block
                aggregate.send :commit_with_event_name, name.to_s, args
                return aggregate
              end

            end
            self.singleton_class.class_eval { private name.to_s }
          end
        end

        def events(*event_names)
          event_names.each do |name|
            define_method(name) do |*args, &block|
              block.call() if block
              commit_with_event_name(name.to_s, args)
            end
            private name.to_s
          end
        end

        private

        def build_event name, args, attribute_deltas, aggregate_version, trace_information = nil

          data = {
            method_name: name,
            method_args: args,
            attribute_deltas: attribute_deltas
          }

          unless trace_information.nil? || trace_information.empty?
            data.merge!({ trace: trace_information })
          end

          return {
            aggregate_version: aggregate_version,
            event_name: name,
            event_args: data
          }

        end

        def build_instance_vars_from_events events
          events.each_with_object({}) do |event, instance_vars|
            event_args = event[:event_args]
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
          events.first[:aggregate]
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

      def extract_relevant_aggregate_instance_variables
        instance_variables.select do |variable|
          equals_aggregate_id = variable.to_s == "@aggregate_id"
          does_not_contain_aggregate = !variable.to_s.start_with?("@aggregate_")

          equals_aggregate_id || does_not_contain_aggregate
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
      end

      def aggregate_clear_current_event_version!
        @aggregate_current_event_version = 0
      end

      def set_aggregate_id aggregate_id
        @aggregate_id = aggregate_id
      end

      def commit_with_event_name(event_name, args)
        aggregate_attribute_deltas = get_delta

        increase_current_aggregate_version!
        data = {
          method_name: event_name,
          method_args: args,
          attribute_deltas: aggregate_attribute_deltas
        }
        trace_information = @aggregate_trace_information
        unless trace_information.nil? || trace_information.empty?
          data.merge!({ trace: trace_information })
        end

        @aggregate_events << ({
          aggregate_version: @aggregate_current_event_version,
          event_name: event_name,
          event_args: data
        })

        self
      end

    end
  end
end
