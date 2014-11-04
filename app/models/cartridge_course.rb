class CartridgeCourse < ActiveRecord::Base
  
  belongs_to :canvas_load
  
  attr_accessor :is_enabled, :is_selected

  def content=(value)
    if value.is_a?(String)
      parts = value.split(',')
      @content = value
    else
      parts = value
      @content = value.join(',')
    end
    self.category   = parts[0]
    self.source_id   = parts[1]
    self.short_name  = parts[2]
    self.long_name   = parts[3]
    self.sub_account = parts[4]
    self.course_file = parts[5]
    self.is_enabled  = parts[6] == 'TRUE'
  end
  def content
    @content
  end
end
