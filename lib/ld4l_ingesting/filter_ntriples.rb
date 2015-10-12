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
      bad = 0
      good = 0
      File.open(out_path, 'w') do |out|
        File.foreach(in_path) do |line|
          if line.strip.empty?
            blank += 1
          elsif good_syntax(line)
            out.write(line)
            good += 1
          else
            bad += 1
            @report.write("#{in_path}:  #{line}")
          end
        end
      end

      @files_count += 1
      @good_triples_count += good
      if bad > 0 || blank > 0
        @bad_files_count += 1
        @bad_triples_count += bad
      @blank_lines_count += blank
      end

      puts "Found #{good} good triples, #{bad} bad triples, and #{blank} blank lines in #{in_path}"
    end

    def good_syntax(line)
      line =~ / ^ \s* (\S+) \s+ (\S+) \s+ (.*?) \s+ \. \s* $ /x
      match = $~
      return match && good_subject(match[1]) && good_predicate(match[2]) && good_object(match[3])
    end

    def good_subject(s)
      good_uri(s)
    end

    def good_predicate(p)
      good_uri(p)
    end

    def good_object(o)
      good_uri(o) || good_literal(o)
    end
    
    def good_uri(uri)
      good_explicit_uri(uri) || good_prefixed_uri(uri)
    end
    
    def good_explicit(uri)
      uri[0] == '<' && uri[-1] == '>' && uri.index(':') && ! uri =~ INVALID_URI_CHARACTERS
    end
    
    def good_prefixed_uri(uri)
      uri.index(':') && ! uri =~ INVALID_PREFIX_CHARACTERS
    
    def good_literal(literal)
      good_untyped_literal(literal) || good_typed_literal(literal) || good_language_literal(literal)
    end
    
    def good_untyped_literal(literal)
      literal =~ /^"[^"]*"$/
    end
    
    def good_typed_literal(literal)
      literal =~ /^"[^"]*"\^\^[^" ]+$/
    end
    
    def good_language_literal(literal)
      literal =~ /^"[^"]*"@\S+$/
    end
    
    def report()
      puts "Processed #{@good_triples_count} good triples in #{@files_count} files."
      puts "Found #{@bad_triples_count} bad triples and #{@blank_lines_count} blank lines in #{@bad_files_count} files."
      @report.puts "Processed #{@good_triples_count} good triples in #{@files_count} files."
      @report.puts "Found #{@bad_triples_count} bad triples and #{@blank_lines_count} blank lines in #{@bad_files_count} files."
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
