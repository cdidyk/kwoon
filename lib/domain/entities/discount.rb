require_relative './base'

module Domain
  module Entities
    class Discount < Base
      attr_accessor :description, :price, :courses

      def attributes
        super.merge(
          'description' => description,
          'price' => price,
          'courses' => courses
        )
      end
    end
  end
end
