class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.text :content
      t.integer :canvas_load_id
      t.integer :canvas_course_id
      t.integer :canvas_account_id
      t.timestamps
    end
    add_index :courses, :canvas_load_id
  end
end