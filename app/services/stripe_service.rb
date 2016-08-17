class StripeService
  CHARGE_SUCCESS_STATUS = 'succeeded'

  MESSAGES = {
    try_again: "There was a problem processing your registration and you weren't charged. Please try again in a few minutes. If the problem persists, contact Sifu Chris Didyk at sifu.chris@shaolinstpete.com",
    card_declined: "Your card was declined. If this continues to happen, please try a different card."
  }

  def self.find_or_create_customer user
    customer = nil
    if user.stripe_id
      begin
        customer = Stripe::Customer.retrieve user.stripe_id
      rescue Stripe::InvalidRequestError => e
        Rails.logger.warn "Unable to retrieve Stripe Customer with id: #{user.stripe_id} for user: #{user.name} (id: #{user.id}). Will attempt to create a new Stripe Customer.\n original error: #{e.inspect}"
      end
    end

    if customer.respond_to?(:deleted) and customer.deleted
      Rails.logger.warn "Stripe Customer with id: #{user.stripe_id} for user: #{user.name} (id: #{user.id}) was deleted. Will attempt to create a new Stripe Customer."
      customer = nil
    end

    if customer.blank?
      begin
        customer = Stripe::Customer.create(
          email: user.email,
          description: user.name
        )
      rescue Stripe::InvalidRequestError => e
        Rails.logger.error "Unable to create Stripe Customer for user: #{user.name} (id: #{user.id}). Aborting payment transaction.\n original error: #{e.inspect}"
      else
        #TODO: log but continue if update fails
        user.update stripe_id: customer.id
      end
    end

    customer
  end

  # TODO: move user out. StripeService should throw relevant errors and provide
  # relevant info but whatever uses it knows the context for how to interpret
  # those errors into meaningful messages.
  def self.create_payment_source user, customer, stripe_token
    customer.sources.create(
      source: stripe_token
    )
  rescue Stripe::CardError => e
    Rails.logger.error "Card declined for user: #{user.name} (id: #{user.id}, stripe_id: #{user.stripe_id}). Aborting payment transaction.\n original error: #{e.inspect}"
    raise
  rescue Stripe::InvalidRequestError => e
    Rails.logger.error "Unable to create Stripe Card for user: #{user.name} (id: #{user.id}, stripe_id: #{user.stripe_id}). Aborting payment transaction.\n original error: #{e.inspect}"
    raise
  end


  # attrs are:
  # - customer
  # - source
  # - amount
  # - description
  # - user
  #
  # TODO: just return the Stripe::Charge object itself. It will provide a
  # consistent return value and should have enough info on it to determine what
  # type of message to display to the user (including failure code and message).
  # The logging should happen in the context or whatever else uses
  # StripeService.charge, since it will know the proper context and info to make
  # a good error message. StripeService.charge should just throw its errors.
  def self.charge attrs = {}
    charge = nil

    # don't charge if there's no amount to charge
    return charge if attrs[:amount] == 0

    begin
      charge = Stripe::Charge.create(
        amount: attrs[:amount],
        currency: 'usd',
        customer: attrs[:customer].id,
        source: attrs[:source].id,
        description: attrs[:description]
      )
    rescue Stripe::InvalidRequestError => e
      Rails.logger.error "Unable to create Stripe Charge for user: #{attrs[:user].name} (id: #{attrs[:user].id}, stripe_id: #{attrs[:user].stripe_id}). Aborting payment transaction.\n original error: #{e.inspect}"
      return {
        payment_succeeded: false,
        message: MESSAGES[:try_again]
      }
    else
      if charge.status != CHARGE_SUCCESS_STATUS
        Rails.logger.error "Stripe Charge created for user: #{attrs[:user].name} (id: #{attrs[:user].id}, stripe_id: #{attrs[:user].stripe_id}), but its status was '#{charge.status}' instead of '#{CHARGE_SUCCESS_STATUS}'. The payment was likely aborted, but this should be checked!"
      end
    end

    charge
  end
end