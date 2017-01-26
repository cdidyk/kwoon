class ApplicationsController < ApplicationController
  skip_before_filter :require_login
  before_filter :require_logged_out

  def new
    @application = Application.new
    @application.user = User.new
  end

  def create
    prepped_params = app_params
    if !prepped_params[:interests].blank?
      prepped_params[:interests] = prepped_params[:interests].join(',')
    end
    @application = Application.create prepped_params
    if @application.new_record?
      flash.now[:alert] = "There are some problems with your application that prevented its submission. Please review your application below and re-submit when you have fixed the problems."
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
        { interests: [] }, :phone, :address, :emergency_contact_name,
        :emergency_contact_phone, :wahnam_courses, :martial_arts_experience,
        :health_issues, :bio, :why_shaolin, :ten_shaolin_laws,
        user_attributes: [:name, :email]
      )
  end
end
