RSpec.describe User, type: :model do
  context "validations" do
    let(:user) { User.new }

    it "has a name" do
      expect(user).to validate_presence_of(:name)
    end

    it "has a valid, unique email" do
      expect(user).to validate_presence_of(:email)
      expect(user).to(
        validate_email_format_of(:email)
          .with_message("is not a valid email address")
      )
      expect(user).to validate_uniqueness_of(:email)
    end

    it "is valid without a password" do
      user = User.new name: 'Bob', email: 'bob@example.com'
      expect(user).to be_valid
    end

    it "has a password confirmation if it has a password" do
      user.password = "supersecure"
      expect(user).not_to be_valid
      expect(user.errors.messages).to have_key(:password_confirmation)
    end
  end
end
