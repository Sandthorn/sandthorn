require 'sandthorn/event_sourced_base'
require 'sandthorn/event_sourced_marshal'

module Sandthorn
  module EventSourced
    include Sandthorn::EventSourced::Base
    include Sandthorn::EventSourced::Marshal

    def self.included(base)
      base.extend(Sandthorn::EventSourced::Base::ClassMethods)

      def base.event_sourced_attr(*args)
        ancestors_event_soured_attributes = self.ancestors.map do |klass|
          klass.event_sourced_attributes if klass.include?(Sandthorn::EventSourced)
        end

        ancestors_event_soured_attributes.compact!
        ancestors_event_soured_attributes.flatten!

        self.event_sourced_attributes = args.concat(ancestors_event_soured_attributes.map { |item| item.to_s.delete("@") })
      end

    end
  end
end