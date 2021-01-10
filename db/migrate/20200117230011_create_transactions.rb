class CreateTransactions < ActiveRecord::Migration[6.0]
  def change
    create_table :transactions, id: :string do |t|
      t.string :account_id
      t.date :day
      t.string :payee
      t.integer :amount

      t.timestamps
    end
  end
end
