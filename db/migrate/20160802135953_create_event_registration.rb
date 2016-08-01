class CreateEventRegistration < ActiveRecord::Migration
  def change
    create_table :event_registrations do |t|
      t.references :event, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.integer :amount_paid
      t.string :stripe_id
    end
  end
end
