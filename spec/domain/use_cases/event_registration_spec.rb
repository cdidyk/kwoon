require 'date'
require 'ostruct'
require 'active_support'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_time'
require_relative "../../../lib/domain/use_cases/event_registration"
require_relative "../../../lib/domain/entities/registrant"
require_relative "../../../lib/domain/entities/event"
require_relative "../../../lib/domain/entities/course"
require_relative "../../../lib/domain/entities/event_registration"
require_relative "../../../lib/domain/i_payment_gateway"

RSpec.describe Domain::UseCases::EventRegistration, type: :use_case do
  class TestGateway
    include Domain::IPaymentGateway

    # expected args: registration, payment_token, and maybe description? (for metadata)
    def process_payment args={}
      return { succeeded: true, data: { customer_id: 'abc123' } }
    end
  end

  let(:i_payment_gateway) {
    TestGateway.new
  }
  let(:event_start) {
    DateTime.now
  }
  let(:event_end) {
    3.days.from_now
  }
  let(:course_dtos) {
    {
      cosmic_expansion: {
        "id" => 14,
        "title" => "Cosmic Expansion",
        "event_id" => 73,
        "start_date" => event_end,
        "end_date" => event_end,
        "base_price" => 30000
      },
      kung_fu: {
        "id" => 15,
        "title" => "Kung Fu course",
        "base_price" => 120000,
        "event_id" => 73,
        "start_date" => event_start,
        "end_date" => event_end
      },
      energy_flow: {
        "id" => 16,
        "title" => "Generating Energy Flow",
        "base_price" => 30000,
        "event_id" => 73,
        "start_date" => event_start,
        "end_date" => event_start
      },
      ofsz: {
        "id" => 17,
        "title" => "One Finger Shooting Zen",
        "base_price" => 30000,
        "event_id" => 73,
        "start_date" => 1.day.since(event_start),
        "end_date" => 1.day.since(event_start)
      }
    }
  }
  let(:args) {
    {
      registrant: {
        "id" => 12,
        "email" => "bobb@mailinator.com",
        "name" => "Bob Bobberson",
        "admin" => false,
        "stripe_id" => nil },
      payment_gateway: i_payment_gateway,
      payment_token: "stripe token",
      event: {
        "id" => 73,
        "title" => "Chi Kung & Kung Fu Festival",
        "description" => nil,
        "start_date" => event_start,
        "end_date" => event_end,
        "courses" => course_dtos.values,
        "discounts" => [
          {
            "id" => 7,
            "event_id" => 73,
            "description" => "All Chi Kung Courses",
            "course_list" => "14,16",
            "price" => 50000
          }, {
            "id" => 8,
            "event_id" => 73,
            "description" => "All Courses",
            "course_list" => "14,15,16,17",
            "price" => 150000
          }]
      },
      selected_courses: [course_dtos[:cosmic_expansion], course_dtos[:energy_flow]]
    }
  }
  let(:use_case) {
    Domain::UseCases::EventRegistration.new args
  }

  describe "#initialize" do
    it "initializes the UseCaseResult with the right steps" do
      use_case = Domain::UseCases::EventRegistration.new args
      expect(use_case.result.class).to eq(Domain::UseCases::Result)
      expect(use_case.result.steps).
        to eq([
          :setup_registration,
          :process_payment,
          :finalize_registration
        ])
    end

    it "builds a registrant from the supplied data" do
      registrant = Domain::Entities::Registrant.new args[:registrant]
      expect(use_case.registrant).to eq(registrant)
      expect(use_case.registrant.attributes).to eq(registrant.attributes)
    end

    it "builds an event (with courses and discounts) from the supplied data" do
      event = Domain::Entities::Event.new args[:event]
      expect(use_case.event).to eq(event)
      expect(use_case.event.attributes).to eq(event.attributes)
    end

    it "builds the selected courses from the supplied data" do
      selected_courses = args[:selected_courses].map do |dto|
        Domain::Entities::Course.from_dto dto
      end
      expect(use_case.selected_courses).to eq(selected_courses)
      expect(use_case.selected_courses.map(&:attributes)).to eq(selected_courses.map(&:attributes))
    end

    it "raises an error if the registrant can't be built" do
      expect {
        Domain::UseCases::EventRegistration.new args.merge(registrant: nil)
      }.to raise_error(ArgumentError, /Registrant/)
    end

    it "raises an error if the event can't be built" do
      expect {
        Domain::UseCases::EventRegistration.new args.merge(event: nil)
      }.to raise_error(ArgumentError, /Event/)
    end

    it "raises an error if the selected courses aren't an array" do
      expect {
        Domain::UseCases::EventRegistration.new args.merge(selected_courses: nil)
      }.to raise_error(ArgumentError, /selected_courses/)
    end

    it "raises an error if the selected courses can't be built" do
      expect {
        Domain::UseCases::EventRegistration.new args.merge(selected_courses: [nil])
      }.to raise_error(ArgumentError, /Course/)
    end

    it "raises an error if the Payment Gateway doesn't implement the IPaymentGateway interface" do
      expect {
        Domain::UseCases::EventRegistration.new(
          args.merge(payment_gateway: OpenStruct.new)
        )
      }.to raise_error(ArgumentError, /IPaymentGateway/)
    end
  end

  describe "#call" do
    skip "executes the setup_registration step" do
      pending "not so useful. Revisit what #call specs should be after implementing the functions it calls."
      # expect(use_case).to receive(:setup_registration)
      # use_case.call
    end
  end

  describe "#setup_registration" do
    it "builds an Event Registration" do
      use_case.setup_registration
      expect(use_case.registration.class).to eq(Domain::Entities::EventRegistration)
      expect(use_case.registration.registrant).to eql(use_case.registrant)
      expect(use_case.registration.event).to eql(use_case.event)
      expect(use_case.registration.selected_courses).to eql(use_case.selected_courses)
    end

    it "fails if there are no selected courses" do
      use_case = Domain::UseCases::EventRegistration.new(
        args.merge(selected_courses: [])
      )
      result = use_case.setup_registration
      expect(result.last_completed).to eq(:setup_registration)
      expect(result.failed).to eq([:setup_registration])
      expect(result.data[:messages]).
        to eq(selected_courses: ["Please select at least one course"])
    end

    it "fails if there are duplicate selected courses" do
      use_case = Domain::UseCases::EventRegistration.new(
        args.merge(
          selected_courses: [
            course_dtos[:cosmic_expansion],
            course_dtos[:energy_flow],
            course_dtos[:cosmic_expansion]])
      )
      result = use_case.setup_registration
      expect(result.last_completed).to eq(:setup_registration)
      expect(result.failed).to eq([:setup_registration])
      expect(result.data[:messages]).
        to eq(selected_courses: ["There was a problem with the courses you selected. Please try again."])
    end

    it "fails if any of the selected courses are not part of the event" do
      imposter_course_dto = {
        "id" => 25,
        "title" => "Sinew Metamorphosis",
        "event_id" => 73,
        "start_date" => event_end,
        "end_date" => event_end,
        "base_price" => 30000
      }
      use_case = Domain::UseCases::EventRegistration.new(
        args.merge(
          selected_courses: [
            course_dtos[:cosmic_expansion],
            imposter_course_dto])
      )
      result = use_case.setup_registration
      expect(result.last_completed).to eq(:setup_registration)
      expect(result.failed).to eq([:setup_registration])
      expect(result.data[:messages]).
        to eq(selected_courses: ["There was a problem with the courses you selected. Please try again."])
    end

    it "fails if the payment token is missing" do
      use_case =
        Domain::UseCases::EventRegistration.new args.merge(payment_token: nil)
      result = use_case.setup_registration
      expect(result.last_completed).to eq(:setup_registration)
      expect(result.failed).to eq([:setup_registration])
      expect(result.data[:messages]).
        to eq(payment_token: ["Please provide payment info"])
    end

    it "calculates the total price, including discounts" do
      use_case.setup_registration
      expect(use_case.registration.total_price).to eql(50000)
    end

    it "calculates the total price even when there are no discounts" do
      use_case = Domain::UseCases::EventRegistration.new(
        args.merge event: args[:event].merge(discounts: [])
      )
      use_case.setup_registration
      expect(use_case.registration.total_price).to eql(60000)
    end

    # REVIEW: is there a better test description?
    it "succeeds if it the event registration is set up successfully" do
      use_case.setup_registration
      expect(use_case.result.last_completed).to eq(:setup_registration)
      expect(use_case.result.passed).to eq([:setup_registration])
      expect(use_case.result.failed).to eq([])
    end
  end

  describe "#process_payment" do
    it "fails when the payment can't be processed" do
      class FailTestGateway
        def process_payment args={}
          return {
            succeeded: false,
            data: { customer_id: 'abc123', messages: ["The card number is invalid"] }
          }
        end
      end

      i_payment_gateway = FailTestGateway.new
      use_case = Domain::UseCases::EventRegistration.new(
        args.merge payment_gateway: i_payment_gateway
      )
      result = use_case.process_payment
      expect(result.last_completed).to eq(:process_payment)
      expect(result.failed).to eq([:process_payment])
      expect(result.data[:messages]).
        to eq(["The card number is invalid"])
    end

    it "succeeds when the payment can be processed" do
      result = use_case.process_payment
      expect(result.last_completed).to eq(:process_payment)
      expect(result.passed).to eq([:process_payment])
      expect(result.data[:messages]).
        to be_blank
    end
  end
end
