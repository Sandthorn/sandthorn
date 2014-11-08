module Sandthorn
  class Configuration
    attr_accessor :drivers

    def initialize
      yield(self) if block_given?
    end

    def serializer
      if block_given?
        @serializer = Proc.new
      else
        @serializer ||= default_serializer
      end
    end

    def deserializer
      if block_given?
        @deserializer = Proc.new
      else
        @deserializer ||= default_deserializer
      end
    end

    def default_serializer
      @default_serializer   ||= -> (data) { YAML.dump(data) }
    end

    def default_deserializer
      @default_deserializer ||= -> (data) { YAML.load(data) }
    end

  end
end