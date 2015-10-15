=begin rdoc
--------------------------------------------------------------------------------

Traverse the input directory and its subdirectories, copying all '.nt' files
into the output directory, filtering out all triples with known syntax errors.

--------------------------------------------------------------------------------

Usage: ld4l_filter_ntriples <input_directory> <output_directory> [OVERWRITE] <report_file> [REPLACE]

--------------------------------------------------------------------------------
=end

module Ld4lIngesting
  class FilterNtriples
    USAGE_TEXT = 'Usage is ld4l_filter_ntriples <input_directory> <output_directory> [OVERWRITE] <report_file> [REPLACE]'
    INVALID_URI_CHARACTERS = /[^\w\/?:;@&=+$,-.!~*()'%#\[\]]/
    INVALID_PREFIX_CHARACTERS= /[^\w.-:]/
    def initialize
      @blank_lines_count = 0
      @bad_triples_count = 0
      @good_triples_count = 0
      @bad_files_count = 0
      @files_count = 0
      @error_count = 0
    end

    def process_arguments(args)
      replace_file = args.delete('REPLACE')
      overwrite_directory = args.delete('OVERWRITE')

      raise UserInputError.new(USAGE_TEXT) unless args && args.size == 3

      raise UserInputError.new("#{args[0]} is not a directory") unless Dir.exist?(args[0])
      @input_dir = File.expand_path(args[0])

      raise UserInputError.new("#{args[1]} already exists -- specify OVERWRITE") if Dir.exist?(args[1]) unless overwrite_directory
      raise UserInputError.new("Can't create #{args[1]}: no parent directory.") unless Dir.exist?(File.dirname(args[1]))
      @output_dir = File.expand_path(args[1])

      raise UserInputError.new("#{args[2]} already exists -- specify REPLACE") if File.exist?(args[2]) unless replace_file
      raise UserInputError.new("Can't create #{args[2]}: no parent directory.") unless Dir.exist?(File.dirname(args[2]))
      @report_file_path = File.expand_path(args[2])
    end

    def prepare_output_directory()
      FileUtils.rm_r(@output_dir) if Dir.exist?(@output_dir)
      Dir.mkdir(@output_dir)
    end

    def traverse
      Dir.chdir(@input_dir) do
        Find.find('.') do |path|
          output_path = File.expand_path(path, @output_dir)
          if File.directory?(path)
            FileUtils.mkdir_p(output_path)
          elsif File.file?(path) && path.end_with?('.nt')
            filter_file(path, output_path)
          end
        end
      end
    end

    def filter_file(in_path, out_path)
      blank = 0
      total = 0
      good = 0
      errors = 0

      `rapper -i 'ntriples' #{in_path} - > #{out_path} 2> #{@tempfile_path}`

      error_lines = File.readlines(@tempfile_path).each.select {|l| l.index('Error')}
      unless error_lines.empty?
        @bad_files_count += 1
        @report.write(error_lines.join)
        errors = error_lines.size
      end

      File.foreach(in_path) do |line|
        total += 1
        if line.strip.empty?
          blank += 1
        end
      end

      File.foreach(out_path) do |line|
        good += 1
      end

      bad = total - blank - good

      @files_count += 1
      @good_triples_count += good
      @blank_lines_count += blank
      @bad_triples_count += bad
      @error_count += errors

      puts "Found #{good} good triples, #{bad} bad triples (#{errors} errors), and #{blank} blank lines in #{in_path}"
    end

    def report()
      puts "Processed #{@good_triples_count} good triples in #{@files_count} files."
      puts "Found #{@bad_triples_count} bad triples (#{@error_count} errors) and #{@blank_lines_count} blank lines in #{@bad_files_count} files."
      @report.puts "Processed #{@good_triples_count} good triples in #{@files_count} files."
      @report.puts "Found #{@bad_triples_count} bad triples (#{@error_count} errors) and #{@blank_lines_count} blank lines in #{@bad_files_count} files."
    end

    def run()
      begin
        process_arguments(ARGV)

        @report = File.open(@report_file_path, 'w')
        begin
          prepare_output_directory

          tempfile = Tempfile.new('ld4l_scan')
          @tempfile_path = tempfile.path

          traverse
          report
        ensure
          tempfile.close! if tempfile
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
