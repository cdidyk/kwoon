require_relative '../../lib/domain/i_payment_gateway'

class StripeGateway
  include Domain::IPaymentGateway

  CHARGE_SUCCESS_STATUS = 'succeeded'

  # TODO: change hardcoded contact
  MESSAGES = {
    try_again: "There was a problem processing your registration and you weren't charged. Please try again in a few minutes. If the problem persists, contact Sifu Chris Didyk at sifu.chris@shaolinstpete.com",
    card_declined: "Your card was declined. If this continues to happen, please try a different card."
    }


  # TODO: review where errors are handled and what raises an error vs. returns a
  # failing result with appropriate message. This will become clearer once a full
  # use case (EventRegistration) is fully implemented throughout the stack.
  #
  # args (only description is optional):
  #  customer_rep (with stripe_id, name, and email)
  #  amount
  #  payment_token
  #  description
  def process_payment args={}
    if args[:customer_rep].nil? || args[:customer_rep].email.nil?
      raise ArgumentError, "args hash requires :customer_rep with attr email"
    end
    if args[:amount].nil?
      raise ArgumentError, "args hash requires :amount (in cents)"
    end
    if args[:payment_token].nil?
      raise ArgumentError, "args hash requires :payment_token"
    end

    begin
      customer = find_or_create_customer args[:customer_rep]
    rescue Stripe::InvalidRequestError => e
      return {
        succeeded: false,
        data: {
          customer_id: nil,
          charge_id: nil,
          messages: {
            customer: ["Unable to find or create the Stripe Customer. Payment canceled."]
          }
        }
      }
    end

    begin
      card = create_payment_source customer, args[:payment_token]
    rescue => e
      error_msg =
        e.class == Stripe::CardError ?
          MESSAGES[:card_declined] :
          MESSAGES[:try_again]
      return {
        succeeded: false,
        data: {
          customer_id: customer.id,
          charge_id: nil,
          messages: { payment_token: [error_msg] }
        }
      }
    end

    begin
      charge = charge_customer(
        amount: args[:amount],
        customer: customer,
        description: args[:description],
        source: card
      )
    rescue Stripe::InvalidRequestError => e
      return {
        succeeded: false,
        data: {
          customer_id: customer.id,
          charge_id: nil,
          messages: { payment_token: ["Unable to create the Stripe Charge. Payment canceled."] }
        }
      }
    end

    return {
      succeeded: true,
      data: {
        customer_id: customer.id,
        charge_id: charge.id
      }
    }
  end


  # TODO: adapt tests from StripeService and remove from StripeService with
  # the goal of having StripeGateway replace StripeService entirely.
  # customer_rep is the domain's Stripe::Customer representative and should
  # have: name, stripe_id, email
  def find_or_create_customer customer_rep
    customer = nil
    if customer_rep.stripe_id
      begin
        customer = Stripe::Customer.retrieve customer_rep.stripe_id
      rescue Stripe::InvalidRequestError => e
        Rails.logger.warn "Unable to retrieve Stripe Customer with id: #{customer_rep.stripe_id} for customer: #{customer_rep.name} (email: #{customer_rep.email}). Will attempt to create a new Stripe Customer.\n original error: #{e.inspect}"
      end
    end

    if customer.respond_to?(:deleted) and customer.deleted
      Rails.logger.warn "Stripe Customer with id: #{customer_rep.stripe_id} for user: #{customer_rep.name} (email: #{customer_rep.email}) was deleted. Will attempt to create a new Stripe Customer."
      customer = nil
    end

    if customer.blank?
      begin
        customer = Stripe::Customer.create(
          email: customer_rep.email,
          description: customer_rep.name
        )
      rescue Stripe::InvalidRequestError => e
        Rails.logger.error "Unable to create Stripe Customer for user: #{customer_rep.name} (email: #{customer_rep.email}).\n original error: #{e.inspect}"
      end
    end

    customer
  end


  def create_payment_source customer, stripe_token
    customer.sources.create(
      source: stripe_token
    )
  rescue Stripe::CardError => e
    Rails.logger.error "Card declined for customer: #{customer.description} (email: #{customer.email}, stripe_id: #{customer.id}). Aborting payment transaction.\n original error: #{e.inspect}"
    raise
  rescue Stripe::InvalidRequestError => e
    Rails.logger.error "Unable to create Stripe Card for customer: #{customer.description} (email: #{customer.email}, stripe_id: #{customer.id}). Aborting payment transaction.\n original error: #{e.inspect}"
    raise
  end


  # attrs should be:
  #   amount: the amount to charge in cents
  #   customer: the Stripe::Customer
  #   description: the charge description
  #   source_id: the id of the Stripe::Source to charge on the customer
  def charge_customer attrs={}
    # TODO: guard for missing attrs

    charge = nil

    # don't charge if there's no amount to charge
    return charge if attrs[:amount] == 0

    begin
      charge = Stripe::Charge.create(
        amount: attrs[:amount],
        currency: 'usd',
        customer: attrs[:customer].id,
        description: attrs[:description],
        source: attrs[:source_id]
      )
    rescue Stripe::InvalidRequestError => e
      Rails.logger.error "Unable to create Stripe Charge for customer: #{attrs[:customer].description} (email: #{attrs[:customer].email}, stripe_id: #{attrs[:customer].id}). Aborting payment transaction.\n original error: #{e.inspect}"
      return nil
    end

    charge
  end
end
