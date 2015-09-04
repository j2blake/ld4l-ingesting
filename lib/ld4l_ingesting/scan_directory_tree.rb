=begin rdoc
--------------------------------------------------------------------------------

Run rapper against all eligible files in a directory tree, compiling a list of
the syntax errors in the files.

--------------------------------------------------------------------------------

Usage: ld4l_scan_directory_tree <directory> <error_file> [[regexp] input_format] [REPLACE]

--------------------------------------------------------------------------------
=end

module Ld4lIngesting
  class ScanDirectoryTree
    USAGE_TEXT = 'Usage is ld4l_scan_directory_tree <directory> <error_file> [[regexp] input_format] [REPLACE]'
    DEFAULT_MATCHER = /.+\.(rdf|owl|nt|ttl)$/
    def initialize
      @bad_files_count = 0
      @error_count = 0
    end

    def process_arguments(args)
      replace_output = args.delete('REPLACE')

      raise UserInputError.new(USAGE_TEXT) unless args && (2..4).include?(args.size)

      raise UserInputError.new("#{args[0]} is not a directory") unless Dir.exist?(args[0])
      @top_dir = File.expand_path(args[0])

      raise UserInputError.new("#{args[1]} already exists -- specify REPLACE") if File.exist?(args[1]) unless replace_output
      raise UserInputError.new("Can't create #{args[1]}: no parent directory.") unless Dir.exist?(File.dirname(args[1]))
      @error_file_path = File.expand_path(args[1])

      if args[2]
        @filename_matcher = Regexp.new(args[2])
      else
        @filename_matcher = DEFAULT_MATCHER
      end

      if args[3]
        @input_format = args[3]
      else
        @input_format = 'ntriples'
      end
    end

    def traverse_the_directory
      Dir.chdir(@top_dir) do
        Find.find('.') do |path|
          if File.file?(path) && path =~ @filename_matcher
            scan_file_and_record_errors(path)
          end
        end
      end
    end

    def scan_file_and_record_errors(path)
      `rapper -i #{@input_format} #{path} - > /dev/null 2> #{@tempfile_path}`

      error_lines = File.readlines(@tempfile_path).each.select {|l| l.index('Error')}
      unless error_lines.empty?
        @bad_files_count += 1
        @error_count += error_lines.size
        @error_file.write(error_lines.join)
      end
      puts "-- found #{error_lines.size} errors in #{path}"
    end

    def report
      puts ">>>>>>> bad files #{@bad_files_count}, errors #{@error_count}"
    end

    def run()
      begin
        process_arguments(ARGV)
        begin
          @error_file = File.open(@error_file_path, 'w')
          begin
            tempfile = Tempfile.new('ld4l_scan')
            @tempfile_path = tempfile.path
            traverse_the_directory()
            report
          ensure
            tempfile.close! if tempfile
          end
        ensure
          @error_file.close if @error_file
        end
      rescue UserInputError
        puts
        puts "ERROR: #{$!}"
        puts
      end
    end
  end

end
