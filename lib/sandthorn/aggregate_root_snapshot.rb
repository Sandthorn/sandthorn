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
        raise Errors::SnapshotError.new, 
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
        raise Errors::SnapshotError.new "No snapshot has been created!"
      end

      @aggregate_snapshot[:event_data] = Sandthorn
        .serialize aggregate_snapshot[:event_args]

      @aggregate_snapshot[:event_args] = nil
      Sandthorn.save_snapshot aggregate_snapshot, aggregate_id, self.class.name
      @aggregate_snapshot = nil
    end
  end
end
