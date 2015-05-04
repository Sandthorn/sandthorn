require "sandthorn/aggregate_root_marshal"

module Sandthorn
  module AggregateRoot
    include Sandthorn::AggregateRoot::Marshal

    def self.included(base)
      base.extend(Sandthorn::AggregateRoot::Base::ClassMethods)
    end
  end
end
