require 'benchmark'
require 'fileutils'
require 'find'
require 'tempfile'

require "ld4l_ingesting/version"
require "ld4l_ingesting/convert_directory_tree"
require "ld4l_ingesting/ingest_directory_tree"
require "ld4l_ingesting/filter_ntriples"
require "ld4l_ingesting/scan_directory_tree"

module Ld4lIngesting
  # You screwed up the calling sequence.
  class IllegalStateError < StandardError
  end

  # What did you ask for?
  class UserInputError < StandardError
  end

  def bogus(message)
    puts(">>>>>>>>>>>>>BOGUS #{message}")
  end
end
