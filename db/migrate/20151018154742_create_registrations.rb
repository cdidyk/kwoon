class CreateRegistrations < ActiveRecord::Migration
  def change
    create_table :registrations do |t|
      t.integer :user_id, null: false
      t.integer :course_id, null: false
      t.index :user_id
      t.index :course_id
    end
  end
end
