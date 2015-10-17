FactoryGirl.define do
  factory :contract_plan do
    title Faker::Company.name
    total 100000
    deposit 25000
    payment_amount 25000
    stripe_id 'fake stripe plan id'
  end
end
