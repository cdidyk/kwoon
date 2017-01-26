RSpec.describe Application, type: :model do
  context "validations" do
    let(:application) { Application.new }

    it "has a user" do
      expect(application).to validate_presence_of(:user)
    end

    it "has interests" do
      application.valid?
      expect(application.errors[:interests]).to eq(['must be chosen'])
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

  context "#interested_in?" do
    let(:application) {
      Application.new interests: "Shaolin Kung Fu,Shaolin Cosmos Chi Kung"
    }

    it "is true when the application interests include the supplied one" do
      expect(application).to be_interested_in('Shaolin Kung Fu')
    end

    it "is true on case-insensitive match" do
      expect(application).to be_interested_in(' shaolin kung fU')
    end

    it "is false when the application interests don't include the supplied one" do
      expect(application).not_to be_interested_in('Pottery')
    end

    it "is false when there are no interests" do
      expect(Application.new).not_to be_interested_in('Shaolin Kung Fu')
    end
  end
end
