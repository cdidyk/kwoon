module Domain
  module IPaymentGateway
    # args (only description is optional):
    #  customer_rep (with stripe_id, name, and email)
    #  amount
    #  payment_token
    #  description
    def process_payment args={}
      raise NotImplementedError, "process_payment is an abstract method that must be implemented in whatever includes IPaymentGateway"
    end
  end
end
