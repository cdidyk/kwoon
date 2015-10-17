class Contract < ActiveRecord::Base
  belongs_to :user

  #TODO validations for:
  # - start date before end date
  # - status is in STATUSES
  # - total and balance (and payment_amount, if it has a value) are positive
  validates :balance, presence: true
  validates :end_date, presence: true
  validates :start_date, presence: true
  validates :status, presence: true
  validates :title, presence: true
  validates :total, presence: true
  validates :user, presence: true

  STATUSES = HashWithIndifferentAccess.new(
    future: 'future',
    active: 'active',
    expired: 'expired'
  )

  def paid_off?
    balance == 0
  end

  def make_payment amount
    self.balance = self.balance - amount
  end
end
