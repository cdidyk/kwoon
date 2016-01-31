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

  describe "#paid_off?" do
    let(:contract) { build :contract }

    it "is false when the balance is not 0" do
      expect(contract).to_not be_paid_off
    end

    it "is true when the balance is 0" do
      contract.balance = 0
      expect(contract).to be_paid_off
    end
  end

  describe "#make_payment" do
    it "reduces the balance by the specified amount" do
      contract = build :contract
      original_balance = contract.balance
      contract.make_payment 25000
      expect(contract.balance).to eq(75000)
    end
  end

  describe "#summary" do
    let(:contract) { build :contract, balance: 75000 }

    it "displays the contract's total, balance, and payment amount" do
      expect(contract.summary).to eq("Dates: Jul 15, 2015 - Nov 15, 2015  Total: $1,000.00  Balance: $750.00  Payment Amount: $250.00")
    end
  end
end
