class CreateCourseContractPlans < ActiveRecord::Migration
  def change
    create_table :course_contract_plans do |t|
      t.integer :course_id, null: false
      t.integer :contract_plan_id, null: false

      t.index :course_id
      t.index :contract_plan_id
    end
  end
end
