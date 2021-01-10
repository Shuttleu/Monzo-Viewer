class CreateAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :accounts, id: :string do |t|
      t.string :user_id
      t.string :sort_code
      t.string :acc_number
      t.string :account_id
      t.integer :balance
      t.string :name

      t.timestamps
    end
  end
end
