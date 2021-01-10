class AddChangeToAccount < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :change, :integer
  end
end
