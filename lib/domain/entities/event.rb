require_relative './base'
require_relative './course'
require_relative './discount'

module Domain
  module Entities
    class Event < Base
      attr_accessor :title, :start_date, :end_date, :courses, :discounts

      def initialize args={}
        super
        @courses = courses.map {|dto| Course.from_dto dto }
        @discounts = discounts.map do |dto|
          Discount.from_dto(dto).tap do |d|
            d.courses = courses.find_all do |c|
              dto['course_list'].
                split(',').
                map(&:to_i).
                include? c.id
            end
          end
        end
      end

      def attributes
        super.merge(
          'title' => title,
          'start_date' => start_date,
          'end_date' => end_date,
          'courses' => courses,
          'discounts' => discounts
        )
      end
    end
  end
end
