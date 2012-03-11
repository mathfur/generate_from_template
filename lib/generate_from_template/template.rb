# -*- encoding: utf-8 -*-

require "erb"
require "fileutils"
require File.dirname(__FILE__) + "/oo_helper"

class Template
  attr_reader :erb_result

  def initialize(fname, csv_fname, options = {})
    @erb_result = ERB.new(File.read(fname), nil, '-').result(binding)
    @templates = @erb_result.scan(/\n--\[([^\:]+):([^\]:]+)\]-{10,}(?:\n|\n(.*?)\n)--\n/m)
    @verbose = options[:verbose]
  end

  def each_at(base, &block)
    @templates.each do |path, actor, templ|
      full_path = "#{base}/#{path}"
      str = File.exist?(full_path) ? File.read(full_path) : ''
      result = block.call(full_path, actor, str, templ)
      unless Dir.exist?(File.dirname(full_path))
        FileUtils.mkdir_p(File.dirname(full_path))
        STDERR.puts "directory '#{File.dirname(full_path)}' was created." if @verbose
      end
      open(full_path,'w'){|f| f.write result}
      STDERR.puts "write to #{full_path}" if @verbose
    end
  end
end
