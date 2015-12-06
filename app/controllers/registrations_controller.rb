class RegistrationsController < ApplicationController
  skip_before_filter :require_login
  before_filter :validate_token, except: [:confirmation]
  before_filter :set_stripe_key

  def new
    @user = User.find @decoded_token[:user_id]
    @course = Course.find @decoded_token[:course_id]
    @registration = Registration.new course: @course, user: @user
    @payment_options = @course.contract_plans.all.map(&:to_select_option)
    @custom_validations = {}
    @month_options = month_options
    @year_options = year_options
  end

  def create
    @user = User.where(id: @decoded_token[:user_id]).first
    @course = Course.where(id: @decoded_token[:course_id]).first
    @registration = Registration.new course: @course, user: @user
    @payment_options = @course.contract_plans.all.map(&:to_select_option)
    @custom_validations = {}
    @month_options = month_options
    @year_options = year_options

    if @user.blank? or @course.blank? or (params[:registration] and @user.id != params[:registration][:user_id].to_i)
      flash[:alert] = MESSAGES[:bad_token]
      redirect_to info_path
      return
    end

    payment_plan = @course.contract_plans.where(id: params[:payment_plan]).first
    if payment_plan.blank?
      @custom_validations[:payment_plan] = "must be selected"
      flash.now[:alert] = "There are some problems with your registration that prevented its submission. Please review the form below and re-submit when you have fixed the problems."
      render :new
      return
    end

    context = RegistrationContext.new(
      user: @user,
      course: @course,
      registration: @registration,
      payment_plan: payment_plan,
      stripe_token: params[:stripe_token]
    )
    result = context.call
    @registration = context.registration

    if result.successful?
      redirect_to course_registration_confirmation_path(course_id: @course.id)

      RegistrationMailer.
        confirmation(@user, @course).
        deliver_later
    else
      flash.now[:alert] = result.message
      render :new
    end
  end

  def confirmation
    @course = Course.find params[:course_id]
  end


  protected

  MESSAGES = {
    blank_token: "You can't register without a registration token. If you were emailed a registration link, double check that you are using the full link. Otherwise, contact Sifu Chris for a valid registration link.",
    bad_token: "There is a problem with your registration invitation. Contact Sifu Chris for a new one.",
    already_registered: "You have already registered for this course. If you have reached this page in error, contact Sifu Chris Didyk."
  }

  Option = Struct.new(:value, :label)

  def month_options
    [
      Option.new(1, "January"),
      Option.new(2, "February"),
      Option.new(3, "March"),
      Option.new(4, "April"),
      Option.new(5, "May"),
      Option.new(6, "June"),
      Option.new(7, "July"),
      Option.new(8, "August"),
      Option.new(9, "September"),
      Option.new(10, "October"),
      Option.new(11, "November"),
      Option.new(12, "December")
    ]
  end

  def year_options
    current_year = DateTime.now.year
    (current_year..(current_year + 10)).map do |year|
      Option.new year, year
    end
  end

  #TODO figure out if additional logging needs to happen for these 404s
  def validate_token
    if params[:reg_token].blank?
      flash[:alert] = MESSAGES[:blank_token]
      redirect_to info_path
      return
    end

    begin
      @decoded_token = TokenService.decode params[:reg_token]
    rescue JWT::DecodeError
      flash[:alert] = MESSAGES[:bad_token]
      redirect_to info_path
      return
    end

    if @decoded_token[:course_id].blank? or @decoded_token[:user_id].blank?
      flash[:alert] = MESSAGES[:bad_token]
      redirect_to info_path
      return
    end

    if params[:course_id].to_i != @decoded_token[:course_id]
      flash[:alert] = MESSAGES[:bad_token]
      redirect_to info_path
      return
    end

    reg_count =
      Registration.
        where(course_id: @decoded_token[:course_id],
              user_id: @decoded_token[:user_id]).
        count

    if reg_count > 0
      flash[:alert] = MESSAGES[:already_registered]
      redirect_to info_path
      return
    end
  end

  def set_stripe_key
    @stripe_key = ENV['STRIPE_KEY']
  end
end
