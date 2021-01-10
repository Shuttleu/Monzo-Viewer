class RemoveChangeFromAccounts < ActiveRecord::Migration[6.0]
  def change
    remove_column :accounts, :change, :integer
  end
end
