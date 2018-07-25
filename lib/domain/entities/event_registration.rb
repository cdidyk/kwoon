require_relative './base'

module Domain
  module Entities
    class EventRegistration < Base
      attr_accessor :event, :registrant, :selected_courses, :total_price

      def initialize args={}
        super
      end

      def attributes
        super.merge(
          'event' => event,
          'registrant' => registrant,
          'selected_courses' => selected_courses,
          'total_price' => total_price
        )
      end

      def calculate_price
        price_no_discount = selected_courses.sum(&:base_price)
        applicable_discounts = event.discounts.find_all do |d|
          d.courses.map(&:id).sort == selected_courses.map(&:id).sort
        end

        if applicable_discounts.empty?
          @total_price = price_no_discount
        else
          @total_price =
            (applicable_discounts.map(&:price) << price_no_discount).min
        end
      end
    end
  end
end
