class ApplicationsController < ApplicationController
  skip_before_filter :require_login
  before_filter :require_logged_out

  def new
    @application = Application.new
    @application.user = User.new
  end

  def create
    @application = Application.create app_params
    if @application.new_record?
      render action: 'new'
    else
      redirect_to application_confirmation_path

      StudentApplicationMailer.
        confirmation(@application.user).
        deliver_later

      StudentApplicationMailer.
        new_application(@application).
        deliver_later
    end
  end

  def confirmation

  end


  protected

  def require_logged_out
    if logged_in?
      redirect_to logged_in_home
    else
      true
    end
  end

  private

  def app_params
    params.require(:application)
      .permit(
        :phone, :address, :emergency_contact_name, :emergency_contact_phone,
        :wahnam_courses, :martial_arts_experience, :health_issues, :bio,
        :why_shaolin, :ten_shaolin_laws, user_attributes: [:name, :email]
      )
  end
end
