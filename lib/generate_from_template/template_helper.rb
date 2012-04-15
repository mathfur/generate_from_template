# -*- encoding: utf-8 -*-
module TemplateHelper
  def n(str)
    str.present? ? str : '""'
  end

  def arr(str)
    str.split(/\s*,\s*/)
  end
end

