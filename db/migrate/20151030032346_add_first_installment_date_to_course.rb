class AddFirstInstallmentDateToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :first_installment_date, :datetime
  end
end
