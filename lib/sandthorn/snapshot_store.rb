module Sandthorn
  class SnapshotStore
  	def initialize
      @store = Hash.new
    end

    attr_reader :store

    def save key, value
      @store[key] = value
    end

    def find key
      @store[key]
    end
  end
end