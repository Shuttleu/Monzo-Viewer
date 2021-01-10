class AddThresholdoffsetToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :threshold_offset, :integer
  end
end
