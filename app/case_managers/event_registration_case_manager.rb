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
      course_reg_params[:course_ids].include? c.id
    end

    # REVIEW: perhaps the payment gateway can store the payment token and then
    # the latter wouldn't need to be passed in
    result = Domain::UseCases::EventRegistration.new(
      registrant: user.to_dto,
      payment_gateway: StripeGateway.new,
      payment_token: payment_token,
      event: event.to_dto(include: [:courses, :discounts]),
      selected_courses: selected_courses.map(&:to_dto)
    ).call

    # if result is good, persist changes to models
    #   update the affected models
    #   prepare the presenter
    # else
    #   put the failure into terms the controller can reason about to
    #   determine whether to, say, re-render a form with validation marks
    #   or issue a general "something went wrong" message and report it to the
    #   developer
    # end
  end
end
