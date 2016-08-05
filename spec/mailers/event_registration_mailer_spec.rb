RSpec.describe EventRegistrationMailer, type: :mailer do
  let(:event_reg) {
    build :event_registration, amount_paid: 60000
  }
  let(:event) { event_reg.event }
  let(:courses) {
    [
      build(:event_course,
            event: event,
            title: 'First Course',
            start_date: event.start_date,
            end_date: event.start_date,
            base_price: 30000
           ),
      build(:event_course,
            event: event,
            title: 'Second Course',
            start_date: event.end_date,
            end_date: event.end_date,
            base_price: 30000
           )
    ]
  }

  describe ".confirmation" do
    it "generates a confirmation email to the user" do
      allow(event_reg)
        .to receive(:selected_courses).
             and_return courses

      email = EventRegistrationMailer.
              confirmation(event_reg).
              deliver_now

      expect(email.from).to eq(["no-reply@shaolinstpete.com"])
      expect(email.to).to eq([event_reg.user.email])
      expect(email.subject).to match(/registration/i)
    end
  end

  describe ".new_registration" do
    it "generates an email to the sifu describing the new registration" do
      allow(event_reg)
        .to receive(:selected_courses).
             and_return courses

      email = EventRegistrationMailer.
              new_registration(event_reg).
              deliver_now

      expect(email.from).to eq(["no-reply@shaolinstpete.com"])
      expect(email.to).to eq([ENV['SIFU_EMAIL']])
      expect(email.subject).to match(/Registration/i)
      expect(email.body.to_s).to match(/received.*registration/)
    end
  end
end