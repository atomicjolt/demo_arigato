class CreateCanvasLoads < ActiveRecord::Migration
  def change
    create_table :canvas_loads do |t|
      t.integer :user_id
      t.string :canvas_domain, limit: 2048
      t.string :suffix
      t.string :sis_id
      t.boolean :lti_attendance
      t.boolean :lti_chat
      t.boolean :course_welcome
      t.timestamps
    end
    add_index :canvas_loads, :user_id
  end
end
