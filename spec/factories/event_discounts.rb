FactoryBot.define do
  factory :event_discount do
    association :event, strategy: :build
    description 'All Courses'
    course_list '1,2,3'
    price 90000
  end
end
