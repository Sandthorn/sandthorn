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
    end

    def save_snapshot
      Sandthorn.save_snapshot(self)
    end
  end
end
