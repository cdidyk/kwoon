require 'rails_helper'

RSpec.describe Event, type: :model do
  context "validations" do
    let(:event) { Event.new }

    it "has a title" do
      expect(event).to validate_presence_of(:title)
    end
  end
end
