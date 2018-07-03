module Sandthorn
  class ApplicationSnapshotStore
  	def initialize
      @store = Hash.new
    end

    attr_reader :store

    def save aggregate_id, aggregate
      @store[aggregate_id] = aggregate
    end

    def find aggregate_id
      @store[aggregate_id]
    end
  end
end
