class AddGraphToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :show_balance, :boolean
    add_column :accounts, :show_pots, :boolean
    add_column :accounts, :show_combined, :boolean
  end
end
