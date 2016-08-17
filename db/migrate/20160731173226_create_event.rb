class CreateEvent < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.string :location
      t.datetime :start_date
      t.datetime :end_date
      t.timestamps
    end
  end
end
