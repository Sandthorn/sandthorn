
# class Class

#   alias_method :attr_reader_without_tracking, :attr_reader
#   def attr_reader(*names)
#     attr_readers.concat(names)
#     attr_reader_without_tracking(*names)
#   end

#   def attr_readers
#     @attr_readers ||= [ ]
#   end

#   alias_method :attr_writer_without_tracking, :attr_writer
#   def attr_writer(*names)
#     attr_writers.concat(names)
#     attr_writer_without_tracking(*names)
#   end

#   def attr_writers
#     @attr_writers ||= [ ]
#   end

#   alias_method :attr_accessor_without_tracking, :attr_accessor
#   def attr_accessor(*names)
#     attr_readers.concat(names)
#     attr_writers.concat(names)
#     attr_accessor_without_tracking(*names)
#   end

#   def attr_accessors
#     attr_readers + attr_writers
#   end

# end
