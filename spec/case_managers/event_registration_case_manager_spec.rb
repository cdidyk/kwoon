require 'rails_helper'
require_relative '../../lib/domain/use_cases/event_registration'
require_relative '../../lib/domain/i_payment_gateway'

RSpec.describe EventRegistrationCaseManager, type: :case_manager do
  let(:args) {
    { user_params: { name: "Bob Bobberson", email: "bobb@mailinator.com" },
      course_reg_params: { course_ids: ["1", "7"] },
      payment_token: '123abc',
      event_id: '11' }
  }

  def args_without key
    args.reject {|k,v| k == key }
  end

  describe "#initialize" do
    it "raises an error if user_params is missing" do
      expect {
        EventRegistrationCaseManager.new args.without(:user_params)
      }.to raise_error(ArgumentError, /user_params/)
    end

    it "raises an error if course_reg_params is missing" do
      expect {
        EventRegistrationCaseManager.new args.without(:course_reg_params)
      }.to raise_error(ArgumentError, /course_reg_params/)
    end

    it "raises an error if payment_token is missing" do
      expect {
        EventRegistrationCaseManager.new args.without(:payment_token)
      }.to raise_error(ArgumentError, /payment_token/)
    end

    it "raises an error if event_id is missing" do
      expect {
        EventRegistrationCaseManager.new args.without(:event_id)
      }.to raise_error(ArgumentError, /event_id/)
    end
  end

  describe "#call" do
    let(:cm) { EventRegistrationCaseManager.new args }
    let(:user) { build :user, args[:user_params] }
    let!(:event) {
      create :event, id: args[:event_id], title: 'Chi Kung & Kung Fu Festival'
    }
    let!(:courses) {
      {
        cosmic_expansion:
          create(:event_course,
            id: 1,
            title: 'Cosmic Expansion',
            event: event,
            start_date: event.end_date,
            end_date: event.end_date),
        kung_fu:
          create(:event_course,
            id: 3,
            title: 'Kung Fu course',
            base_price: 120000,
            event: event,
            start_date: event.start_date,
            end_date: event.end_date),
        energy_flow:
          create(:event_course,
            id: 5,
            title: 'Generating Energy Flow',
            event: event,
            start_date: event.start_date,
            end_date: event.start_date),
        ofsz:
          create(:event_course,
            id: 7,
            title: 'One Finger Shooting Zen',
            event: event,
            start_date: 1.day.since(event.start_date),
            end_date: 1.day.since(event.end_date))
      }
    }
    let!(:discounts) {
      {
        ck: event.discounts.create!(
          description: "Both Chi Kung Courses + One Finger Shooting Zen",
          course_list:
            [:cosmic_expansion, :energy_flow, :ofsz]
              .map {|c| courses[c].id }
              .join(','),
          price: 60000),
        all: event.discounts.create!(
          description: "All Courses",
          course_list: courses.values.map(&:id).join(','),
          price: 150000),
        kf_ofsz: event.discounts.create!(
          description: "One Finger Shooting Zen + Crossroads at Four Gates",
          course_list:
            [:kung_fu, :ofsz]
              .map {|c| courses[c].id }
              .join(','),
          price: 120000)
      }
    }

    class TestGateway
      include Domain::IPaymentGateway

      def process_payment args={}
        return {
          succeeded: true,
          data: {
            customer_id: 'abc123',
            charge_id: 'def456',
            messages: {}
          }
        }
      end
    end

    class FailTestGateway
      include Domain::IPaymentGateway

      def process_payment args={}
        return {
          succeeded: false,
          data: {
            customer_id: 'abc123',
            charge_id: nil,
            messages: { payment_token: ["Your card was declined."]}
          }
        }
      end
    end

    let(:payment_gateway) {
      TestGateway.new
    }

    before :each do
      allow(StripeGateway).
        to receive(:new).
             and_return payment_gateway
    end

    it "finds the User by email" do
      expect(User).
        to receive(:where).
             with(email: "bobb@mailinator.com").
             and_return([user])
      cm.call
    end

    it "builds a new User using user_params when the User can't be found" do
      allow(User).
        to receive(:where).
             and_return []
      expect(User).
        to receive(:new).
             with(cm.user_params).
             and_return user
      cm.call
    end

    it "finds the Event and its Courses and Discounts by event_id" do
      expect(Event).
        to receive(:find_with_courses_discounts).
             with(args[:event_id]).
             and_return event
      result = cm.call
    end

    it "calls the EventRegistration Use Case with the registrant, payment_gateway, payment_token, event, and selected_courses" do
      selected_courses = event.courses.find_all do |c|
        args[:course_reg_params][:course_ids].include? c.id.to_s
      end

      uc_result = double(
        "Domain::UseCases::Result",
        'successful?' => true,
        data: {
          dtos: { event_registration: {
                    "registrant" => {},
                    "selected_courses" => [],
                  } },
          customer_id: 'abc123',
          charge_id: 'def456',
          messages: {}
        }
      )

      expect(Domain::UseCases::EventRegistration).
        to receive(:new).
             with(
               event: event.to_dto(include: [:courses, :discounts]),
               payment_gateway: payment_gateway,
               payment_token: args[:payment_token],
               registrant: user.to_dto,
               selected_courses: selected_courses.map(&:to_dto)
             ).
             and_return(
               instance_double(
                 Domain::UseCases::EventRegistration,
                 call: uc_result
               )
             )
      cm.call
    end

    context "when the Use Case succeeds" do
      it "updates and saves the affected models" do
        cm.call
        saved_user =
          User.
            where(email: user.email).
            includes(:event_registrations, :registrations).
            first

        expect(saved_user).not_to be_nil
        expect(saved_user.stripe_id).to eq('abc123')

        event_registrations = saved_user.event_registrations.to_a
        expect(event_registrations.size).to eql(1)
        expect(event_registrations[0].event_id).to eql(event.id)

        course_registrations = saved_user.registrations.find_all do |r|
          [1,7].include? r.course_id
        end

        expect(course_registrations.size).to eql(2)
        expect(course_registrations.map(&:course_id)).to eq([1, 7])
      end

      it "builds a presenter" do
        result = cm.call
        pres = result[:presenter]
        expect(pres.user.attributes).
          to match(hash_including(
                  "admin" => nil,
                  "email" => 'bobb@mailinator.com',
                  "name" => 'Bob Bobberson',
                  "stripe_id" => 'abc123'
                ))
        expect(pres.user.id).to_not be_nil
        expect(pres.event).to eq(event)
        expect(pres.courses).to eq(event.courses)
        expect(pres.event_registration.user).to eql(pres.user)
        expect(pres.event_registration.event).to eql(event)
        expect(pres.event_registration.amount_paid).to eql(60000)
        expect(pres.event_registration.stripe_id).to eql('def456')
        expect(pres.course_reg_ids).to eq(["1", "7"])
        expect(pres.custom_validations).to eq({})
      end

      it "returns a successful result with the presenter" do
        result = cm.call
        expect(result[:succeeded]).to be true
        expect(result[:presenter]).to_not be_nil
      end
    end

    context "when the Use Case fails" do
      let(:payment_gateway) { FailTestGateway.new }

      it "updates but doesn't save the affected models" do
        result = cm.call
        expect(result[:presenter].user.stripe_id).to eql('abc123')
        expect(result[:presenter].user.id).to be_nil
      end

      it "builds a presenter when the failure is due to bad user input" do
        result = cm.call
        expect(result[:presenter]).to_not be_blank
      end

      it "returns a failed result" do
        expect(cm.call[:succeeded]).to be false
      end
    end
  end
end
