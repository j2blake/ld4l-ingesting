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
  class BlankNodesMap < Hash
    def record(node_name, line_number)
      range = self[node_name]
      if range
        self[node_name] = range.first...line_number
      else
        self[node_name] = line_number...line_number
      end
    end
  end

  class BreakpointFinder
    attr_reader :line_count
    def initialize(input_path, max_triples)
      @input_path = input_path
      @max_triples = max_triples
    end

    def find()
      build_blank_nodes_map
      determine_breakpoints
      @breakpoints
    end

    def build_blank_nodes_map()
      @range_map = BlankNodesMap.new
      File.foreach(@input_path) do |line|
        if line =~ /(_:\S+)\s/
          @range_map.record($~[1], $.)
        end
      end
      @line_count = $.
    end

    def determine_breakpoints()
      @breakpoints = []
      while bp = next_breakpoint
        @breakpoints << bp
      end
    end

    def previous_break
      @breakpoints[-1] || 0
    end

    def next_breakpoint()
      return nil if at_the_end?
      return check_within_reach_of_the_end || look_for_eligible_break || look_for_too_large_break
    end

    def at_the_end?()
      previous_break >= @line_count
    end

    def check_within_reach_of_the_end()
      if (@max_triples >= @line_count - previous_break)
        @line_count
      else
        nil
      end
    end

    def look_for_eligible_break()
      (1..@max_triples).reverse_each do |length|
        candidate = previous_break + length
        if eligible_breakpoint?(candidate)
          return candidate
        end
      end
      nil
    end

    def look_for_too_large_break()
      preferred_maximum = previous_break + @max_triples
      (preferred_maximum..@line_count).each do |candidate|
        if eligible_breakpoint?(candidate)
          warn("Can't find a break between #{previous_break} and #{preferred_maximum}. Breaking at #{candidate} (#{candidate - previous_break} triples).")
          return candidate
        end
      end
    end

    def eligible_breakpoint?(candidate)
      return false if candidate == 0
      return true if candidate >= @line_count
      @range_map.each do |_,range|
        return false if range.include?(candidate)
      end
      return true
    end
  end
end
