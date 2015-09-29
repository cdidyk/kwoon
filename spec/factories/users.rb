FactoryGirl.define do
  factory :user do
    first_name Faker::Hacker.adjective
    last_name Faker::Hacker.noun
    email Faker::Internet.email
  end
end
