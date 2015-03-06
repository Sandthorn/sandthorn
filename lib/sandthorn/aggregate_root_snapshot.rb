module Sandthorn
  module AggregateRootSnapshot
    attr_reader :aggregate_snapshot

    def snapshot
      aggregate_snapshot!
      save_snapshot
      self
    end

    def aggregate_snapshot!
      if @aggregate_events.count > 0
        raise Errors::SnapshotError,
          "Can't take snapshot on object with unsaved events"
      end

      @aggregate_snapshot = {
        event_name: "aggregate_set_from_snapshot",
        event_args: [self],
        aggregate_version: @aggregate_current_event_version
      }
    end

    def save_snapshot
      unless aggregate_snapshot
        raise Errors::SnapshotError, "No snapshot has been created!"
      end
      @aggregate_snapshot[:event_data] = Sandthorn.serialize @aggregate_snapshot[:event_args]
      @aggregate_snapshot[:event_args] = nil
      Sandthorn.save_snapshot @aggregate_snapshot, @aggregate_id
      @aggregate_snapshot = nil
    end
    private
    def aggregate_create_event_when_extended
      self.aggregate_snapshot!
      vars = extract_relevant_aggregate_instance_variables
      vars.each do |var_name|
        value = instance_variable_get var_name
        dump = Marshal.dump(value)
        store_aggregate_instance_variable var_name, dump
      end

      @aggregate_snapshot[:event_data] = Sandthorn
        .serialize aggregate_snapshot[:event_args]

      @aggregate_snapshot[:event_args] = nil
      Sandthorn.save_snapshot aggregate_snapshot, aggregate_id
      @aggregate_snapshot = nil
    end
  end
end
