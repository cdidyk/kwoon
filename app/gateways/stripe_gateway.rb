require_relative '../../lib/domain/i_payment_gateway'

class StripeGateway
  include Domain::IPaymentGateway

  def process_payment
    return false
  end
end
