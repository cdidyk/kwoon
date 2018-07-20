require 'rails_helper'

RSpec.describe Course, type: :model do
  context "validations" do
    let(:course) { Course.new }

    it "has a title" do
      expect(course).to validate_presence_of(:title)
    end
  end
end
