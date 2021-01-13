class RemoveThresholdFromAccounts < ActiveRecord::Migration[6.0]
  def change
    remove_column :accounts, :threshold, :integer
  end
end
