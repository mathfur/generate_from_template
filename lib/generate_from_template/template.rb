# -*- encoding: utf-8 -*-

require "erb"
require "fileutils"

class Template
  def initialize(fname)
    @templates = ERB.new(File.read(fname), nil, '-').result(binding).scan(/--\[([^\:]*):([^\]:]*)\]-{10,}\n(.*?)\n--\n/m)
  end

  def each_at(base, &block)
    @templates.each do |path, actor, templ|
      full_path = "#{base}/#{path}"
      str = File.exist?(full_path) ? File.read(full_path) : ''
      result = block.call(full_path, actor, str, templ)
      unless Dir.exist?(File.dirname(full_path))
        FileUtils.mkdir_p(File.dirname(full_path))
        STDERR.puts "directory '#{File.dirname(full_path)}' was created."
      end
      open(full_path,'w'){|f| f.write result}
    end
  end
end
