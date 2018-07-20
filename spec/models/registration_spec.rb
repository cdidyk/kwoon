require 'rails_helper'

RSpec.describe Registration, type: :model do
  let(:registration) { build :registration }

  context "validations" do
    it "has a user" do
      expect(registration).to validate_presence_of(:user)
    end

    it "has a course" do
      expect(registration).to validate_presence_of(:course)
    end
  end
end
