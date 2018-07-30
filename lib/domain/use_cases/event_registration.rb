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
        return result unless result.successful?

        process_payment
        finalize_registration
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
        resp = payment_gateway.process_payment(
          amount: registration.total_price,
          customer_rep: registrant,
          payment_token: payment_token,
          description: "Registration for #{event.title}: #{selected_courses.map(&:title).join(', ')}"
        )
        if resp[:succeeded]
          result.pass_step(:process_payment, resp[:data])
        else
          result.fail_step(
            :process_payment, {
              customer_id: resp.dig(:data, :customer_id),
              messages: resp.dig(:data, :messages)
            })
        end

        result
      end


      def finalize_registration
        messages = {}

        registrant.stripe_id = result.data[:customer_id]
        if result.data[:customer_id].nil?
          messages.merge! registrant: ["Unable to link registrant to payment gateway customer. The id returned by the payment gateway was nil."]
        end

        result.pass_step(
          :finalize_registration,
          { messages: messages,
            dtos: { event_registration: registration.to_dto }
          })
        result
      end
    end
  end
end
