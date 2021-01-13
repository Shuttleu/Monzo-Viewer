class CreateConditions < ActiveRecord::Migration[6.0]
  def change
    create_table :conditions, id: :string do |t|
      t.string :account_id
      t.boolean :amount
      t.string :condition

      t.timestamps
    end
  end
end
