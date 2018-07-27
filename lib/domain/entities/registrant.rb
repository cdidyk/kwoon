require_relative './base'

module Domain
  module Entities
    class Registrant < Base
      # TODO: change stripe_id to payment_gateway_id throughout system
      attr_accessor :name, :email, :stripe_id

      def attributes
        super.merge(
          'name' => name,
          'email' => email,
          'stripe_id' => stripe_id
        )
      end
    end
  end
end
