RSpec.describe RegistrationMailer, type: :mailer do
  describe ".confirmation" do
    it "generates a confirmation email to the user" do
      user = build :user
      course = build :course

      email = RegistrationMailer.
        confirmation(user, course).
        deliver_now

      expect(email.from).to eq(["no-reply@shaolinstpete.com"])
      expect(email.to).to eq([user.email])
      expect(email.subject).to match(/registration/i)
    end

  end

  describe ".invite" do
    it "generates an email inviting the user to register for the course" do
      user = build :user
      course = double Course, id: 99, title: 'Super Flying Kung Fu'
      reg_token = TokenService.generate_course_invite_token user: user, course: course

      email = RegistrationMailer.
        invite(user, course, reg_token).
        deliver_now

      expect(email.from).to eq(["no-reply@shaolinstpete.com"])
      expect(email.to).to eq([user.email])
      expect(email.subject).to match(/#{course.title}/)
      expect(email.body).to match(/#{reg_token}/)
    end
  end
end
