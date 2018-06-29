class Event < ApplicationRecord
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

  #TODO: test
  def reg_count_by_course
    course_titles_by_id = courses.reduce({}) do |out, course|
      out["#{course.id}"] = course.title
      out
    end

    by_course_id =
      Registration
        .where("course_id IN (?)", course_titles_by_id.keys)
        .group(:course_id)
        .count

    by_course_id.reduce({}) do |out, (course_id, course_count)|
      out[course_titles_by_id["#{course_id}"]] = course_count
      out
    end
  end

  def total_paid
    registrations.sum('amount_paid')
  end
end
