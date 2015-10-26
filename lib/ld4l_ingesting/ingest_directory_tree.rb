=begin rdoc
--------------------------------------------------------------------------------

If the triple-store is running, show how many triples it has and ask whether to
continue (this is reminder to clear, if desired).

Ingest into the specified graph name.

Ingest all of the eligible files in the specified directory, and in any
sub-directories. A file is eligible if its name matches the regular expression.
By default, this means files with extensions of .rdf, .owl, .nt, or .ttl.

--------------------------------------------------------------------------------

Usage: ld4l_ingest_directory_tree <directory> <graph_uri> <timings_output_file> [regexp] [REPLACE]

--------------------------------------------------------------------------------
=end

module Ld4lIngesting
  class IngestDirectoryTree
    USAGE_TEXT = 'Usage is ld4l_ingest_directory_tree <directory> <graph_uri> <timings_output_file> [regexp] [REPLACE]'
    DEFAULT_MATCHER = /.+\.(rdf|owl|nt|ttl)$/
    def process_arguments(args)
      replace_output = args.delete('REPLACE')

      raise UserInputError.new(USAGE_TEXT) unless args && (3..4).include?(args.size)

      raise UserInputError.new("#{args[0]} is not a directory") unless Dir.exist?(args[0])
      @top_dir = File.expand_path(args[0])

      @graph_uri = args[1]

      raise UserInputError.new("#{args[2]} already exists -- specify REPLACE") if File.exist?(args[2]) unless replace_output
      raise UserInputError.new("Can't create #{args[2]}: no parent directory.") unless Dir.exist?(File.dirname(args[2]))
      @timings_output = File.expand_path(args[2])

      if args[3]
        @filename_matcher = Regexp.new(args[3])
      else
        @filename_matcher = DEFAULT_MATCHER
      end
      
      @start_time = Time.now
    end

    def complain_if_not_running
      selected = TripleStoreController::Selector.selected
      raise UserInputError.new("No triple store selected.") unless selected

      TripleStoreDrivers.select(selected)
      @ts = TripleStoreDrivers.selected

      raise UserInputError.new("#{@ts} is not running") unless @ts.running?
    end

    def confirm_intentions
      puts "#{@ts} already contains #{@ts.size} triples."
      puts "Continue with the ingest? (yes/no) ?"
      'yes' == STDIN.gets.chomp
    end

    def traverse_the_directory
      Find.find(@top_dir) do |path|
        if File.file?(path) && path =~ @filename_matcher
          elapsed = ingest_file(path)
          record_ingest(path, elapsed)
        end
      end
    end

    def ingest_file(path)
      puts "Ingesting #{path}"
      elapsed = Benchmark.realtime do
        @ts.ingest_file(File.expand_path(path), @graph_uri)
      end
      puts "Ingested in #{elapsed}."
      elapsed
    end

    def record_ingest(path, elapsed)
      File.open(@timings_output, 'a') do |f|
        f.puts("%s, %.3f" % [path, elapsed])
      end
    end
    
    def report
      puts "Start time: #{@start_time}"
      puts "End time:   #{Time.now}"
    end

    def run
      begin
        process_arguments(ARGV)
        complain_if_not_running

        if confirm_intentions
          traverse_the_directory
          report
        else
          puts
          puts "OK. Skip it."
          puts
        end
      rescue UserInputError
        puts
        puts "ERROR: #{$!}"
        puts
      end
    end
  end
end
