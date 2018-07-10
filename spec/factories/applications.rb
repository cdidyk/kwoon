FactoryBot.define do
  factory :application do
    user
    interests "Shaolin Kung Fu,Shaolin Cosmos Chi Kung"
    phone Faker::PhoneNumber.phone_number
    address "#{Faker::Address.street_address} #{Faker::Address.city}, #{Faker::Address.state_abbr} #{Faker::Address.zip_code}"
    emergency_contact_name Faker::Name.name
    emergency_contact_phone Faker::PhoneNumber.phone_number
    wahnam_courses "None"
    martial_arts_experience "I took some karate as a kid"
    health_issues "My lower back is stiff and I'm a bit out of shape"
    bio "I like to watch cooking shows and play with my cats"
    why_shaolin "I want to be Gordon Liu"
    ten_shaolin_laws true
  end
end
