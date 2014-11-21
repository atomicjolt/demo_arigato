class DropCartridgeCourses < ActiveRecord::Migration
  def change
    drop_table :cartridge_courses
  end
end
