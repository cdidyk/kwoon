require 'rails_helper'
require_relative '../../lib/domain/use_cases/event_registration'

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
      cm.call
    end

    it "calls the EventRegistrationUseCase with the registrant, payment_gateway, payment_token, event, and selected_courses" do
      selected_courses = event.courses.find_all do |c|
        args[:course_reg_params][:course_ids].include? c.id
      end

      allow(StripeGateway).
        to receive(:new).
             and_return instance_double(StripeGateway)
      expect(Domain::UseCases::EventRegistration).
        to receive(:new).
             with(
               registrant: user.to_dto,
               payment_gateway: StripeGateway.new,
               payment_token: args[:payment_token],
               event: event.to_dto(include: [:courses, :discounts]),
               selected_courses: selected_courses.map(&:to_dto)
             ).
             and_return(instance_double(Domain::UseCases::EventRegistration, call: {}))
      cm.call
    end
  end
end
