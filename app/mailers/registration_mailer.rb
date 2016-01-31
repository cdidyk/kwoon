class RegistrationMailer < ApplicationMailer
  default from: "no-reply@shaolinstpete.com"

  def confirmation user, course
    @user = user
    @course = course
    mail to: user.email,
         subject: "Shaolin Wahnam St Pete - Registration Receipt"
  end

  def invite user, course, reg_token
    @user = user
    @course = course
    @invite_link = new_course_registration_url(
      course_id: @course.id, reg_token: reg_token
    )
    mail to: user.email,
         subject: "Shaolin Wahnam St Pete - Register for #{@course.title}"
  end

  def new_registration user, course
    @user = user
    @contract = @user.contracts.order("created_at DESC").first
    @course = course
    @course_registrations = course.registrations.count

    mail to: ENV['SIFU_EMAIL'],
         subject: "Shaolin Wahnam St Pete - New Registration by #{@user.name}"
  end
end
