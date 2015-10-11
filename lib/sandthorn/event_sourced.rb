require 'sandthorn/event_sourced_marshal'
require 'sandthorn/event_sourced_base'

module Sandthorn
  module EventSourced
    include Sandthorn::EventSourced::Base
    include Sandthorn::EventSourced::Marshal
    
    def self.included(base)
      base.extend(Sandthorn::EventSourced::Base::ClassMethods)

      def base.event_sourced_attr(*args)
        self.event_sourced_attributes= args
      end

    end
  end
end