FactoryGirl.define do
  factory :course do
    title Faker::Company.name
    start_date DateTime.now
    end_date 4.months.from_now

    factory :event_course do
      base_price 30000
      schedule_desc { "#{start_date.strftime(Course::DEFAULT_DATE_FORMAT)} to #{end_date.strftime(Course::DEFAULT_DATE_FORMAT)} from 8am to 11am" }
      association :event, strategy: :build
    end
  end
end
