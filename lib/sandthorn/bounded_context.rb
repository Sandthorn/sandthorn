module Sandthorn
  module BoundedContext
    module ClassMethods
      def aggregate_list
        @aggregate_list = p_aggregate_list(self)
      end

      private
      
      def p_aggregate_list(bounded_context_module)
        return [] unless bounded_context_module.respond_to?(:constants)
        
        classes = get_classes(bounded_context_module)
        aggregate_list = classes.select { |item| item.include?(Sandthorn::AggregateRoot) }
        modules = get_modules(bounded_context_module, classes)
        
        aggregate_list += modules.flat_map { |m| p_aggregate_list(m) }
        
        aggregate_list
      end

      def get_classes namespace
        namespace.constants.map(&namespace.method(:const_get)).grep(Class)
      end

      def get_modules namespace, classes
        namespace.constants.map(&namespace.method(:const_get)).grep(Module).delete_if do |m| 
          classes.include?(m) || m == Sandthorn::BoundedContext::ClassMethods
        end
      end
    end

    extend ClassMethods
    
    def self.included( other )
      other.extend( ClassMethods )
    end
  end
end
