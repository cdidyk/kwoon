class StudentApplicationMailer < ApplicationMailer
  default from: "no-reply@shaolinstpete.com"

  def confirmation user
    @user = user
    mail to: user.email,
         subject: "Shaolin Wahnam St Pete - Application Received"
  end

  def new_application application
    @application = application
    mail to: ENV['SIFU_EMAIL'],
         subject: "Kung Fu Application: #{application.user.name}"
  end
end
