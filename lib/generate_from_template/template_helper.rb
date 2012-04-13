# -*- encoding: utf-8 -*-
module TemplateHelper
  def n(str)
    str.present? ? str : '""'
  end
end

