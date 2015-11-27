class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :require_login
  skip_before_filter :require_login, only: :redirect_to_new_application

  def logged_in_home
    users_path
  end

  def redirect_to_new_application
    redirect_to new_application_url
  end
end
