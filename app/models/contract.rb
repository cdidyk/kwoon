class Contract < ApplicationRecord
  include ActionView::Helpers::NumberHelper

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

  STATUSES = ActiveSupport::HashWithIndifferentAccess.new(
    future: 'future',
    active: 'active',
    expired: 'expired'
  )

  #TODO: this default format is the same as in courses, so we should consider
  # extracting it (and possibly a display date range string)
  DEFAULT_DATE_FORMAT = "%b %d, %Y"

  def paid_off?
    balance == 0
  end

  def make_payment amount
    self.balance = self.balance - amount
  end

  def display_currency amount_in_cents
    number_to_currency(amount_in_cents / 100)
  end

  def summary
    "Dates: #{start_date.strftime(DEFAULT_DATE_FORMAT)} - #{end_date.strftime(DEFAULT_DATE_FORMAT)}  Total: #{display_currency(total)}  Balance: #{display_currency(balance)}  Payment Amount: #{display_currency(payment_amount)}"
  end
end
