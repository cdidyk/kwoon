class Registration < ActiveRecord::Base
  belongs_to :user, inverse_of: :registrations
  belongs_to :course, inverse_of: :registrations

  validates :user, presence: true
  validates :course, presence: true
end
