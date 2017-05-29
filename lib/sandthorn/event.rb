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
      raw_deltas.map { |delta| AttributeDelta.new(delta) }
    end

    def build_new_values
      attribute_deltas.each_with_object({}) do |delta, changed|
        changed[delta.attribute_name.to_sym] = delta.new_value
      end
    end

    def raw_deltas
      fetch(:event_data, {}).fetch(:attribute_deltas, [])
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
