class ChangePaymentAmountDefault < ActiveRecord::Migration
  def up
    change_column_default :contracts, :payment_amount, 0
    change_column_default :contract_plans, :payment_amount, 0
  end

  def down
    change_column_default :contracts, :payment_amount, nil
    change_column_default :contract_plans, :payment_amount, nil
  end
end
