RSpec.describe TokenService, type: :service do
  describe ".encode" do
    it "encodes to JWT" do
      allow(JWT).to receive(:encode).and_return("NUMBERS!")
      encoded = described_class.encode(user_id: 14)
      expect(encoded).to eq("NUMBERS!")
    end
  end

  describe ".decode" do
    it "decodes via JWT" do
      expect(JWT)
        .to receive(:decode).with('encoded token', anything).and_return []
      described_class.decode('encoded token')
    end

    it "returns only the decoded token's payload (including 'exp', which is added automatically)" do
      token = described_class.encode(user_id: 14)
      result = described_class.decode(token)
      expect(result.keys).to eq(['user_id', 'exp'])
      expect(result['user_id']).to eq(14)
    end
  end

  describe ".generate_course_invite_token" do
    let(:user) { double User, id: 14 }
    let(:course) { double Course, id: 33 }

    it "requires a user param" do
      expect {
        TokenService.generate_course_invite_token course: course
      }.to raise_error(ArgumentError, /user/)
    end

    it "requires a course param" do
      expect {
        TokenService.generate_course_invite_token user: user
      }.to raise_error(ArgumentError, /course/)
    end


    it "generates a JWT with a 'course invite' context, course id, user id, and expiration dateof 3 months" do
      now = Time.zone.parse "July 4, 2020"
      allow(Time.zone).to receive(:now).and_return now
      three_months_from_now_in_min = (60 * 24 * 90).minutes.from_now.to_i

      token = TokenService.generate_course_invite_token user: user, course: course
      decoded_token = TokenService.decode token
      expect(decoded_token[:context]).to eq('course invite')
      expect(decoded_token[:user_id]).to eq(user.id)
      expect(decoded_token[:course_id]).to eq(course.id)
      expect(decoded_token[:exp]).to eq(three_months_from_now_in_min)
    end
  end
end
