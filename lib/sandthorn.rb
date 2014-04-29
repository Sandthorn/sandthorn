require "sandthorn/version"
require "sandthorn/errors"
require "sandthorn/aggregate_root"
require 'yaml'
require 'securerandom'

module Sandthorn
  class << self
    def configuration= configuration
      @configuration = configuration
    end
    def configuration
      @configuration ||= []
    end

    def serialize data
      #Marshal.dump(data)
      YAML::dump(data)
      #Oj.dump(data)
      #MessagePack.pack(data, symbolize_keys: true)
    end

    def deserialize data
      #Marshal.load(data)
      YAML::load(data)
      #Oj.load(data)
      #MessagePack.unpack(data, symbolize_keys: true)
    end

    def generate_aggregate_id
      SecureRandom.uuid
    end

    def get_aggregate_events aggregate_id, class_name
      driver_for(class_name).get_aggregate_events aggregate_id, class_name
    end

    def save_events aggregate_events, originating_aggregate_version, aggregate_id, class_name
      #begin
      driver_for(class_name).save_events aggregate_events, originating_aggregate_version, aggregate_id, *class_name
      #rescue UpptecEventSequelDriver::Errors::WrongAggregateVersionError => sequel_error
      #  raise UpptecEventFramework::Errors::ConcurrencyError.new sequel_error.message
      #end
    end

    def get_aggregate aggregate_id, class_name
      driver_for(class_name).get_aggregate aggregate_id, class_name
    end

    def save_snapshot aggregate_snapshot, aggregate_id, class_name
      driver_for(class_name).save_snapshot aggregate_snapshot, aggregate_id, class_name
    end

    def get_aggregate_list_by_typename class_name
      driver_for(class_name).get_aggregate_list_by_typename class_name
    end

    def get_events aggregate_types: [], take: 0, after_sequence_number: 0
      drivers = drivers_for_aggregate_types type_names: aggregate_types
      raise Sandthorn::Errors::Error.new "Cannot get events from multiple contexts simultaneously, only one single context can be handled at a time." unless drivers.length == 1
      driver = drivers.first
      events = driver.get_events aggregate_types: aggregate_types, take: take, after_sequence_number: after_sequence_number
      events.each do |event|
        event[:event_args] = deserialize event[:event_data]
        event.delete(:event_data)
      end
      events
    end

    def obsolete_snapshots type_names: [], min_event_distance: 0
      drivers = drivers_for_aggregate_types type_names: type_names
      obsolete = drivers.flat_map { |driver| driver.obsolete_snapshots(class_names: type_names, max_event_distance: min_event_distance) }
      yielder = []
      obsolete.each do |single_obsolete|
          type = Kernel.const_get single_obsolete[:aggregate_type]
          aggregate = type.aggregate_find single_obsolete[:aggregate_id]
          if block_given?
            yield aggregate
          else
            yielder << aggregate
          end
      end
      yielder unless block_given?
    end

    private
    def driver_for class_name, &block
      driver = identify_driver_from_class class_name
      block.call(driver) if block_given?
      driver
    end
    def identify_driver_from_class class_name
      matches = configuration.select do |conf|
        r = Regexp.new "^#{conf[:aggregate_pattern]}"
        pattern = class_name.to_s
        conf[:aggregate_pattern].nil? || r.match(pattern)
      end
      raise Sandthorn::Errors::ConfigurationError.new "Aggregate class #{class_name} is not configured for Sandthorn" if matches.empty?
      first_match = matches.first
      first_match[:driver]
    end
    def drivers_for_aggregate_types type_names: []
      return all_drivers if type_names.empty?
      type_names.map { |e| driver_for e }
    end
    def all_drivers
      configuration.map { |e| e[:driver]  }
    end
  end
end
