require_relative './base'

module Domain
  module Entities
    class Course < Base
      attr_accessor :title, :base_price, :start_date, :end_date

      def attributes
        super.merge(
          'title' => title,
          'base_price' => base_price,
          'start_date' => start_date,
          'end_date' => end_date
        )
      end
    end
  end
end
