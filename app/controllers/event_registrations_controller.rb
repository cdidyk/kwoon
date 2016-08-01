class EventRegistrationsController < ApplicationController
  skip_before_filter :require_login
  before_filter :set_stripe_key

  def new
    @user = User.new
    @event = Event.find params[:event_id]
    @courses = @event.courses.order("end_date ASC").all.to_a
    @event_registration = EventRegistration.new event: @event, user: @user
    @course_regs = CourseRegList.new []
    @month_options = month_options
    @year_options = year_options
  end

  def create

  end

  def confirmation

  end


  protected

  CourseRegList = Struct.new(:course_ids)

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
end