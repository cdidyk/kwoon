class EventRegistrationsController < ApplicationController
  skip_before_filter :require_login
  before_filter :set_stripe_key

  def new
    @user = User.new
    @event = Event.find params[:event_id]
    @courses = @event.courses.order("end_date ASC").to_a
    @event_registration = EventRegistration.new event: @event, user: @user
    @course_regs = CourseRegList.new []
    @custom_validations = {}
    @month_options = month_options
    @year_options = year_options
  end

  def create
    @user =
      User.where(email: params[:user][:email]).first ||
      User.new(user_params)
    @event = Event.find params[:event_id]
    @courses = @event.courses.order("end_date ASC").to_a
    @event_registration = EventRegistration.new user: @user, event: @event

    course_ids =
      if params[:course_regs].blank? or params[:course_regs][:course_ids].blank?
        []
      else
        params[:course_regs][:course_ids]
      end
    @course_regs = CourseRegList.new course_ids

    @custom_validations = {}
    @month_options = month_options
    @year_options = year_options

    selected_course_ids =
      @course_regs.course_ids.
        find_all {|id| !id.blank? and @courses.map(&:id).include? id.to_i }.
        map(&:to_i)

    if selected_course_ids.empty?
      @custom_validations[:courses] = "Please choose at least one course"
      flash.now[:alert] = DEFAULT_VALIDATION_FLASH
      render :new
      return
    end

    context = EventRegistrationContext.new(
      user: @user,
      event: @event,
      event_registration: @event_registration,
      courses: @courses,
      selected_course_ids: selected_course_ids,
      stripe_token: params[:stripe_token]
    )
    result = context.call
    @event_registration = context.event_registration

    if result.successful?
      redirect_to event_registration_confirmation_path(event_id: @event.id)

      EventRegistrationMailer
        .confirmation(@event_registration)
        .deliver_later

      EventRegistrationMailer
        .new_registration(@event_registration)
        .deliver_later
    else
      flash.now[:alert] = result.message.blank? ? DEFAULT_VALIDATION_FLASH : result.message
      render :new
    end
  end

  def confirmation
    @event = Event.find params[:event_id]
  end


  protected

  DEFAULT_VALIDATION_FLASH = "There are some problems with your registration that prevented its submission. Please review the form below and re-submit when you have fixed the problems."

  class CourseRegList
    attr_accessor :course_ids

    def initialize course_ids
      @course_ids = course_ids
    end

    def course_selected? id
      @course_ids.map(&:to_i).include? id
    end
  end

  #TODO: DRY up: Option, month_options, year_options, and set_stripe_key are in
  # RegistrationsController, too
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

  #TODO: DRY up -this is in RegistrationsController, too
  def set_stripe_key
    @stripe_key = ENV['STRIPE_KEY']
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :hometown)
  end
end