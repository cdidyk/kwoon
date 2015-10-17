FactoryGirl.define do
  factory :course do
    title Faker::Company.name
    start_date DateTime.now
    end_date 4.months.from_now
  end
end
