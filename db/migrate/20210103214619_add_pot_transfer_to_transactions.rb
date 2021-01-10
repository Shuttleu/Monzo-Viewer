class AddPotTransferToTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :transactions, :pot_transfer, :boolean
  end
end
