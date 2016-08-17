class EventRegistration < ActiveRecord::Base
  belongs_to :user, inverse_of: :event_registrations
  belongs_to :event, inverse_of: :registrations

  validates :user, presence: true
  validates :event, presence: true
  validates_associated :user, :event

  #TODO: test
  def selected_courses
    Course
      .joins(:registrations)
      .where(registrations: { user_id: user_id },
             courses: { event_id: event_id })
  end
end