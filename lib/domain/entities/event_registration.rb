require_relative './base'

module Domain
  module Entities
    class EventRegistration < Base
      attr_accessor :event, :registrant, :selected_courses, :amount_paid

      def initialize args={}
        super
      end

      def attributes
        super.merge(
          'event' => event,
          'registrant' => registrant,
          'selected_courses' => selected_courses,
          'amount_paid' => amount_paid
        )
      end

      def to_dto options=nil
        super.tap do |dto|
          dto["event"] =
            dto["event"].to_dto.reject {|k,v| ["courses", "discounts"].include? k }
          dto["registrant"] = dto["registrant"].to_dto
          dto["selected_courses"] = dto["selected_courses"].map(&:to_dto)
        end
      end

      def calculate_price
        price_no_discount = selected_courses.sum(&:base_price)
        applicable_discounts = event.discounts.find_all do |d|
          d.courses.map(&:id).sort == selected_courses.map(&:id).sort
        end

        if applicable_discounts.empty?
          @amount_paid = price_no_discount
        else
          @amount_paid =
            (applicable_discounts.map(&:price) << price_no_discount).min
        end
      end
    end
  end
end
