class AddCoinJarToTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :transactions, :coin_jar, :boolean
  end
end
