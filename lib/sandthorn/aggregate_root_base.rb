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

        Sandthorn.save_snapshot self if self.class.snapshot

        self
      end

      def ==(other)
        other.respond_to?(:aggregate_id) && aggregate_id == other.aggregate_id
      end

      def unsaved_events?
        aggregate_events.any?
      end

      def aggregate_trace args
        @aggregate_trace_information = args
        yield self if block_given?
        @aggregate_trace_information = nil
      end

      def commit
        event_name = caller_locations(1,1)[0].label.gsub(/block ?(.*) in /, "")
        commit_with_event_name(event_name)
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

        def snapshot(value = nil)
          if value
            @snapshot = value
          else
            @snapshot
          end
        end

        def all
          Sandthorn.all(self).map { |events|
            aggregate_build events, nil
          }
        end

        def find id
          return aggregate_find id unless id.respond_to?(:each)
          return id.map { |e| aggregate_find e }
        end

        def aggregate_find aggregate_id
          begin
            aggregate_from_snapshot = Sandthorn.find_snapshot(aggregate_id) if self.snapshot
            current_aggregate_version = aggregate_from_snapshot.nil? ? 0 : aggregate_from_snapshot.aggregate_current_event_version
            events = Sandthorn.find(aggregate_id, self, current_aggregate_version)
            if aggregate_from_snapshot.nil? && events.empty?
              raise Errors::AggregateNotFound
            end

            return aggregate_build events, aggregate_from_snapshot
          rescue Exception
            raise Errors::AggregateNotFound
          end
            
        end

        def new *args, &block
          aggregate = create_new_empty_aggregate()
          aggregate.aggregate_base_initialize
          aggregate.aggregate_initialize

          aggregate.default_attributes
          aggregate.send :initialize, *args, &block
          aggregate.send :set_aggregate_id, Sandthorn.generate_aggregate_id

          aggregate.aggregate_trace @@aggregate_trace_information do |aggr|
            aggr.send :commit
            return aggr
          end

        end

        def aggregate_build events, aggregate_from_snapshot = nil
          aggregate = aggregate_from_snapshot || create_new_empty_aggregate

          if events.any?
            current_aggregate_version = events.last[:aggregate_version]
            aggregate.send :set_orginating_aggregate_version!, current_aggregate_version
            aggregate.send :set_current_aggregate_version!, current_aggregate_version
            aggregate.send :set_aggregate_id, events.first.fetch(:aggregate_id)
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
              event = build_stateless_event(aggregate_id, name.to_s, args)
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
                aggregate.send :commit_with_event_name, name.to_s
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
              commit_with_event_name(name.to_s)
            end
            private name.to_s
          end
        end

        private

        def build_stateless_event aggregate_id, name, args = []

          deltas = {}
          args.first.each do |key, value|
            deltas[key.to_sym] = { old_value: nil, new_value: value }
          end unless args.empty?

          return {
            aggregate_version: nil,
            aggregate_id: aggregate_id,
            event_name: name,
            event_data: deltas,
            event_metadata: nil
          }

        end

        def build_instance_vars_from_events events
          events.each_with_object({}) do |event, instance_vars|
            attribute_deltas = event[:event_data]
            unless attribute_deltas.nil?
              deltas = {}
              attribute_deltas.each do |key, value|
                deltas[key] = value[:new_value]
              end
              instance_vars.merge! deltas
            end
          end
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
           !variable.to_s.start_with?("@aggregate_")
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

      def commit_with_event_name(event_name)
        increase_current_aggregate_version!

        @aggregate_events << ({
          aggregate_version: @aggregate_current_event_version,
          aggregate_id: @aggregate_id,
          event_name: event_name,
          event_data: get_delta(),
          event_metadata: @aggregate_trace_information
        })

        self
      end

    end
  end
end
