FactoryGirl.define do
  factory :contract do
    title Faker::Company.name
    total 100000
    balance 100000
    payment_amount 25000
    start_date DateTime.parse("July 15, 2015")
    end_date DateTime.parse("November 15, 2015")
    status 'future'
    stripe_id 'fake stripe plan id'
    user
  end
end
