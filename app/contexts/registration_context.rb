class RegistrationContext
  attr_reader :contract,
              :course,
              :payment_plan,
              :registration,
              :stripe_token,
              :user

  MESSAGES = {
    try_again: "There was a problem processing your registration and you weren't charged. Please try again in a few minutes. If the problem persists, contact Sifu Chris Didyk at cdidyk@gmail.com",
    card_declined: "Your card was declined. If this continues to happen, please try a different card."
  }

  def target_actors
    [@contract, @registration]
  end


  def initialize args={}
    if args[:user].blank?
      raise ArgumentError, "user is required"
    elsif args[:course].blank?
      raise ArgumentError, "course is required"
    elsif args[:registration].blank?
      raise ArgumentError, "registration is required"
    elsif args[:payment_plan].blank?
      raise ArgumentError, "payment plan is required"
    elsif args[:stripe_token].blank?
      raise ArgumentError, "stripe token is required"
    end

    @user = args[:user]
    @course = args[:course]
    @payment_plan = args[:payment_plan]
    @registration = args[:registration]
    @stripe_token = args[:stripe_token]
    @contract = Contract.new(
      user: @user,
      status: Contract::STATUSES[:future],
      start_date: @course.start_date,
      end_date: @course.end_date,
      title: @payment_plan.title,
      total: @payment_plan.total,
      balance: @payment_plan.total,
      payment_amount: @payment_plan.payment_amount
    )
  end


  #TODO: these procedural calls should probably just take the result obj as a
  # param and modify it
  def call
    result = Result.new

    validation_result = validate_targets
    result.valid = validation_result[:valid]
    result.validation_errors = validation_result[:error_messages]
    return result unless result.valid

    charge_result = process_deposit
    result.payment_succeeded = charge_result[:payment_succeeded]
    result.message = charge_result[:message] if charge_result[:message]
    return result unless result.payment_succeeded

    result.saved = save_targets
    return result unless result.saved

    result.subscribed = subscribe_to_plan charge_result[:customer]

    result
  end


  def validate_targets
    valid = target_actors.map(&:valid?).all?
    error_messages = target_actors.inject({}) do |out, actor|
      out[class_to_sym actor] = actor.errors.messages
      out
    end

    { valid: valid, error_messages: error_messages }
  end


  #REVIEW: look to break this up and ensure a consistent object is returned
  def process_deposit
    customer = nil
    if @user.stripe_id
      begin
        customer = Stripe::Customer.retrieve @user.stripe_id
      rescue Stripe::InvalidRequestError => e
        Rails.logger.warn "Unable to retrieve Stripe Customer with id: #{@user.stripe_id} for user: #{@user.name} (id: #{@user.id}). Will attempt to create a new Stripe Customer.\n original error: #{e.inspect}"
      end
    end

    if customer.respond_to?(:deleted) and customer.deleted
      Rails.logger.warn "Stripe Customer with id: #{@user.stripe_id} for user: #{@user.name} (id: #{@user.id}) waas deleted. Will attempt to create a new Stripe Customer."
      customer = nil
    end

    if customer.blank?
      begin
        customer = Stripe::Customer.create(
          email: @user.email,
          description: @user.name
        )
      rescue Stripe::InvalidRequestError => e
        Rails.logger.error "Unable to create Stripe Customer for user: #{@user.name} (id: #{@user.id}). Aborting payment transaction.\n original error: #{e.inspect}"
        return {
          payment_succeeded: false,
          message: MESSAGES[:try_again]
        }
      end

      #TODO: log but continue if update fails
      @user.update stripe_id: customer.id
    end

    begin
      card = customer.sources.create(
        source: @stripe_token
      )
    rescue Stripe::CardError => e
      Rails.logger.error "Card declined for user: #{@user.name} (id: #{@user.id}, stripe_id: #{@user.stripe_id}). Aborting payment transaction.\n original error: #{e.inspect}"
      return {
        payment_succeeded: false,
        message: MESSAGES[:card_declined]
      }
    rescue Stripe::InvalidRequestError => e
      Rails.logger.error "Unable to create Stripe Card for user: #{@user.name} (id: #{@user.id}, stripe_id: #{@user.stripe_id}). Aborting payment transaction.\n original error: #{e.inspect}"
      return {
        payment_succeeded: false,
        message: MESSAGES[:try_again]
      }
    end

    # Don't charge if there's no deposit to charge
    if @payment_plan.deposit.blank? or @payment_plan.deposit <= 1
      #REVIEW: consider renaming payment_succeeded. It's a little weird for it
      # to be true here when there is no payment attempted, but it's used to
      # represent the success of #process_deposit.
      #
      # Maybe rethink the charge result object, too, and at least have it return
      # something consistently-structured.
      return {
        payment_succeeded: true,
        customer: customer,
        card: card,
        charge: nil
      }
    end

    # Charge deposit
    desc =
      if @payment_plan.payment_amount > 0
        "#{@course.title} Deposit $#{@payment_plan.deposit/100}"
      else
        "#{@course.title} Pay-in-full $#{@payment_plan.deposit/100}"
      end

    begin
      charge = Stripe::Charge.create(
        amount: @payment_plan.deposit,
        currency: 'usd',
        customer: customer.id,
        source: card.id,
        description: desc
      )
    rescue Stripe::InvalidRequestError => e
      Rails.logger.error "Unable to create Stripe Charge for user: #{@user.name} (id: #{@user.id}, stripe_id: #{@user.stripe_id}). Aborting payment transaction.\n original error: #{e.inspect}"
      return {
        payment_succeeded: false,
        message: MESSAGES[:try_again]
      }
    end

    @contract.make_payment charge.amount

    {
      payment_succeeded: charge.status == 'succeeded',
      customer: customer,
      card: card,
      charge: charge
    }

  rescue Stripe::StripeError => e
    Rails.logger.error "Unable to charge a student #{@user.id} #{@user.name} during registration for course #{@course.id} #{@course.title}.\n  #{e.class.to_s}: #{e.message}\n#{e.backtrace.join("\n")}"
    {payment_succeeded: charge && charge.status == 'succeeded'}
  end


  def save_targets
    all_saved = false

    ActiveRecord::Base.transaction do
      all_saved = target_actors.map(&:save).all?
      raise ActiveRecord::Rollback unless all_saved
    end

    all_saved
  end


  def subscribe_to_plan customer
    return true if @contract.paid_off?

    #TODO: double check that the course's first_installment_date is set and
    # catch separately if it isn't

    begin
      subscription = customer.subscriptions.create(
        plan: @payment_plan.stripe_id,
        metadata: {
          contract_id: @contract.id
        },
        trial_end: @course.first_installment_date.to_i
      )
    rescue Stripe::InvalidRequestError => e
      Rails.logger.error "Unable to create subscription for user: #{@user.name} (id: #{@user.id}) and contract: #{@contract.id}. Continuing on because a separate charge may have still gone through, but no installment payments will be made!"
    end

    (!subscription.blank? && !subscription.id.blank?).tap do |subscribed|
      if subscribed
        @contract.update_attribute :stripe_id, subscription.id
      end
    end
  end



  private

  def class_to_sym obj
    obj.class.to_s.underscore.to_sym
  end


  class Result
    attr_accessor :valid, :validation_errors, :payment_succeeded,
                  :saved, :subscribed, :message

    def initialize
      @valid = false
      @validation_errors = {}
      @payment_succeeded = false
      @saved = false
      @subscribed = false
      @message = ""
    end

    def successful?
      [valid, payment_succeeded, saved, subscribed].all?
    end
  end

end
