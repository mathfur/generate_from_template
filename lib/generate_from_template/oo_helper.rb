require "rubygems"
require "csv2hash"
require "active_support"

module OOHelper
  class Models
    def initialize(csv_fname)
      @hash = CSV2Hash.new(csv_fname).to_hash
    end

    def models(&block)
      models_ = @hash.map do |model, model_info|
        Model.new(model, model_info)
      end

      return models_ unless block_given?

      models_.each{|m| block.call(m) }
    end
  end

  class Model
    attr_accessor :model, :model_info

    def initialize(model, model_info)
      @model = model
      @model_info = model_info

      (@model_info.keys - self.methods).each do |name|
        self.class.class_eval do
          define_method name do |*args|
            @model_info[name]
          end
        end
      end
    end

    def camelize
      @model.camelize
    end

    def table_name
      @model.pluralize.underscore
    end

    alias :tbl :table_name

    def model_name
      @model.pluralize.camelize
    end

    def attrs(&block)
      @model_info["attrs"].each do |attr, attr_info|
        attr = Attr.new(attr, attr_info)
        block.call(attr)
      end
    end

    def attr_names
      self.attr.keys
    end
  end

  class Attr
    attr_accessor :attr, :attr_info

    def initialize(attr, attr_info)
      @attr = attr
      @attr_info = attr_info # => {"type" => *,  "field" => * .. }

      @attr_info.keys.each do |name|
        self.class.class_eval do
          define_method name do |*args|
            @attr_info[name]
          end
        end
      end
    end

    def name
      @attr
    end
  end
end

# TODO: 後で消す
class String
  STDERR.puts "不要なコードが残っています"
  def camelize; self; end
  def underscore; self; end
  def pluralize; self; end
end

if $0 == __FILE__
  OOHelper::Models.new("test/sample.csv").models do |m|
    puts "#{m.table_name}"
    m.attrs do |a|
      puts "  > #{a.name}: #{a.type}"
    end
  end
end
