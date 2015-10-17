RSpec.describe RegistrationsController, type: :controller do
  describe "GET new" do
    let(:course) { double Course, id: 33  }
    let(:user) { double User, id: 14 }
    let(:reg_token) {
      TokenService.
        generate_course_invite_token(
          user: user,
          course: course
        )
    }
    let(:params) {
      { course_id: course.id, reg_token: reg_token }
    }

    before :each do
      allow(Course).
        to receive(:find).
            with(course.id).
            and_return course

      allow(User).
        to receive(:find).
            with(user.id).
            and_return user
    end

    it "requires a course" do
      allow(Course).to receive(:find).and_call_original
      expect {
        get :new, course_id: course.id, reg_token: reg_token
      }.to raise_error(ActiveRecord::RecordNotFound)
    end


    it "requires a course registration token" do
      get :new, course_id: course.id
      expect(response).to have_http_status(302)
      expect(flash[:alert]).to match(/can't register without a registration token/)
    end

    it "returns an error message when the token can't be decoded" do
      get :new, course_id: course.id, reg_token: 'bad token'
      expect(controller).to redirect_to(info_path)
      expect(flash[:alert]).to match(/problem.*invitation/)
    end

    it "returns an error message when the token's course doesn't match the URL" do
      get :new, course_id: '999', reg_token: reg_token
      expect(controller).to redirect_to(info_path)
      expect(flash[:alert]).to match(/problem.*invitation/)
    end

    it "returns an error when the token's user can't be found" do
      allow(User).to receive(:find).and_call_original
      expect {
        get :new, params
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns an error message when the token is expired" do
      expired_token =
        TokenService.
          generate_course_invite_token(
            user: user,
            course: course,
            ttl_in_minutes: 0
          )
      params[:reg_token] = expired_token
      get :new, params
      expect(controller).to redirect_to(info_path)
      expect(flash[:alert]).to match(/problem.*invitation/)
    end

    it "returns an error message when the invitee is already a registered for the course" do
      user = create :user
      course = create :course
      create :registration, user: user, course: course
      reg_token =
        TokenService.generate_course_invite_token user: user, course: course

      get :new, { course_id: course.id, reg_token: reg_token }

      expect(controller).to redirect_to(info_path)
      expect(flash[:alert]).to match(/already registered/i)
    end
  end

  describe "POST create" do
    let(:user) { create :user }
    let(:course_contract_plan) { create :course_contract_plan }
    let(:payment_plan) { course_contract_plan.contract_plan }
    let(:course) { course_contract_plan.course }
    let(:reg_token) {
      TokenService.
        generate_course_invite_token(
          user: user,
          course: course
        )
    }
    let(:params) {
      {
        course_id: course.id,
        reg_token: reg_token,
        registration: {
          user_id: user.id
        },
        payment_plan: payment_plan.id,
        stripe_token: "token"
      }
    }

    let(:mail_double) { double("Mail", deliver_later: nil) }
    let(:reg) { double("Registration") }
    let(:result) { double("RegCtxtResult", 'successful?' => true) }
    let(:context) {
      double "RegistrationContext", call: result, registration: reg
    }

    before :each do
      allow(RegistrationContext).
        to receive(:new).
            and_return context

      allow(RegistrationMailer).
        to receive(:confirmation).
            and_return mail_double
    end

    context "when the registration is successful" do
      #REVIEW should this be moved into RegistrationContext?
      it "sends the student a confirmation email" do
        allow(User).
          to receive(:find).
              with(user.id).
              and_return user

        allow(Course).
          to receive(:find).
              with(course.id).
              and_return course

        expect(RegistrationMailer).
          to receive(:confirmation).
              with(user, course).
              and_return mail_double

        post :create, params
      end

      it "redirects to the registration confirmation page" do
        post :create, params

        expect(response).
          to redirect_to(
               course_registration_confirmation_path(
                 course_id: course.id
               ))
      end
    end

    context "when no payment plan has been selected" do
      it "displays a validation error" do
        post :create, params.merge({payment_plan: ''})

        expect(response).
          to render_template(:new)

        expect(assigns[:custom_validations]).
          to eq(payment_plan: "must be selected")
      end
    end

    context "when the token is for a user (or course) that doesn't exist" do
      let(:reg_token) {
        TokenService.
          generate_course_invite_token(
            user: double("User", id: 0),
            course: course
          )
      }

      it "redirects to an error page asking the user to request a new invite" do
        post :create, params
        expect(response).to redirect_to(info_path)
        expect(flash[:alert]).to match(/problem.*invitation/)
      end
    end

    context "when the token is invalid" do
      let(:reg_token) { "invalid token value" }

      it "displays an error asking the user to request a new invite" do
        post :create, params
        expect(response).to redirect_to(info_path)
        expect(flash[:alert]).to match(/problem.*invitation/)
      end
    end

    context "when the user is already registered for the course" do
      before :each do
        create :registration, user: user, course: course
      end

      it "redirects to the info page with a message that the user is already registered" do
        post :create, params
        expect(response).to redirect_to(info_path)
        expect(flash[:alert]).to match(/already registered/)
      end
    end

    context "when the user (or course) param doesn't match the one in the token" do
      it "displays an error asking the user to request a new invite" do
        other_user = create :user
        post :create, params.merge(registration: {user_id: other_user.id})

        expect(response).to redirect_to(info_path)
        expect(flash[:alert]).to match(/problem.*invitation/)
      end
    end

    context "when the registration is unsuccessful" do
      let(:result) {
        double "RegCtxtResult",
               'successful?' => false,
               'message' => 'the sky is falling!'
      }

      it "displays a relevant error message" do
        post :create, params
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq('the sky is falling!')
      end
    end
  end
end
