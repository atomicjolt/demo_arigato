class Course < ActiveRecord::Base
  belongs_to :canvas_load
  
  attr_accessor :is_selected

  def parsed
    JSON.parse(self.content).symbolize_keys
  end

  def method_missing(meth, *args, &block)
    if meth != :content= && parsed.has_key?(meth)
      parsed[meth]
    else
      super
    end
  end

end
