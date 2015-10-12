=begin rdoc
--------------------------------------------------------------------------------

Run rapper against all eligible files in a directory tree, comverting RDF/XML to
NTriples.

If you supply a regular expression, any file whose path matches the expression
is eligible for conversion. By default, files whose names end in ".owl" or ".rdf"
are eligible.

--------------------------------------------------------------------------------

Usage: ld4l_convert_directory_tree <input_directory> <output_directory> [OVERWRITE] <report_file> [REPLACE] [regexp]

--------------------------------------------------------------------------------
=end

module Ld4lIngesting
  class ConvertDirectoryTree
    USAGE_TEXT = 'Usage is ld4l_convert_directory_tree <input_directory> <output_directory> [OVERWRITE] <report_file> [REPLACE] [regexp]'
    DEFAULT_MATCHER = /.+\.(rdf|owl)$/
    def initialize
      @files_count = 0
    end

    def process_arguments(args)
      replace_file = args.delete('REPLACE')
      overwrite_directory = args.delete('OVERWRITE')

      raise UserInputError.new(USAGE_TEXT) unless args && (3..4).include?(args.size)

      raise UserInputError.new("#{args[0]} is not a directory") unless Dir.exist?(args[0])
      @input_dir = File.expand_path(args[0])

      raise UserInputError.new("#{args[1]} already exists -- specify OVERWRITE") if Dir.exist?(args[1]) unless overwrite_directory
      raise UserInputError.new("Can't create #{args[1]}: no parent directory.") unless Dir.exist?(File.dirname(args[1]))
      @output_dir = File.expand_path(args[1])

      raise UserInputError.new("#{args[2]} already exists -- specify REPLACE") if File.exist?(args[2]) unless replace_file
      raise UserInputError.new("Can't create #{args[2]}: no parent directory.") unless Dir.exist?(File.dirname(args[2]))
      @report_file_path = File.expand_path(args[2])

      if args[3]
        @filename_matcher = Regexp.new(args[3])
      else
        @filename_matcher = DEFAULT_MATCHER
      end
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
          elsif File.file?(path) && path =~ @filename_matcher
            convert_file(path, output_path)
          end
        end
      end
    end

    def convert_file(path, output_path)
      puts "converting #{path}"
      `rapper #{path} - > #{output_path}.nt`
      @files_count += 1
    end

    def report
      puts ">>>>>>> converted #{@files_count} files."
    end

    def run()
      begin
        process_arguments(ARGV)

        @report = File.open(@report_file_path, 'w')
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
