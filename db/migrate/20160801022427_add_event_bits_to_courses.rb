class AddEventBitsToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :base_price, :integer
    add_column :courses, :event_id, :integer
    add_column :courses, :schedule_desc, :string
    add_foreign_key :courses, :events
    add_index :courses, :event_id
  end
end
