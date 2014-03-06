require "dirty_hashy"
require "sandthorn/aggregate_root_base"

module Sandthorn
  module AggregateRoot
    module DirtyHashy
      include Sandthorn::AggregateRoot::Base

      def self.included(base)
        base.extend(Sandthorn::AggregateRoot::Base::ClassMethods)
      end

      def aggregate_initialize
        @hashy = ::DirtyHashy.new
      end

      def get_delta
        extract_relevant_aggregate_instance_variables.each do |var|
          @hashy[var.to_s.delete("@")] = self.instance_variable_get("#{var}")
        end
        aggregate_attribute_deltas = []
        @hashy.changes.each do |attribute|
          aggregate_attribute_deltas << { :attribute_name => attribute[0], :old_value => attribute[1][0], :new_value => attribute[1][1]}
        end
        aggregate_attribute_deltas
      end

    end
  end
end