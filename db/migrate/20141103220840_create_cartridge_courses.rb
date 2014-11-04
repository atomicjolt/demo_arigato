class CreateCartridgeCourses < ActiveRecord::Migration
  def change
    create_table :cartridge_courses do |t|
      t.integer :canvas_load_id
      t.string :category
      t.integer :source_id
      t.string :short_name
      t.string :long_name
      t.integer :sub_account
      t.string :course_file
      t.timestamps
    end
  end
end