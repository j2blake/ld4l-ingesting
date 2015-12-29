=begin
--------------------------------------------------------------------------------

As with convert_directory, keep the subdirectory structure and corresponding fileames.
When breaking, append to the filename __001, __002, etc.
If the file is small enough, keep the original filename and just copy.

Stupid approach:
  Read a line at a time. Decide whether the line contains one or more blank nodes.
  If it contains a blank node, write it to the blank node file. 
    Otherwise, write to one of the regular files.
  The problem with this is that as many as 30% of the lines contain blank nodes.

Two-pass approach:
  First pass:
    pass through, creating a map of the first and last mention of each blank node.
    record the number of lines in the file.
  Find break points:
    start at the desired break point (max-triples past the previous break point)
    search the map to see if the break poiint is eligible.
    if ineligible, try the next smaller.

    if no eligible break point is found, begin incrementing and checking.
      if found, issue a warning and break it there.
  Second pass:
    read through the file, breaking as determined.

--------------------------------------------------------------------------------

Usage: ld4l_break_nt_files <input_directory> <output_directory> [OVERWRITE] <report_file> [REPLACE] <max_triples>

--------------------------------------------------------------------------------
=end

require_relative 'break_nt_files/breakpoint_finder'
require_relative 'break_nt_files/file_breaker'

module Ld4lIngesting
  class BreakNtFiles
    USAGE_TEXT = 'Usage is ld4l_break_nt_files <input_directory> <output_directory> [OVERWRITE] <report_file> [REPLACE] <max_triples>'
    FILENAME_MATCHER = /^.+\.nt$/
    def initialize
    end

    def process_arguments()
      args = Array.new(ARGV)
      replace_file = args.delete('REPLACE')
      overwrite_directory = args.delete('OVERWRITE')

      raise UserInputError.new(USAGE_TEXT) unless args && args.size == 4

      raise UserInputError.new("#{args[0]} is not a directory") unless Dir.exist?(args[0])
      @input_dir = File.expand_path(args[0])

      raise UserInputError.new("#{args[1]} already exists -- specify OVERWRITE") if Dir.exist?(args[1]) unless overwrite_directory
      raise UserInputError.new("Can't create #{args[1]}: no parent directory.") unless Dir.exist?(File.dirname(args[1]))
      @output_dir = File.expand_path(args[1])

      raise UserInputError.new("#{args[2]} already exists -- specify REPLACE") if File.exist?(args[2]) unless replace_file
      raise UserInputError.new("Can't create #{args[2]}: no parent directory.") unless Dir.exist?(File.dirname(args[2]))
      @report_file_path = File.expand_path(args[2])

      begin
        @max_triples = args[3].to_i
      rescue
        raise UserInputError.new("#{args[3]} is not a valid integer.")
      end
      raise UserInputError.new("max_triples must be at least 100.") if @max_triples < 100

      @files_count = 0
      @broken_count = 0
    end

    def prepare_output_directory()
      FileUtils.rm_r(@output_dir) if Dir.exist?(@output_dir)
      Dir.mkdir(@output_dir)
    end

    def traverse
      Dir.chdir(@input_dir) do
        Find.find('.') do |path|
          @input_path = File.expand_path(path, @input_dir)
          @output_path = File.expand_path(path, @output_dir)
          if File.directory?(@input_path)
            FileUtils.mkdir_p(@output_path)
          elsif File.file?(@input_path) && @input_path =~ FILENAME_MATCHER
            @files_count += 1
            process_file()
          end
        end
      end
    end

    def process_file()
      breakpoints, lines, files = find_breakpoints
      break_it(breakpoints)
      @broken_count += files
      logit "Broke #{@input_path} (#{lines} lines) into #{files} files"
    end

    def find_breakpoints()
      finder = BreakpointFinder.new(@input_path, @max_triples)
      breakpoints = finder.find
      [breakpoints, finder.line_count, breakpoints.size]
    end
    
    def break_it(breakpoints)
      FileBreaker.new(@input_path, @output_path, breakpoints).break
    end
    
    def log_header()
      logit "ld4l_break_nt_files #{ARGV.join(' ')}"
    end
    
    def logit(message)
      m = "#{Time.new.strftime('%Y-%m-%d %H:%M:%S')} #{message}"
      puts m
      @report.puts(m)
    end

    def report
      logit ">>>>>>> #{@files_count} files became #{@broken_count} files."
    end

    def run()
      begin
        process_arguments
        @report = File.open(@report_file_path, 'w')
        log_header()
        
        begin
          prepare_output_directory
          traverse
          report
        ensure
          @report.close if @report
        end
      rescue UserInputError
        puts
        puts "ERROR: #{$!}"
        puts
      end
    end

  end
end