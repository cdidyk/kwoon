class EventDiscount < ActiveRecord::Base
  belongs_to :event

  def undiscounted_price
    course_ids = course_list.split(',')
    courses = Course.find course_ids
    courses.sum(&:base_price)
  end
end
