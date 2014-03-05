require "dirty_hashy"


module Sandthorn
  module AggregateRoot
    include Dirty::Attributes
    #module_function

    attr_reader :aggregate_id
    attr_reader :aggregate_events
    attr_reader :aggregate_current_event_version
    attr_reader :aggregate_originating_version
    attr_reader :aggregate_stored_serialized_object
    attr_reader :hashy

    alias :id :aggregate_id


    def self.extend_object(aggregate)
      puts "self.extend_object"
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def aggregate_initialize
      @aggregate_current_event_version = 0
      @aggregate_originating_version = 0
      @aggregate_events = []
      @hashy = DirtyHashy.new
    end



    def save
      aggregate_events.each do |event|
        event[:event_data] = Sandthorn.serialize event[:event_args]
        event[:event_args] = nil #Not send extra data over the wire
      end
      unless aggregate_events.empty?
        Sandthorn.save_events( aggregate_events, aggregate_originating_version, aggregate_id, self.class.name)
        @aggregate_events = []
        @aggregate_originating_version = @aggregate_current_event_version
      end
      self
    end

    

    def all
    end

    module ClassMethods
    
      def find aggregate_id
        class_name = self.respond_to?(:name) ? self.name : self.class # to be able to extend a string for example.
        events = Sandthorn.get_aggregate(aggregate_id, class_name)
        raise Sandthorn::Errors::AggregateNotFound unless events and !events.empty?

        transformed_events = events.map { |e| e.merge(event_args: Sandthorn.deserialize(e[:event_data])) }
        aggregate_build transformed_events
      end

      def new *args
        agg = super
        
        agg.aggregate_initialize
        agg.send :set_aggregate_id, Sandthorn.generate_aggregate_id
        #Maby not need
        # self.attr_accessors.each do |var|
        #   value = agg.instance_variable_get("@#{var}")
        #   agg.instance_variable_set "@#{var}", value
        #   hashy[var.to_s] = value
        # end
        agg.send :commit, *args
        agg
      end


      def aggregate_build events
        first_event = events.first()
        current_aggregate_version = 0
        if first_event[:event_name] == "aggregate_set_from_snapshot"
          aggregate = first_event[:event_args][0]
          current_aggregate_version = aggregate.aggregate_originating_version
          events.shift
        elsif first_event[:event_name] == "instance_extended_as_aggregate"
          aggregate = first_event[:event_args][0]
          aggregate.extend AggregateRoot
          events.pop
        else
          new_args = events.first()[:event_args][:method_args]

          if new_args.nil?
            aggregate = new
          else
            aggregate = new *new_args
          end
          aggregate.send :aggregate_clear_current_event_version!
        end

        attributes = {}
        events.each do |event|
          event_args = event[:event_args]
          event_name = event[:event_name]

          if event_name == "aggregate_set_from_snapshot"
            #aggregate.send event_name,*event_args
            #set the attribute hash instead of instance varaibles directly
            next
          end
          next if event_name == "instance_extended_as_aggregate"

          attribute_deltas = event_args[:attribute_deltas]
          if (event[:aggregate_version].nil? == false)
            current_aggregate_version = event[:aggregate_version]
          end

          if !attribute_deltas.nil?
            deltas = {}
            attribute_deltas.each do |delta|
              deltas[delta[:attribute_name]] = delta[:new_value]
            end
            attributes.merge! deltas
          end
        end
        aggregate.send :clear_aggregate_events
        aggregate.send :set_orginating_aggregate_version!, current_aggregate_version
        aggregate.send :set_current_aggregate_version!, current_aggregate_version
        aggregate.send :set_instance_variables!, attributes
        aggregate
    end
      
    end
    

    private

    def commit *args
      increase_current_aggregate_version!
      extract_relevant_aggregate_instance_variables.each do |var|
        @hashy[var.to_s.delete("@")] = self.instance_variable_get("#{var}")
      end
      
      method_name = caller[0][/`.*'/][1..-2]
      aggregate_attribute_deltas = [] 
      @hashy.changes.each do |attribute|
        aggregate_attribute_deltas << { :attribute_name => attribute[0], :old_value => attribute[1][0], :new_value => attribute[1][1]}
      end
      unless aggregate_attribute_deltas.empty?
        data = {:method_name => method_name, :method_args => args, :attribute_deltas => aggregate_attribute_deltas}
        @aggregate_events << ({:aggregate_version => @aggregate_current_event_version, :event_name => method_name, :event_args => data})
      end
      self
    end

    def set_instance_variables! attributes
      attributes.each_pair do |k,v|
        self.instance_variable_set "@#{k}", v
      end
    end

    def extract_relevant_aggregate_instance_variables
      instance_variables.select { |i| i.to_s != "@hashy" && (!i.to_s.start_with?("@aggregate_") || i.to_s == "@aggregate_id") }
    end

    def set_orginating_aggregate_version! aggregate_version
      @aggregate_originating_version = aggregate_version
    end

    def increase_current_aggregate_version!
      @aggregate_current_event_version += 1
    end

    def set_current_aggregate_version! aggregate_version
      @aggregate_current_event_version = aggregate_version
    end

    def clear_aggregate_events
      @aggregate_events = []
      @aggregate_attribute_deltas = []
    end

    def aggregate_clear_current_event_version!
      @aggregate_current_event_version = 0
    end

    def set_aggregate_id aggregate_id
      @aggregate_id = aggregate_id
    end

  end
end