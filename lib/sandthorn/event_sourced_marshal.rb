module Sandthorn
  module EventSourced
    module Marshal 

      def aggregate_initialize event_sourced_attributes
        @attribute_deltas = []
        @stored_instance_variables = {}
        @instance_variabled = event_sourced_attributes
      end

      def set_instance_variables! attribute
        super attribute
        init_vars = @instance_variabled

        init_vars.each do |attribute_name|
          @stored_instance_variables[attribute_name] =
            ::Marshal.dump(instance_variable_get(attribute_name))
        end
      end

      def get_delta
        deltas = @instance_variabled
        deltas.each { |d| delta_attribute(d) }

        result = @attribute_deltas
        clear_aggregate_deltas
        result
      end

      private

      def delta_attribute attribute_name
        old_dump = @stored_instance_variables[attribute_name]
        new_dump = ::Marshal.dump(instance_variable_get(attribute_name))

        unless old_dump == new_dump
          store_attribute_deltas attribute_name, new_dump, old_dump
          store_aggregate_instance_variable attribute_name, new_dump
        end
      end

      def store_attribute_deltas attribute_name, new_dump, old_dump
        new_value_to_store = ::Marshal.load(new_dump)
        old_value_to_store = old_dump ? ::Marshal.load(old_dump) : nil

        @attribute_deltas << {
          attribute_name: attribute_name.to_s.delete("@"),
          old_value: old_value_to_store,
          new_value: new_value_to_store
        }
      end

      def store_aggregate_instance_variable attribute_name, new_dump
        @stored_instance_variables[attribute_name] = new_dump
      end

      def clear_aggregate_deltas
        @attribute_deltas = []
      end
    end
  end
end
