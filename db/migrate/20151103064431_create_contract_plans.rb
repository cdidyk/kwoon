class CreateContractPlans < ActiveRecord::Migration
  def change
    create_table :contract_plans do |t|
      t.string :title, null: false
      t.integer :total, null: false
      t.integer :deposit, null: false
      t.integer :payment_amount
      t.string :stripe_id
      t.timestamps null: false

      t.index :stripe_id
    end
  end
end
