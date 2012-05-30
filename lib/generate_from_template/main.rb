# -*- encoding: utf-8 -*-

require "getoptlong"
require File.dirname(__FILE__) + "/template"

parser = GetoptLong.new

parser.set_options(
  ['--output-dir', '-o', GetoptLong::REQUIRED_ARGUMENT],
  ['--template', '-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--csv-fname', '-c', GetoptLong::REQUIRED_ARGUMENT],
  ['--verbose', GetoptLong::NO_ARGUMENT],
  ['--only-erb', GetoptLong::NO_ARGUMENT],
  ['--skip-confirm', GetoptLong::NO_ARGUMENT]
)

output_dir = nil
template_fname = nil
csv_fname = nil
verbose = nil
skip_confirm = nil
only_erb = nil

parser.each_option do |name, arg|
  case name
  when '--output-dir', '-o'
    output_dir = arg
    puts "output_dir: #{output_dir}"
  when '--csv-fname', '-c'
    csv_fname = arg
    puts "csv_fname: #{csv_fname}"
  when '--template', '-t'
    template_fname = arg
    puts "template_fname: #{template_fname}"
  when '--verbose'
    verbose = true
  when '--only-erb'
    only_erb = true
  when '--skip-confirm'
    skip_confirm = true
  end
end

puts "テンプレートファイルの指定が必要です" unless template_fname
puts "CSVファイルの指定が必要です" unless csv_fname

if only_erb
  puts Template.new(template_fname, csv_fname).erb_result
  exit
end

puts "出力ファイルの指定が必要です" unless output_dir

mark_reg = /INSERT_MARK(\(([^\)]*)\))/

def confirm(path)
  print "#{path}\t\tに書き込みます。よろしいですか?(y/n): "
  res = gets.strip
  (res == 'y')
end

Template.new(template_fname, csv_fname, :verbose => verbose).each_at(output_dir) do |path, act_string, target_str, templ|
  print "."
  result = nil
  case act_string
  when /^m/
    # TODO: 作成中
    result = target_str.gsub(mark_reg) do
      mark_args = $2
      templ
    end
  when /^c/
    result = templ
  else
    raise "act_stringが不正です"
  end
  (skip_confirm || confirm(path)) ? result : nil
end
