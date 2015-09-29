class User < ActiveRecord::Base
  authenticates_with_sorcery!

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email,
            presence: true,
            uniqueness: true,
            email_format: { message: "is not a valid email address" }
  validates :password, length: { minimum: 8 },
            if: -> { new_record? || changes["password"] }
  validates :password, confirmation: true,
            if: -> { new_record? || changes["password"] }
  validates :password_confirmation, presence: true,
            if: -> { new_record? || changes["password"] }

  def display_name
    "#{first_name} #{last_name}"
  end
end
