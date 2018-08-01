require 'rails_helper'

RSpec.describe EventRegistrationsController, type: :controller do
  describe "POST create" do
    let(:params) {
      { "course_regs" => {"course_ids" => ["1", "7"]},
        "user" => {"name" => "Bob Bobberson", "email" => "bobb@mailinator.com"},
        "stripe_token" => "stripe token",
        "event_id" => "2"
      }
    }

    it "calls the EventRegistrationCaseManager with the passed-in params" do
      cm_args = {
        user_params: params['user'],
        course_reg_params: params['course_regs'],
        payment_token: params['stripe_token'],
        event_id: params['event_id']
      }

      cm = EventRegistrationCaseManager.new cm_args
      allow(cm).to receive(:call).once.and_return({ succeeded: false })
      allow(EventRegistrationCaseManager).
        to receive(:new).
             with(cm_args).
             and_return cm

      expect(cm).to receive(:call).once.and_return({})

      post :create, params: params
    end

    it "displays the confirmation page when successful"
    it "re-displays the new page when unsuccessful due to bad user input"
  end

  describe "POST old_create" do
    let(:params) {
      { "course_regs" => {"course_ids" => ["#{courses[0].id}", "#{courses[1].id}"]},
        "user" => {"name" => "Bob Bobberson", "email" => "bobb@mailinator.com"},
        "stripe_token" => "stripe token",
        "event_id" => "#{event.id}"
      }
    }
    let(:user) {
      build :user, email: 'bobb@mailinator.com', name: 'Bob Bobberson'
    }
    let(:event) {
      create :event
    }
    let(:courses) {
      [
        create(:event_course,
               title: 'Last Chi Kung course',
               event: event,
               start_date: event.end_date,
               end_date: event.end_date),
        create(:event_course,
               title: 'Kung Fu course',
               event: event,
               base_price: 120000,
               start_date: event.start_date,
               end_date: event.end_date),
        create(:event_course,
               title: 'First Chi Kung course',
               event: event,
               start_date: event.start_date,
               end_date: event.start_date)
      ]
    }
    let(:event_reg) {
      double EventRegistration, id: 22, save: true
    }
    let(:result) { double 'Result', 'successful?' => true }
    let(:event_reg_context) {
      double EventRegistrationContext,
             call: result,
             event_registration: event_reg
    }
    let(:mail_double) { double("Mail", deliver_later: nil) }

    before :each do
      allow(Event).
        to receive(:find).
            with("#{event.id}").
            and_return event

      allow(EventRegistration).
        to receive(:new).
            and_return event_reg

      allow(EventRegistrationContext).
        to receive(:new).
            and_return event_reg_context

      allow(EventRegistrationMailer).
        to receive(:confirmation).
            and_return mail_double

      allow(EventRegistrationMailer).
        to receive(:new_registration).
            and_return mail_double

    end

    it "finds the user by email" do
      expect(User).
        to receive(:where).
            with(email: 'bobb@mailinator.com').
            and_return [user]
      expect(User).
        not_to receive(:new)
      post :old_create, params: params
    end

    it "builds a new user if no user is found with the supplied email" do
      allow(User).
        to receive(:where).
            and_return []
      expect(User).
        to receive(:new).
            with('name' => 'Bob Bobberson', 'email' => 'bobb@mailinator.com')
      post :old_create, params: params
    end

    it "finds the event with the supplied id" do
      expect(Event).
        to receive(:find).
            with("#{event.id}").
            and_return event
      post :old_create, params: params
    end

    it "finds all of the event courses ordered by ascending end date" do
      expect(event.courses).
        to receive(:order).
            with("end_date ASC").
            and_return double("AR::Relation", to_a: [courses[1], courses[2], courses[0]])

      post :old_create, params: params
    end

    context "when no courses are selected" do
      let(:no_course_params) {
        params.reject {|k,v| k == 'course_regs' }
      }

      it "displays an error message" do
        post :old_create, params: no_course_params
        expect(flash.now[:alert]).to match(/some problems.*registration/i)
      end

      it "stops and redisplays the registration form so the user can correct errors" do
        expect(EventRegistrationContext).
          not_to receive(:new)

        post :old_create, params: no_course_params

        expect(response).
          to render_template(:new)
      end
    end

    it "builds a new EventRegistrationContext and calls it" do
      expect(EventRegistrationContext).
        to receive(:new).
            and_return event_reg_context

      expect(event_reg_context).
        to receive(:call).
            and_return result

      post :old_create, params: params
    end

    context "when the event registration is successful" do
      it "sends the student a confirmation email" do
        expect(EventRegistrationMailer).
          to receive(:confirmation).
              with(event_reg).
              and_return mail_double

        post :old_create, params: params
      end

      it "sends the sifu a new registration email" do
        expect(EventRegistrationMailer).
          to receive(:new_registration).
              with(event_reg).
              and_return mail_double

        post :old_create, params: params
      end

      it "redirects to a confirmation page" do
        allow(controller).
          to receive(:event_registration_confirmation_path).
              with(event_id: event.id).
              and_return 'event registration confirmation path'

        post :old_create, params: params

        expect(controller)
          .to redirect_to('event registration confirmation path')
      end
    end

    context "when the event registration fails" do
      let(:result) {
        double 'Result', 'successful?' => false, 'message' => 'game over'
      }

      it "renders the new event registration page with a flash message" do
        post :old_create, params: params

        expect(flash.now[:alert]).to eql('game over')
        expect(controller).
          to render_template(:new)
      end
    end
  end
end
