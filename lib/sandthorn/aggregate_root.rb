require 'sandthorn/aggregate_root_base'
require 'sandthorn/aggregate_root_marshal'

module Sandthorn
  module AggregateRoot
    include Base
    include Marshal

    def self.included(base)
      base.extend(Base::ClassMethods)
    end
  end
end