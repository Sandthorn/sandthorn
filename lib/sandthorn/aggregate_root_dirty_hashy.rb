require "dirty_hashy"
require "sandthorn/aggregate_root_base"

module Sandthorn
  module AggregateRoot
    module DirtyHashy
      include Sandthorn::AggregateRoot::Base

      def self.included(base)
        base.extend(Sandthorn::AggregateRoot::Base::ClassMethods)
      end

      def aggregate_initialize *args
        @hashy = ::DirtyHashy.new
      end

      def set_instance_variables! attribute
        super attribute

        extract_relevant_aggregate_instance_variables.each do |var|
          next if var.to_s == "@hashy"
          @hashy[var.to_s.delete("@")] = self.instance_variable_get("#{var}")
        end
        @hashy.clean_up!
      end

      def get_delta
        extract_relevant_aggregate_instance_variables.each do |var|
          next if var.to_s == "@hashy"
          @hashy[var.to_s.delete("@")] = self.instance_variable_get("#{var}")
        end
        aggregate_attribute_deltas = []
        @hashy.changes.each do |attribute|
          aggregate_attribute_deltas << { :attribute_name => attribute[0], :old_value => attribute[1][0], :new_value => attribute[1][1]}
        end
        @hashy.clean_up!
        aggregate_attribute_deltas
      end

    end
  end
end