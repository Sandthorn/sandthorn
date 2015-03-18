using Sandthorn::Refinements

module Sandthorn
  class FinderProxy
    def initialize(aggregate_type, *args)
      @aggregate_type = aggregate_type
      @args = args
    end

    def find(id)
      if id.respond_to?(:each)
        id.map { |id| aggregate_find(id) }.compact
      else
        aggregate_find(id)
      end
    end

    def find!(id)
      if id.respond_to?(:each)
        id.map { |id| aggregate_find!(id) }.compact
      else
        aggregate_find!(id)
      end
    end

    def aggregate_find(id)
      aggregate_find!(id)
    rescue Errors::AggregateNotFound
      nil
    end

    def aggregate_find!(id)
      @aggregate_type.aggregate_build_to(id.to_id, *@args)
    end

    def all
      ids = Sandthorn.get_aggregate_list_by_type(@aggregate_type)
      find(ids)
    end
  end
end