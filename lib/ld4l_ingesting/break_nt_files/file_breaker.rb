=begin
--------------------------------------------------------------------------------

Find out where to break the input file.

The return from find() is an array of line numbers (1-origin). The file should
be broken after each specified line. The last number in the array is the number
of lines in the file, and hence the last breakpoint.

--------------------------------------------------------------------------------

Read through the input file, creating a map of ranges. Each range goes from the
first to the last mention (exclusive) of a particular blank node.

Find breakpoints: loop until at end of file
  if the remaining lines are less than the limit, break at the end of the file.
  else, start at the desired breakpoint (max-triples past the previous breakpoint)
    search the map to see if the break poiint is eligible.
    if ineligible, try the next smaller.
  if no eligible breakpoint is found, begin incrementing and checking.
    if found, issue a warning and break it there.

--------------------------------------------------------------------------------
=end

module Ld4lIngesting
  class FileBreaker
    def initialize(input_path, output_path, breakpoints)
      @input_path = input_path
      @output_path = output_path
      @breakpoints = breakpoints
      @output_file = nil
      @output_file_counter = 0
    end

    def break()
      File.foreach(@input_path) do |line|
        @line = line
        write_line_to_output
      end
    end

    def write_line_to_output()
      open_output_file unless @output_file
      @output_file.write(@line)
      close_output_file if at_breakpoint?
    end

    def open_output_file()
      @output_file_counter += 1
      @output_file = File.open(figure_expanded_filename, 'w')
    end

    def close_output_file()
      @output_file = @output_file.close
    end

    def at_breakpoint?()
      @breakpoints.include?($.)
    end
    
    def figure_expanded_filename()
      dirname = File.dirname(@output_path)
      basename = File.basename(@output_path)
      filename, period, extension = basename.rpartition('.')
      expanded_basename = "%s_%03d.%s" % [filename, @output_file_counter, extension]
      File.expand_path(expanded_basename, dirname)
    end
  end
end