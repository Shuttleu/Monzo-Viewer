class AddTransactionIdToTransaction < ActiveRecord::Migration[6.0]
  def change
    add_column :transactions, :transaction_id, :string
  end
end
