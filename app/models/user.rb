class User < ActiveRecord::Base
  authenticates_with_sorcery!

  has_one :application

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
