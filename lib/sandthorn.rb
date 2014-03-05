require "sandthorn/version"
require "sandthorn/errors"
require "sandthorn/aggregate_root"
require "sandthorn/dirty_checker"

module Sandthorn
  class << self
    def configuration= configuration
      @configuration = configuration
    end
    def configuration
      @configuration ||= []
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
      raise Sandthorn::Errors::ConfigurationError.new "Aggregate class #{class_name} is not configured for EventStore" if matches.empty?
      first_match = matches.first
      first_match[:driver]
      #UpptecEventSequelDriver.driver_from_url url: first_match[:url], context: first_match[:context]
    end
    # def drivers_for_class_names class_names: []
    #   return all_drivers if class_names.empty?
    #   class_names.map { |e| driver_for e }.uniq { |d| { url: d.url, context: d.context } }
    # end
    # def all_drivers
    #   configuration.map { |e| UpptecEventSequelDriver.driver_from_url url: e[:url], context: e[:context]  }
    # end
  end
end
