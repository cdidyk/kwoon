class Application < ActiveRecord::Base
  belongs_to :user

  accepts_nested_attributes_for :user

  validates :user, presence: true
  validates :phone, presence: true
  validates :address, presence: true
  validates :emergency_contact_name, presence: true
  validates :emergency_contact_phone, presence: true
  validates :wahnam_courses, presence: true
  validates :martial_arts_experience, presence: true
  validates :health_issues, presence: true
  validates :bio, presence: true
  validates :why_shaolin, presence: true
  validates :ten_shaolin_laws, acceptance: { accept: true }
end
