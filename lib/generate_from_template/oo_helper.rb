require "rubygems"
require "csv2hash"
require "active_support/inflector"
require "active_support/core_ext/hash"

module OOHelper
  class Models
    attr_accessor :normal_models, :special_models

    def initialize(csv_fname)
      @hash = CSV2Hash.new(csv_fname).to_hash
      set_normal_models
    end

    def models(&block)
      _models = normal_models.map do |model, model_info|
        Model.new(model, model_info)
      end
      return _models unless block_given?
      _models.each{|m| block.call(m) }
    end

    def set_normal_models
      # __で始まるモデル名は、グローバルな設定値(例えばapplication_nameなど)を
      # 設定するためのテーブルとして使うため、ここでは除外する
      @normal_models = @hash.reject{|m, _| m =~ /^__/ }
    end

    def set_special_models
      @special_models = @hash.select{|m, _| m =~ /^__/ }.map{|m, info| [ m[/^__(.*)$/, 1], info]}
    end

    # ==== for view.erb ===================

    def controllers
      self.models.map{|m| m.controllers}.flatten
    end

    # {[cname, view_name] => models}の形のハッシュを得る
    def models_group_by_cont_and_view
      self.models.inject({}) do |result, m|
        m.views_group_by_cont.each do |cname, view_names|
          result[[cname, view_names]] ||= []
          result[[cname, view_names]] << m
        end
        result
      end
    end
  end

  class Model
    attr_accessor :model, :model_info

    def initialize(model, model_info)
      @model = model
      @model_info = model_info

      # attrにある属性にはa.fooのようにアクセスできるようにする
      ((@model_info["attrs"] || {}).keys - self.methods).each do |name_|
        self.class.class_eval do
          define_method name_ do |*args|
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

    # ==== for view.erb ===================

    # views欄からコントローラ名一覧を取得
    def controllers
      self.views_group_by_cont.blank? ? [] : self.views_group_by_cont.keys.uniq
    end

    # {コントローラ名 => [ビュー名1, ビュー名2 .. ]}の形のハッシュを返す
    def views_group_by_cont
      return [] if self.views.blank?
      #@model.views.uniq.scan(/([\w_]+)#([\w_]+)/).inject({}) do |result, (controller_name, view_name)|
      #  result[controller_name] ||= []
      #  result[controller_name] << view_name
      #  result
      #end
      Hash[*(self.views.scan(/([\w_]+)#([\w_]+)/)).flatten]
    end

    alias :model :model_name
    alias :table :table_name

    def attrs(&block)
      if block_given?
        (@model_info["attrs"] ||{}).each do |name, attr_info|
          attr = Attr.new(name, attr_info)
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
      @etc_only_attr_info = attr_info["etc"] # => {"type" => *,  "field" => * .. }
      @all_attr_info = attr_info

      # 下位互換のため
      @attr_info = attr_info

      @etc_only_attr_info.keys.each do |name|
        self.class.class_eval do
          define_method name do |*args|
            if 2 <= args.length
              # a.default "null" ":default => $v"のように書くと、
              # defaultの値が"null"の時は空文字列、その他の場合は":default => #{@etc_only_attr_info[name]}"を返す
              value_is_null, value_is_not_null = args
              v = @etc_only_attr_info[name] == value_is_null ? "" : value_is_not_null.gsub('$v', @etc_only_attr_info[name].to_s).gsub(/\bTRUE\b/, "true").gsub(/\bFALSE\b/, "false")
            else
              v = @etc_only_attr_info[name]
            end
            NKF.nkf('-w', v.to_s)
          end
        end
      end

      @all_attr_info.keys.compact.each do |func_name| # e.g. func_name = "css"
        self.class.class_eval do
          define_method func_name do |*args|
            tbl_name = args[0] # TODO: extract_optionsに変換する
            options = args[1] || {}

            child_name_cell_val_hash = (@all_attr_info[func_name] || {}).select{|k, v| v.present? || options[:blank]}

            if block_given?
              child_name_cell_val_hash.each{|k,v| yield k,v }
            else
              Hash[*child_name_cell_val_hash.flatten]
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
