module Sandthorn
  class AggregateBuilder
    def initialize(aggregate_klass)
      @aggregate_klass  = aggregate_klass
    end

    def build(aggregate_id, sequence_number: nil)
      aggregate_id = aggregate_id.to_s
      if sequence_number
        build_from_sequence_number(aggregate_id, sequence_number)
      else
        build_from_events(all_events(aggregate_id))
      end
    end

    def build_from_time(aggregate_id, time)
      build_from_events(events_up_to_time(aggregate_id, time))
    end

    def build_from_version(aggregate_id, version)
      build_from_events(events_up_to_version(aggregate_id, version))
    end

    def build_from_sequence_number(aggregate_id, sequence_number)
      build_from_events(events_up_to_sequence_number(aggregate_id, sequence_number))
    end

    def build_from_events(events)
      raise Errors::AggregateNotFound if events.nil? || events.empty?
      events, aggregate = init_aggregate(events)
      events.each do |event|
        if snapshot?(event)
          set_from_snapshot(aggregate, event)
        else
          handle_event(aggregate, event)
        end
      end
      aggregate.send :clear_aggregate_events
      aggregate.send :load_aggregate_stored_instance_variables
      return aggregate
    end

    private

    def init_aggregate(events)
      if snapshot?(events.first)
        init_from_snapshot(events)
      else
        return events, @aggregate_klass.allocate
      end
    end

    def snapshot?(event)
      event[:event_name] == "aggregate_set_from_snapshot"
    end

    def set_from_snapshot(aggregate, event)
      event_args = event[:event_args]
      aggregate.send(:aggregate_set_from_snapshot, *event_args)
      set_aggregate_versions(aggregate, aggregate.aggregate_originating_version)
    end

    def handle_event(aggregate, event)
      event_args        = event[:event_args]
      attribute_deltas  = event_args[:attribute_deltas]
      aggregate_version = event[:aggregate_version]
      set_aggregate_versions(aggregate, aggregate_version)  unless aggregate_version.nil?
      set_aggregate_deltas(aggregate, attribute_deltas)     unless attribute_deltas.nil?
    end

    def set_aggregate_versions(aggregate, aggregate_version)
      aggregate.send :set_orginating_aggregate_version!, aggregate_version
      aggregate.send :set_current_aggregate_version!, aggregate_version
    end

    def set_aggregate_deltas(aggregate, attribute_deltas)
      attribute_deltas.each do |delta|
        aggregate.instance_variable_set delta[:attribute_name], delta[:new_value]
      end
    end

    def init_from_snapshot(events)
      aggregate = events.first[:event_args].first
      events.shift
      return events, aggregate
    end

    def events_up_to_time(aggregate_id, time)
      all_events(aggregate_id).select do |event|
        event[:timestamp] <= time
      end
    end

    def events_up_to_version(aggregate_id, version)
      all_events(aggregate_id).select do |event|
        event[:aggregate_version] <= version
      end
    end

    def events_up_to_sequence_number(aggregate_id, sequence_number)
      all_events(aggregate_id).select do |event|
        event[:sequence_number] <= sequence_number
      end
    end

    def all_events(aggregate_id)
      unpack(Sandthorn.get_aggregate_events(@aggregate_klass, aggregate_id))
    end

    def unpack(events)
      events.map do |e|
        e.merge(event_args: Sandthorn.deserialize(e[:event_data]))
      end
    end
  end
end