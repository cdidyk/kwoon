class CreateEventDiscounts < ActiveRecord::Migration
  def change
    create_table :event_discounts do |t|
      t.references :event, index: true, foreign_key: true
      t.string :description
      t.string :course_list
      t.integer :price
    end
  end
end
