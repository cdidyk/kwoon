class EventRegistrationMailer < ApplicationMailer
  default from: "no-reply@shaolinstpete.com"

  def confirmation event_registration
    @event_registration = event_registration
    @user = event_registration.user
    @event = event_registration.event
    @selected_courses = event_registration.selected_courses

    mail to: @user.email,
         subject: "Shaolin Wahnam St Pete - Registration Receipt"
  end

  def new_registration event_registration
    @event_registration = event_registration
    @user = event_registration.user
    @event = event_registration.event
    @selected_courses = event_registration.selected_courses
    @event_registration_count = @event.registrations.count
    @course_registration_count = @event.reg_count_by_course

    mail to: ENV['SIFU_EMAIL'],
         subject: "Shaolin Wahnam St Pete - #{@event.title} Registration by #{@user.name}"
  end
end