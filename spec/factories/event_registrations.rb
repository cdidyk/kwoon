FactoryGirl.define do
  factory :event_registration do
    association :user, strategy: :build
    association :event, strategy: :build
    amount_paid 60000
    stripe_id 'some stripe id'
  end
end
