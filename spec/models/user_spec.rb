RSpec.describe User, type: :model do
  context "validations" do
    let(:user) { User.new }

    it "has a first name" do
      expect(user).to validate_presence_of(:first_name)
    end

    it "has a last name" do
      expect(user).to validate_presence_of(:last_name)
    end

    it "has a valid, unique email" do
      expect(user).to validate_presence_of(:email)
      expect(user).to(
        validate_email_format_of(:email)
          .with_message("is not a valid email address")
      )
      expect(user).to validate_uniqueness_of(:email)
    end
  end
end
