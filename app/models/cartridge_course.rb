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
    
    self.course_code   = parts[0]
    self.name          = parts[1]
    self.sis_course_id = parts[2]
    self.account_id    = parts[3]
    self.term_id       = parts[4]
    self.start_at      = parts[6]
    self.end_at        = parts[7]
    
    self.is_enabled  = parts[5] == 'active'
  end
  
  def content
    @content
  end

end