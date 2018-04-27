require 'delegate'

module Sandthorn
  class Event < SimpleDelegator
    ATTRS = %i(
      aggregate_id
      aggregate_type
      aggregate_version
      timestamp
      event_name
      event_data
      event_metadata
      method_args
      trace
    )

    ATTRS.each do |attr|
      define_method(attr) do
        self[attr]
      end
    end

    def new_values
      @changed_attributes ||= build_new_values
    end

    def attribute_deltas
      @attribute_deltas ||= build_deltas
    end

    private

    def build_deltas
      raw_deltas.map { |key, value|
        d = {}
        d[:attribute_name] = key
        d[:old_value] = value[:old_value]
        d[:new_value] = value[:new_value]
        AttributeDelta.new(d) 
      }
    end

    def build_new_values
      deltas = {}
      attribute_deltas.each do |delta|
        deltas[delta[:attribute_name]] = delta[:new_value]
      end
      return deltas
    end

    def raw_deltas
      fetch(:event_data, {})
    end

    class AttributeDelta < SimpleDelegator
      ATTRS = %i(
        attribute_name
        old_value
        new_value
      )

      ATTRS.each do |attr|
        define_method(attr) do
          self[attr]
        end
      end
    end
  end
end
