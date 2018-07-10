class TokenService
  def self.encode(payload, ttl_in_minutes = 60 * 24 * 90)
    payload[:exp] = ttl_in_minutes.minutes.from_now.to_i
    JWT.encode(payload, ENV['JWT_SECRET'],'HS256')
  end

  def self.decode(token, leeway = nil)
    decoded = JWT.decode(token, ENV['JWT_SECRET'])
    ActiveSupport::HashWithIndifferentAccess.new decoded[0]
  end

  def self.generate_course_invite_token args={}
    if args[:user].blank?
      raise ArgumentError, "user param is required"
    elsif args[:course].blank?
      raise ArgumentError, "course param is required"
    end

    payload = {
      context: 'course invite',
      user_id: args[:user].id,
      course_id: args[:course].id
    }

    if args[:ttl_in_minutes]
      encode payload, args[:ttl_in_minutes]
    else
      encode payload
    end
  end
end
