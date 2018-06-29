class User < ApplicationRecord
  authenticates_with_sorcery!

  has_one :application
  has_many :registrations, inverse_of: :user
  has_many :courses, through: :registrations
  has_many :contracts
  has_many :event_registrations, inverse_of: :user
  has_many :events, through: :event_registrations

  validates :name, presence: true
  validates :email,
              presence: true,
              uniqueness: true,
              email_format: { message: "is not a valid email address" }
  validates :password, length: { minimum: 8 },
              unless: Proc.new { |u| u.password.blank? }
  validates :password, confirmation: true
  validates :password_confirmation, presence: true,
              unless: Proc.new { |u| u.password.blank? }

end
