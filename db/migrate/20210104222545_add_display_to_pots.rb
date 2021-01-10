class AddDisplayToPots < ActiveRecord::Migration[6.0]
  def change
    add_column :pots, :display, :boolean
  end
end
