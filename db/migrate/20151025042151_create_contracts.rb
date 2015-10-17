class CreateContracts < ActiveRecord::Migration
  def change
    create_table :contracts do |t|
      t.integer :user_id, null: false
      t.string :title, null: false
      t.string :status, null: false
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.integer :total, null: false
      t.integer :balance, null: false
      t.integer :payment_amount
      t.string :stripe_id
      t.timestamps null: false

      t.index [:user_id, :status]
    end
  end
end
