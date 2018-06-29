class Application < ApplicationRecord
  belongs_to :user

  accepts_nested_attributes_for :user

  validates :user, presence: true

  # TODO: validate that the interests are all from INTEREST_OPTIONS
  # (inclusion may not work since it expects to compare arrays)'
  validates :interests, presence: { message: "must be chosen" }

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

  INTEREST_OPTIONS = [
    'Shaolin Cosmos Chi Kung',
    'Shaolin Kung Fu'
  ]

  def interests_to_a
    return [] if interests.blank?
    interests.split(',').map {|x| x.downcase.strip }
  end

  def interested_in? interest
    interests_to_a.include? interest.downcase.strip
    # # needed b/c #interested_in? is used to determine whether or not an interest
    # # is selected in the new application form (which can be before the user has
    # # set the interests)
    # return false if self.interests.blank?

    # self.interests.split(',').map { |x|
    #   x.downcase.strip
    # }.include? interest.downcase.strip
  end
end
