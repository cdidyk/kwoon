class ContractPlan < ActiveRecord::Base
  has_many :course_contract_plans, inverse_of: :contract_plan
  has_many :courses, through: :course_contract_plans

  validates :title, presence: true
  validates :total, presence: true
  validates :deposit, presence: true

  def to_select_option
    [title, id]
  end
end
