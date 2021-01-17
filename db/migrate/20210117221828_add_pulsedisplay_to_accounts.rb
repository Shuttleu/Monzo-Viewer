class AddPulsedisplayToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :pulse_display, :integer
  end
end
