class EventRegistration < ActiveRecord::Base
  belongs_to :user, inverse_of: :event_registrations
  belongs_to :event, inverse_of: :registrations
end