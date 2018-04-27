module Sandthorn
  module AggregateRoot
    module Marshal 

      def aggregate_initialize *args
        @aggregate_attribute_deltas = {}
        @aggregate_stored_instance_variables = {}
      end

      def set_instance_variables! attribute
        super attribute
        init_vars = extract_relevant_aggregate_instance_variables

        init_vars.each do |attribute_name|
          @aggregate_stored_instance_variables[attribute_name] =
            ::Marshal.dump(instance_variable_get(attribute_name))
        end
      end

      def get_delta
        deltas = extract_relevant_aggregate_instance_variables
        deltas.each { |d| delta_attribute(d) }

        result = @aggregate_attribute_deltas
        clear_aggregate_deltas
        result
      end

      private

      def delta_attribute attribute_name
        old_dump = @aggregate_stored_instance_variables[attribute_name]
        new_dump = ::Marshal.dump(instance_variable_get(attribute_name))

        unless old_dump == new_dump
          store_attribute_deltas attribute_name, new_dump, old_dump
          store_aggregate_instance_variable attribute_name, new_dump
        end
      end

      def store_attribute_deltas attribute_name, new_dump, old_dump
        new_value_to_store = ::Marshal.load(new_dump)
        old_value_to_store = old_dump ? ::Marshal.load(old_dump) : nil

        @aggregate_attribute_deltas[attribute_name.to_s.delete("@")] = {
          old_value: old_value_to_store,
          new_value: new_value_to_store
        }
      end

      def store_aggregate_instance_variable attribute_name, new_dump
        @aggregate_stored_instance_variables[attribute_name] = new_dump
      end

      def clear_aggregate_deltas
        @aggregate_attribute_deltas = {}
      end
    end
  end
end
