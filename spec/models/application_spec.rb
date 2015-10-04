RSpec.describe Application, type: :model do
  context "validations" do
    let(:application) { Application.new }

    it "has a user" do
      expect(application).to validate_presence_of(:user)
    end

    it "has a phone number" do
      expect(application).to validate_presence_of(:phone)
    end

    it "has an address" do
      expect(application).to validate_presence_of(:address)
    end

    it "has an emergency contact name" do
      expect(application).to validate_presence_of(:emergency_contact_name)
    end

    it "has an emergency contact phone" do
      expect(application).to validate_presence_of(:emergency_contact_phone)
    end

    it "describes previous Wahnam courses taken" do
      expect(application).to validate_presence_of(:wahnam_courses)
    end

    it "describes previous martial arts experience" do
      expect(application).to validate_presence_of(:martial_arts_experience)
    end

    it "describes relevant health issues" do
      expect(application).to validate_presence_of(:health_issues)
    end

    it "has a bio" do
      expect(application).to validate_presence_of(:bio)
    end

    it "has an explanation of why the student wants to learn Shaolin Kung Fu" do
      expect(application).to validate_presence_of(:why_shaolin)
    end

    it "agrees to live by the 10 Shaolin Laws" do
      expect(application).to validate_acceptance_of(:ten_shaolin_laws)
    end
  end
end
