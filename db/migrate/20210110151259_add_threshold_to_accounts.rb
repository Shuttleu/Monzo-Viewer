class AddThresholdToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :threshold, :integer
  end
end
