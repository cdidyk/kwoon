FactoryBot.define do
  factory :event do
    title "Regional Course with Sifu"
    description Faker::Company.bs
    location "#{Faker::Address.city}, #{Faker::Address.state}"
    start_date DateTime.now
    end_date 3.days.from_now
  end
end
