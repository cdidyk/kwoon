require_relative './base'

module Domain
  module Entities
    class Registrant < Base
      attr_accessor :name, :email, :payment_gateway_id

      def attributes
        super.merge(
          'name' => name,
          'email' => email,
          'payment_gateway_id' => payment_gateway_id
        )
      end
    end
  end
end
