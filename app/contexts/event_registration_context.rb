class EventRegistrationContext
  attr_reader :courses,
              :event,
              :event_registration,
              :selected_course_ids,
              :stripe_token,
              :user

  def initialize args={}
    if args[:user].blank?
      raise ArgumentError, 'user is required'
    elsif args[:event].blank?
      raise ArgumentError, 'event is required'
    elsif args[:selected_course_ids].blank?
      raise ArgumentError, 'selected_course_ids is required'
    elsif args[:stripe_token].blank?
      raise ArgumentError, 'stripe_token is required'
    end

    @user = args[:user]
    @event = args[:event]
    @courses = args[:courses] || @event.courses.to_a
    @selected_course_ids = args[:selected_course_ids]
    @stripe_token = args[:stripe_token]
    @event_registration =
      args[:event_registration] ||
      EventRegistration.new(user: @user, event: @event)
  end

  def call
    #REVIEW it would be cool to replace the below implementation with something
    # like:
    #
    # AssemblyLine.new(EventRegistrationContext)
    #   .validate(targets)
    #   .make_payment(user, stripe_token, event_registration)
    #   .finalize_registration(targets)
    #   .result
    #
    # where each method is defined in EventRegistrationContext and handles
    # performing the action and throwing/handling errors. AssemblyLine itself
    # delegates to the methods, but wraps them in its own function that:
    # - puts the result of each function call into a Result object
    # - returns itself (for chaining)
    # - supplies the result getter/method
    # - aborts when it encounters an error (errors that don't cause aborts
    # should be handled in the ERC functions)
    #
    # For this to stay simple, the Result object should maybe just have attrs
    # named after the functions, each with pass/fail and message properties
    # that can be interpreted by the EventRegistrationContext#call and handled
    # properly (such as a more user-friendly error explanation or determining
    # whether a failure at some step constitutes a total failure or something
    # that was optional and can be lived with).

    result = Result.new

    sel_courses = selected_courses
    course_regs = sel_courses.map { |c|
      user.registrations.build course: c
    }

    total_price = calculate_price
    targets = course_regs + [event_registration]

    validation_result = validate_targets(targets + [user])
    result.valid = validation_result[:valid]
    result.validation_errors = validation_result[:error_messages]
    return result unless result.valid

    customer = StripeService.find_or_create_customer user
    if customer.nil?
      result.payment_succeeded = false
      result.message = StripeService::MESSAGES[:try_again]
      return result
    end

    begin
      card = StripeService.create_payment_source user, customer, stripe_token
    rescue => e
      result.payment_succeeded = false
      result.message =
        if e.class == Stripe::CardError
          StripeService::MESSAGES[:card_declined]
        else
          StripeService::MESSAGES[:try_again]
        end
      return result
    end

    charge = StripeService.charge(
      customer: customer,
      source: card,
      amount: total_price,
      description: "#{event.title}: #{sel_courses.map(&:title).join(', ')}"
    )
    if charge.nil?
      result.payment_succeeded = false
      result.message = StripeService::MESSAGES[:try_again]
    else
      result.payment_succeeded =
        charge.status == StripeService::CHARGE_SUCCESS_STATUS
    end

    return result if !result.payment_succeeded

    event_registration.amount_paid = total_price
    event_registration.stripe_id = charge.id

    result.saved = save_targets targets

    result
  end

  def selected_courses
    courses.find_all {|c| selected_course_ids.include? c.id}
  end

  def calculate_price
    sel_courses = selected_courses
    total_price = sel_courses.sum(&:base_price)

    event.discounts.each do |discount|
      course_list = discount.course_list.split(',').map(&:to_i)
      discountable, not_discountable = sel_courses.partition {|c|
        course_list.include? c.id
      }

      discount_applies = (discountable.length == course_list.length)
      if discount_applies
        price_with_discount = discount.price + not_discountable.reduce(0) { |total, c|
          total += c.base_price
          total
        }

        if price_with_discount < total_price
          total_price = price_with_discount
        end
      end
    end

    total_price
  end

  def validate_targets targets
    valid = targets.map(&:valid?).all?
    error_messages = targets.reduce({}) do |out, target|
      key = class_to_sym target
      if not out.has_key? key
        out[key] = target.errors.messages
      end
      out
    end

    { valid: valid, error_messages: error_messages }
  end

  def save_targets targets
    all_saved = false

    ActiveRecord::Base.transaction do
      all_saved = targets.map(&:save).all?
      raise ActiveRecord::Rollback unless all_saved
    end

    all_saved
  end


  private

  def class_to_sym obj
    obj.class.to_s.underscore.to_sym
  end

  class Result
    attr_accessor :valid,
                  :validation_errors,
                  :payment_succeeded,
                  :saved,
                  :message

    def initialize
      @valid = false
      @validation_errors = {}
      @payment_succeeded = false
      @saved = false
      @message = ''
    end

    def successful?
      [valid, payment_succeeded, saved].all?
    end
  end
end