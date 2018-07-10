FactoryBot.define do
  factory :user do
    name Faker::Name.name
    email
  end
end
