class AddCoinamountToTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :transactions, :coin_amount, :integer
  end
end
