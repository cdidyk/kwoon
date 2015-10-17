class CourseContractPlan < ActiveRecord::Base
  belongs_to :course, inverse_of: :course_contract_plans
  belongs_to :contract_plan, inverse_of: :course_contract_plans

  validates :course, presence: true
  validates :contract_plan, presence: true
end
