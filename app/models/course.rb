class Course < ActiveRecord::Base
  belongs_to :event
  has_many :registrations, inverse_of: :course
  has_many :users, through: :registrations
  has_many :course_contract_plans, inverse_of: :course
  has_many :contract_plans, through: :course_contract_plans

  validates :title, presence: true

  DEFAULT_DATE_FORMAT = "%b %d, %Y"

  def ongoing?
    start_date.nil? and end_date.nil?
  end

  def display_dates
    return "" if ongoing?
    "#{start_date.strftime(DEFAULT_DATE_FORMAT)} to #{end_date.strftime(DEFAULT_DATE_FORMAT)}"
  end
end
