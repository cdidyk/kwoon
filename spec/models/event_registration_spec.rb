RSpec.describe EventRegistration, type: :model do
  let(:event_registration) { build :event_registration }

  context "validations" do
    it "has a user" do
      expect(event_registration).to validate_presence_of(:user)
    end

    it "its user is valid" do
      event_registration.user.email = ''
      expect(event_registration).to_not be_valid
      expect(event_registration.errors.messages).to include(user: ['is invalid'])
    end

    it "has an event" do
      expect(event_registration).to validate_presence_of(:event)
    end

    it "its event is valid" do
      event_registration.event.title = ''
      expect(event_registration).to_not be_valid
      expect(event_registration.errors.messages).to include(event: ['is invalid'])
    end
  end
end
