module Sandthorn
  module BoundedContext
    module ClassMethods
      def aggregate_list
        @aggregate_list = p_aggregate_list(self)
      end

      private
      
      def p_aggregate_list(bounded_context_module)
        return [] unless bounded_context_module.respond_to?(:constants)
        
        classes = bounded_context_module.constants.map(&bounded_context_module.method(:const_get)).grep(Class)
        aggregate_list = classes.select { |item| item.include?(Sandthorn::AggregateRoot) }

        modules = bounded_context_module.constants.map(&bounded_context_module.method(:const_get)).grep(Module).delete_if do |mo| 
          classes.include?(mo) || mo == Sandthorn::BoundedContext::ClassMethods
        end
        
        aggregate_list += modules.flat_map { |mo| p_aggregate_list(mo) }
        
        aggregate_list
      end
    end

    extend ClassMethods
    
    def self.included( other )
      other.extend( ClassMethods )
    end
  end
end
