RSpec.describe CourseContractPlan, type: :model do
  let(:ccp) { build :course_contract_plan }

  context "validations" do
    it "has a course" do
      expect(ccp).to validate_presence_of(:course)
    end

    it "has a contract plan" do
      expect(ccp).to validate_presence_of(:contract_plan)
    end
  end
end
