require_relative './result'
require_relative '../entities/registrant'
require_relative '../entities/event'
require_relative '../entities/course'
require_relative '../entities/event_registration'
require_relative '../interface_enforcer'

module Domain
  module UseCases
    class EventRegistration
      include ::Domain

      attr_reader :result, :registrant, :event, :selected_courses,
                  :registration, :payment_gateway, :payment_token

      def initialize args={}
        @result = Result.new(
          steps: [
            :setup_registration,
            :process_payment,
            :finalize_registration
          ])
        @registrant = Entities::Registrant.from_dto args[:registrant]
        @event = Entities::Event.from_dto args[:event]

        if !args[:selected_courses].respond_to? :map
          raise ArgumentError, "selected_courses must be an array of Course dtos"
        end

        @selected_courses = args[:selected_courses].map do |dto|
          Entities::Course.from_dto dto
        end

        if !InterfaceEnforcer.audit args[:payment_gateway], IPaymentGateway
          raise ArgumentError, "payment_gateway must fully implement the IPaymentGateway interface"
        end

        @payment_gateway = args[:payment_gateway]
        @payment_token = args[:payment_token]
      end

      def call
        setup_registration
      end

      def setup_registration
        duplicate_selected_courses =
          selected_courses.map(&:id).uniq.length != selected_courses.length

        selected_not_in_event =
          selected_courses.any? {|c| !event.courses.include? c }

        valid = true

        if selected_courses.empty?
          result.fail_step(
            :setup_registration,
            messages: { selected_courses: ["Please select at least one course"] }
          )
          valid = false
        elsif duplicate_selected_courses || selected_not_in_event
          result.fail_step(
            :setup_registration,
            messages: { selected_courses: ["There was a problem with the courses you selected. Please try again."]}
          )
          valid = false
        end

        if payment_token.nil?
          result.fail_step(
            :setup_registration,
            messages: { payment_token: ["Please provide payment info"]}
          )
          valid = false
        end

        return result unless valid

        @registration = Entities::EventRegistration.new(
          registrant: registrant,
          event: event,
          selected_courses: selected_courses
        )

        @registration.calculate_price
        result.pass_step(:setup_registration)
        result
      end

      def process_payment

      end

      def finalize_registration

      end
    end
  end
end


# class EventRegistrationUseCase
#   attr_reader :event, :payment_gateway, :payment_token,
#               :registrant, :registration, :result

#   def initialize args={}
#     @result = UseCaseResult.new(
#       steps: [
#         :setup_registration
#         :process_payment,
#         :finalize_registration
#       ]
#     )
#     @event = Entities::Event.from_dto args[:event]
#     @payment_gateway = args[:payment_gateway]
#     @payment_token = args[:payment_token]
#     @registrant = Entities::Registrant.from_dto args[:registrant]
#     @selected_courses =
#       args[:selected_courses].map {|c| Entities::Course.from_dto c }
#     @registration = Entities::EventRegistration.new(
#       event: @event,
#       registrant: @registrant,
#       selected_courses: @selected_courses
#     )
#   end

#   def call
#     setup_registration
#     process_payment
#     finalize_registration
#     result
#   end

#   def setup_registration
#     # check pre-conditions, like all initialized data is valid and
#     # set result object accordingly
#     InterfaceCop.verify payment_gateway, IPaymentGateway
#     #event has courses

#     registration.calculate_price # sets its total_price attr
#     @result.pass(:setup_registration)
#   end

#   def process_payment
#     resp = payment_gateway.process_payment user, payment_token, total_price
#     if resp.successful?
#       @result.pass(:process_payment) do |r|

#       end
#     else
#       @result.fail(:process_payment) do |r|
#         r.messages[:process_payment] = ['Failed to process payment']
#       end
#     end
#   end

#   def finalize_registration
#   end
# end
