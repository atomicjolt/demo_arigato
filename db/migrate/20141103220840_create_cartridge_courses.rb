class CreateCartridgeCourses < ActiveRecord::Migration
  def change
    create_table :cartridge_courses do |t|
      t.integer :canvas_load_id
      t.string  :course_code
      t.string  :name
      t.string  :sis_course_id
      t.integer :account_id
      t.integer :term_id
      t.datetime :start_at
      t.datetime :end_at
      t.timestamps
    end
    add_index :cartridge_courses, :canvas_load_id
  end
end