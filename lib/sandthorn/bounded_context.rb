module Sandthorn
  module BoundedContext
    module ClassMethods
      def aggregate_types
        @aggregate_list = p_aggregate_types(self)
      end

      private
      
      def p_aggregate_types(bounded_context_module)
        return [] unless bounded_context_module.respond_to?(:constants)
        
        classes = classes_in(bounded_context_module)
        aggregate_list = classes.select { |item| item.include?(Sandthorn::AggregateRoot) }
        modules = modules_in(bounded_context_module, classes)
        
        aggregate_list += modules.flat_map { |m| p_aggregate_types(m) }
        
        aggregate_list
      end

      def classes_in(namespace)
        namespace.constants.map(&namespace.method(:const_get)).grep(Class)
      end

      def modules_in(namespace, classes)
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
