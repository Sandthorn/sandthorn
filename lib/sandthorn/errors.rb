module Sandthorn
  module Errors
    class Error < StandardError; end
    class AggregateNotFound < Error; end
    class ConcurrencyError < Error; end
    class ConfigurationError < Error; end
  end
end