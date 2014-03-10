module Sandthorn
  module AggregateRootSnapshot
    attr_reader :aggregate_snapshot

    def aggregate_snapshot!

      if @aggregate_events.count > 0
        raise "Can't take snapshot on object with unsaved events"
      end

      @aggregate_snapshot = {
        :event_name => "aggregate_set_from_snapshot",
        :event_args => [self],
        :aggregate_version => @aggregate_current_event_version
      }
    end

    def save_snapshot
      raise "No snapshot has been created!" unless @aggregate_snapshot
      @aggregate_snapshot[:event_data] = Sandthorn.serialize @aggregate_snapshot[:event_args]
      @aggregate_snapshot[:event_args] = nil
      puts "pre save_snapshot"
      Sandthorn.save_snapshot @aggregate_snapshot, @aggregate_id, self.class.name
      puts "post save_snapshot"
      @aggregate_snapshot = nil
    end
    private
    def aggregate_create_event_when_extended
      self.aggregate_snapshot!
      vars = extract_relevant_aggregate_instance_variables
      vars.each do |var_name|
        value = instance_variable_get var_name
        dump = Marshal.dump(value)
        store_aggregate_instance_variable var_name, dump
      end
      #@aggregate_snapshot[:event_data] = Sandthorn.serialize @aggregate_snapshot[:event_args]
      store_aggregate_event "instance_extended_as_aggregate", @aggregate_snapshot[:event_args]
      @aggregate_snapshot = nil
    end
  end
end
