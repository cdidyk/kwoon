module Domain
  module IPaymentGateway
    def process_payment
      raise NotImplementedError, "process_payment is an abstract method that must be implemented in whatever includes IPaymentGateway"
    end
  end
end
