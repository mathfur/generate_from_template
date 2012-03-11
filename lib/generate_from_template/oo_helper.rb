require "rubygems"
require "csv2hash"
require "active_support/inflector"
require "active_support/core_ext/hash"

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

      # attrにある属性にはa.fooのようにアクセスできるようにする
      ((@model_info["attrs"] || {}).keys - self.methods).each do |name_|
        p model if name_ == "name"
        self.class.class_eval do
          define_method name_ do |*args|
            p ">>>>>"
            p @model_info["attrs"].keys
            p "<<<<"
            (@model_info["attrs"] || {})[name_]["etc"]
          end
        end
      end

      # cttrへもアクセサ定義
      ((@model_info["cattrs"] || {}).keys - self.methods).each do |name|
        self.class.class_eval do
          define_method name do |*args|
            (((@model_info["cattrs"] || {})[name] || {})["etc"] || {})["cattr_val"]
          end
        end
      end
    end

    # m.table_columns("index"){|c| .. }でindexのカラム全体を渡る
    # options:
    #   :blank => true <=> セルの値がブランクのものも出力する
    def table_columns(tbl_name, options ={})
      # {カラム名 => セルの値}ハッシュを作る
      column_cell_hash = (@model_info["attrs"] ||{}).merge((@model_info["columns"] ||{})).map{|attr, hash| [attr, hash["tables"][tbl_name]]}.
        select{|k, v| v.present? || options[:blank]}

      if block_given?
        column_cell_hash.each do |attr, cell_val|
          yield attr, cell_val
        end
      else
        Hash[*column_cell_hash.flatten]
      end
    end

    def camelize; @model.camelize; end
    def table_name; @model.pluralize.underscore; end
    def pluralize; @model.pluralize; end
    def singularize; @model.singularize; end
    def underscore; @model.underscore; end

    def single
      self.singularize.underscore
    end

    def multiple
      self.pluralize.underscore
    end

    def instance
      self.singularize.underscore
    end

    alias :tbl :table_name

    def model_name
      @model.singularize.camelize
    end

    def controller_name
      @model.pluralize + "_controller"
    end

    alias :model :model_name
    alias :table :table_name


    def attrs(&block)
      if block_given?
        (@model_info["attrs"] ||{}).each do |attr, attr_info|
          attr = Attr.new(attr, attr_info["etc"])
          block.call(attr)
        end
      else
        Hash[*@model_info["attrs"].map{|attr, attr_info| [attr, attr_info["etc"]]}.flatten]
      end
    end

    def attr_names
      self.attrs.keys
    end

    def has_many?(m2)
      !!m2.attr_names.find{|name| name == "#{self.singularize.underscore}_id" }
    end

    def belongs_to?(m2)
      m2.has_many?(self)
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
            if 2 <= args.length
              # a.default "null" ":default => $v"のように書くと、
              # defaultの値が"null"の時は空文字列、その他の場合は":default => #{@attr_info[name]}"を返す
              value_is_null, value_is_not_null = args
              @attr_info[name] == value_is_null ? "" : value_is_not_null.gsub('$v', @attr_info[name]).gsub(/\bTRUE\b/, "true").gsub(/\bFALSE\b/, "false")
            else
              @attr_info[name]
            end
          end
        end
      end
    end

    def name
      @attr
    end
  end
end

if $0 == __FILE__
  OOHelper::Models.new("test/sample.csv").models do |m|
    puts "#{m.table_name}"
    m.attrs do |a|
      puts "  > #{a.name}: #{a.type}"
    end
  end
end
