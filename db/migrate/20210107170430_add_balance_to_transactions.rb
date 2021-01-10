class AddBalanceToTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :transactions, :balance, :integer
  end
end
