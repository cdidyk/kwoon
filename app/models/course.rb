class Course < ActiveRecord::Base
  has_many :registrations, inverse_of: :course
  has_many :users, through: :registrations
  has_many :course_contract_plans, inverse_of: :course
  has_many :contract_plans, through: :course_contract_plans

  validates :title, presence: true

  def display_dates
    "#{start_date} to #{end_date}"
  end
end
