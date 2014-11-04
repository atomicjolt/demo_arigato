class CanvasLoad < ActiveRecord::Base
  belongs_to :user
  has_many :cartridge_courses
  
  accepts_nested_attributes_for :cartridge_courses, reject_if: proc { |a| a['is_selected'] != '1' }
end
