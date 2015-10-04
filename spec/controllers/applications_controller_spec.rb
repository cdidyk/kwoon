RSpec.describe ApplicationsController, type: :controller do
  describe "POST create" do
    let(:params) {
      { application:
          attributes_for(:application).
            merge(user_attributes: attributes_for(:user))
      }
    }
    let(:application) {
      build :application
    }
    let(:mail_double) { double("Mail", deliver_later: nil) }

    before :each do
      allow(StudentApplicationMailer).
        to receive(:confirmation).
            and_return mail_double

      allow(StudentApplicationMailer).
        to receive(:new_application).
            and_return mail_double
    end

    it "saves the application" do
      expect(Application).
        to receive(:create).
            with(params[:application]).
            and_return (application)
      post :create, params
    end

    context "when the application is valid" do
      it "creates an application and its applicant" do
        total_users = User.count
        total_apps = Application.count

        post :create, params

        expect(Application.count).to eq(total_apps + 1)
        expect(User.count).to eq(total_users + 1)

        new_app = Application.last
        app_attrs = params[:application].clone
        user_attrs = app_attrs.delete :user_attributes

        app_attrs.each_pair do |k,v|
          if k == :ten_shaolin_laws
            expect(new_app.ten_shaolin_laws).to be true
          else
            expect(new_app.attributes[k.to_s]).to eq(v)
          end
        end
        user_attrs.each_pair do |k,v|
          expect(new_app.user.attributes[k.to_s]).to eq(v)
        end
      end

      it "sends a confirmation email to the applicant" do
        allow(application).
          to receive(:new_record?).
              and_return false

        allow(Application).
          to receive(:create).
              and_return application

        expect(StudentApplicationMailer).
          to receive(:confirmation).
              with(application.user).
              and_return mail_double

        post :create, params
      end

      it "emails the application to me" do
        allow(application).
          to receive(:new_record?).
              and_return false

        allow(Application).
          to receive(:create).
              and_return application

        expect(StudentApplicationMailer).
          to receive(:new_application).
              with(application).
              and_return mail_double

        post :create, params
      end

      it "displays a thank you screen" do
        app_double =
          double("Application",
                 :new_record? => false,
                 user: object_double(User))

        allow(Application).
          to receive(:create).
              and_return app_double

        post :create, params

        expect(response).
          to redirect_to(application_confirmation_url)
      end
    end

    context "when the application is invalid" do
      before :each do
        params[:application][:health_issues] = ""
      end

      it "displays the form errors" do
        post :create, params
        expect(response).to render_template(:new)
      end

      it "doesn't send any emails" do
        expect(StudentApplicationMailer).
          to_not receive(:confirmation)

        expect(StudentApplicationMailer).
          to_not receive(:new_application)

        post :create, params
      end
    end
  end
end
