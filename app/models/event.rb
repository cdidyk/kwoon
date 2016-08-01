class Event < ActiveRecord::Base
  has_many :courses
  has_many :discounts, class_name: 'EventDiscount'
  has_many :registrations, class_name: 'EventRegistration', inverse_of: :event
  has_many :users, through: :event_registrations

  validates :title, presence: true

  #TODO: DRY up -this is in Course, too
  DEFAULT_DATE_FORMAT = "%b %d, %Y"

  def display_dates
    "#{start_date.strftime(DEFAULT_DATE_FORMAT)} to #{end_date.strftime(DEFAULT_DATE_FORMAT)}"
  end
end