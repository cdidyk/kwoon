RSpec.describe User, type: :model do
  context "validations" do
    let(:contract) { Contract.new }

    it "has a title" do
      expect(contract).to validate_presence_of(:title)
    end

    it "has a user" do
      expect(contract).to validate_presence_of(:user)
    end

    it "has a status" do
      expect(contract).to validate_presence_of(:status)
    end

    it "has a start date" do
      expect(contract).to validate_presence_of(:start_date)
    end

    it "has an end date" do
      expect(contract).to validate_presence_of(:end_date)
    end

    it "has a total" do
      expect(contract).to validate_presence_of(:total)
    end

    it "has a balance" do
      expect(contract).to validate_presence_of(:balance)
    end
  end
end
