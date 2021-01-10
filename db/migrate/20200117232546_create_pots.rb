class CreatePots < ActiveRecord::Migration[6.0]
  def change
    create_table :pots, id: :string do |t|
      t.string :account_id
      t.string :pot_id
      t.string :name
      t.integer :current

      t.timestamps
    end
  end
end
