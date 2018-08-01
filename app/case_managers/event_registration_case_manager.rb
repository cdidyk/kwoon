require_relative '../../lib/domain/use_cases/event_registration'

class EventRegistrationCaseManager
  attr_reader :user_params, :course_reg_params,
              :payment_token, :event_id

  def initialize args={}
    if args[:user_params].blank?
      raise ArgumentError, "user_params key is required"
    end
    if args[:course_reg_params].blank?
      raise ArgumentError, "course_reg_params key is required"
    end
    if args[:payment_token].blank?
      raise ArgumentError, "payment_token key is required"
    end
    if args[:event_id].blank?
      raise ArgumentError, "event_id key is required"
    end

    @user_params = args[:user_params]
    @course_reg_params = args[:course_reg_params]
    @payment_token = args[:payment_token]
    @event_id = args[:event_id]
  end

  def call
    user =
      User.where(email: user_params[:email]).first ||
      User.new(user_params)

    event = Event.find_with_courses_discounts @event_id

    selected_courses = event.courses.find_all do |c|
      course_reg_params[:course_ids].include? c.id.to_s
    end

    use_case = Domain::UseCases::EventRegistration.new(
      event: event.to_dto(include: [:courses, :discounts]),
      payment_gateway: StripeGateway.new,
      payment_token: payment_token,
      registrant: user.to_dto,
      selected_courses: selected_courses.map(&:to_dto)
    )
    uc_result = use_case.call

    event_reg_dto = uc_result.data.dig :dtos, :event_registration
    if !event_reg_dto.blank?
      event_registration = EventRegistration.from_dto event_reg_dto
      event_registration.event = event
      event_registration.user = user

      user.attributes.each do |attr,v|
        user.send "#{attr}=", event_reg_dto.dig("registrant", attr)
      end

      course_regs = event_reg_dto["selected_courses"].map do |dto|
        user.registrations.build course_id: dto["id"]
      end
    else
      event_registration = EventRegistration.new user: user, event: event

      if !uc_result.data[:customer_id].blank?
        user.stripe_id = uc_result.data[:customer_id]
      end
    end

    # REVIEW: is it possible to have a charge_id but no event registration?
    # In that case, we lose the amount_paid value...
    if !uc_result.data[:charge_id].blank?
      event_registration.stripe_id = uc_result.data[:charge_id]
    end

    succeeded = uc_result.successful?
    if uc_result.successful?
      begin
        ActiveRecord::Base.transaction do
          targets = course_regs + [event_registration]
          raise ActiveRecord::Rollback unless targets.map(&:save).all?
        end
      rescue ActiveRecord::Rollback => e
        succeeded = false
      end
    end

    return {
      succeeded: succeeded,
      presenter: OpenStruct.new(
        user: user,
        event: event,
        courses: event.courses,
        event_registration: event_registration,
        course_reg_ids: course_reg_params[:course_ids],
        custom_validations: {}
      )
    }
  end
end
