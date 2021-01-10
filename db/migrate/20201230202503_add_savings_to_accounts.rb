class AddSavingsToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :savings, :string
  end
end
