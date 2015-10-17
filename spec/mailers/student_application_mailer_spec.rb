RSpec.describe StudentApplicationMailer, type: :mailer do
 describe ".confirmation" do
   it "generates a confirmation email to the user" do
     user = build :user

     email = StudentApplicationMailer.
       confirmation(user).
       deliver_now

     expect(email.from).to eq(["no-reply@shaolinstpete.com"])
     expect(email.to).to eq([user.email])
     expect(email.subject).to match(/application received/i)
   end

 end

 describe ".new_application" do
   it "generates an email to the sifu with the application info" do
     application = build :application

     email = StudentApplicationMailer.
       new_application(application).
       deliver_now

     expect(email.from).to eq(["no-reply@shaolinstpete.com"])
     expect(email.to).to eq([ENV['SIFU_EMAIL']])
     expect(email.subject).to match(/Application/)
     expect(email.body.to_s).to match(/Wahnam Courses/)
   end

 end
end
