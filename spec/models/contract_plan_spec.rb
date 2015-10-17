RSpec.describe ContractPlan, type: :model do
  let(:cp) { ContractPlan.new }

  context "validations" do
    it "has a title" do
      expect(cp).to validate_presence_of(:title)
    end

    it "has a total" do
      expect(cp).to validate_presence_of(:total)
    end

    it "has a deposit" do
      expect(cp).to validate_presence_of(:deposit)
    end
  end
end
