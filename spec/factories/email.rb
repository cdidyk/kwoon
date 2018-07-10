FactoryBot.define do
  sequence :email do |n|
    "#{n}#{Faker::Internet.email}"
  end
end
