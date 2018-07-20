require 'date'
require 'ostruct'
require 'active_support'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_time'
require_relative "../../../lib/domain/use_cases/event_registration"
require_relative "../../../lib/domain/entities/registrant"
require_relative "../../../lib/domain/entities/event"
require_relative "../../../lib/domain/entities/course"

RSpec.describe Domain::UseCases::EventRegistration, type: :use_case do
  let(:i_payment_gateway) {
    OpenStruct.new()
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
      use_case = Domain::UseCases::EventRegistration.new args
      expect(use_case.registrant).to eq(registrant)
      expect(use_case.registrant.attributes).to eq(registrant.attributes)
    end

    it "builds an event (with courses and discounts) from the supplied data" do
      event = Domain::Entities::Event.new args[:event]
      use_case = Domain::UseCases::EventRegistration.new args
      expect(use_case.event).to eq(event)
      expect(use_case.event.attributes).to eq(event.attributes)
    end

    it "builds the selected courses from the supplied data" do
      selected_courses = args[:selected_courses].map do |dto|
        Domain::Entities::Course.from_dto dto
      end
      use_case = Domain::UseCases::EventRegistration.new args
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
  end

  describe "#call" do
    let(:use_case) {
      Domain::UseCases::EventRegistration.new args
    }

    it "executes the setup_registration step" do
      expect(use_case).to receive(:setup_registration)
      use_case.call
    end
  end
end
