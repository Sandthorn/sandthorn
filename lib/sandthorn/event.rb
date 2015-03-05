require 'delegate'

module Sandthorn
  class Event < SimpleDelegator
    ATTRS = %i(
      aggregate_id
      aggregate_type
      aggregate_version
      timestamp
      event_name
      event_args
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
      fetch(:event_args, {}).fetch(:attribute_deltas, [])
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

# {"aggregate_type":"SandthornProduct",
#     "aggregate_version":1,
#     "aggregate_id":"62d88e96-c551-4157-a837-1674e3f2698d",
#     "sequence_number":114,
#     "event_name":"new",
#     "timestamp":"2014-08-16 20:02:05 UTC",
#     "event_args":{"method_name":"new",
#     "method_args":[{"name":"Hahah",
#     "price":"50",
#     "stock_status":"outofstock"}],
#     "attribute_deltas":[{"attribute_name":"name",
#     "old_value":null,
# "new_value":"Hahah"},
#     {"attribute_name":"price",
#     "old_value":null,
# "new_value":50},
#     {"attribute_name":"stock_status",
#     "old_value":null,
# "new_value":"outofstock"},
#     {"attribute_name":"active",
#     "old_value":null,
# "new_value":true},
#     {"attribute_name":"on_sale",
#     "old_value":null,
# "new_value":false},
#     {"attribute_name":"aggregate_id",
#     "old_value":null,
# "new_value":"62d88e96-c551-4157-a837-1674e3f2698d"}]}},