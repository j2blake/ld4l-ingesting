=begin rdoc
--------------------------------------------------------------------------------

Summarize the ingest times. For each 100 files (or 500 or 1000), figure the
average ingest time.

Output as a CSV file, like this:
  "/the/full/ingest_timings_file/path", 100
    "Files", "Average time"
  "1-100", 14.2
  "101-200", 15.3
  ...

--------------------------------------------------------------------------------

Usage: ld4l_summarize_ingest_timings <timings_file> <group_size> <report_file> [REPLACE]

--------------------------------------------------------------------------------
=end

module Ld4lIngesting
  class SummarizeIngestTimings
    USAGE_TEXT = 'Usage is ld4l_summarize_ingest_timings <timings_file> <group_size> <summary_file> [REPLACE]'
    def process_arguments(args)
      replace_file = args.delete('REPLACE')

      raise UserInputError.new(USAGE_TEXT) unless args && args.size == 3

      raise UserInputError.new("#{args[0]} does not exist") unless File.exist?(args[0])
      @timings_path = File.expand_path(args[0])

      begin
        @group_size = args[1].to_i
      rescue
        @group_size = 0
      end
      raise UserInputError.new("Group size must be a positive integer: '#{args[1]}'") unless @group_size > 0

      raise UserInputError.new("#{args[2]} already exists -- specify REPLACE") if File.exist?(args[2]) unless replace_file
      raise UserInputError.new("Can't create #{args[2]}: no parent directory.") unless Dir.exist?(File.dirname(args[2]))
      @summary_file_path = File.expand_path(args[2])
    end

    def build_table()
      @table = []
      File.foreach(@timings_path).each_slice(@group_size) do |slice|
        total_time = 0.0
        slice.each_with_index do |line, i|
          begin
            if line =~ /,\s*([\d.]+)$/
              total_time += $1.to_f
            else
              puts "Invalid format, line %d: '%s'" % [line_number(i), line]
            end
          rescue
            puts "Invalid time value, line %d: '%s'" % [line_number(i), $1]
          end
        end
        @table << [line_number(0), slice.size, total_time]
      end
    end

    def line_number(i)
      @table.size * @group_size + i + 1
    end

    def write_table()
      @summary.puts '"%s", %d' % [@timings_path, @group_size]
      @summary.puts '"Files", "Average time"'
      @table.each do |row|
        @summary.puts '"%d-%d", %.2f' % [row[0], row[0] + row[1] - 1, row[2] / row[1]]
      end
    end

    def run()
      begin
        process_arguments(ARGV)

        @summary = File.open(@summary_file_path, 'w')
        begin
          build_table
          write_table
        ensure
          @summary.close if @summary
        end
      rescue UserInputError
        puts
        puts "ERROR: #{$!}"
        puts
      end
    end
  end
end