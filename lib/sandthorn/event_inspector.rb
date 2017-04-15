module Sandthorn
  module EventInspector
    def has_unsaved_event? event_name, options = {}
      unsaved = events_with_trace_info

      if self.aggregate_events.empty?
        unsaved = []
      else
        unsaved.reject! do |e| 
          e[:aggregate_version] < self
            .aggregate_events.first[:aggregate_version]
        end
      end

      matching_events = unsaved.select { |e| e[:event_name] == event_name }
      event_exists = matching_events.length > 0
      trace = has_trace? matching_events, options.fetch(:trace, {})

      !!(event_exists && trace)
    end

    def has_saved_event? event_name, options = {}
      saved = events_with_trace_info

      unless self.aggregate_events.empty?
        saved.reject! do |e| 
          e[:aggregate_version] >= self
            .aggregate_events.first[:aggregate_version]
        end
      end

      matching_events = saved.select { |e| e[:event_name] == event_name }
      event_exists = matching_events.length > 0
      trace = has_trace? matching_events, options.fetch(:trace, {})

      !!(event_exists && trace)
    end

    def has_event? event_name, options = {}
      matching_events = events_with_trace_info
        .select { |e| e[:event_name] == event_name }

      event_exists = matching_events.length > 0
      trace = has_trace? matching_events, options.fetch(:trace, {})
      !!(event_exists && trace)
    end

    def events_with_trace_info
      saved = Sandthorn.find aggregate_id, self.class
      unsaved = self.aggregate_events
      all = saved
        .concat(unsaved)
        .sort { |a, b| a[:aggregate_version] <=> b[:aggregate_version] }

      extracted = all.collect do |e|
        if e[:event_data].nil? && !e[:event_data].nil?
          data = Sandthorn.deserialize e[:event_data]
        else
          data = e[:event_data]
        end

        {
          aggregate_version: e[:aggregate_version],
          event_name: e[:event_name].to_sym, 
          event_data: data,
          event_meta_data: e[:event_meta_data]
        }
      end

      extracted
    end

    private

    def get_unsaved_events event_name
      self.aggregate_events.select { |e| e[:event_name] == event_name.to_s  }
    end

    def get_saved_events event_name
      saved_events = Sandthorn.get_aggregate_events self.aggregate_id, self.class
      saved_events.select { |e| e[:event_name] == event_name.to_s  }
    end

    def has_trace? events_to_check, trace_info
      return true if trace_info.empty?
      events_to_check.each do |event|
        return false if event[:trace] != trace_info
      end
      true
    end
  end
end
