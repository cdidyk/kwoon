class EventDiscount < ApplicationRecord
  belongs_to :event

  def undiscounted_price
    course_ids = course_list.split(',')
    courses = Course.find course_ids
    courses.sum(&:base_price)
  end

  def display?
    not description.blank?
  end
end
