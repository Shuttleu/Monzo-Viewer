class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users, id: :string do |t|
      t.string :access_token
      t.string :client_id
      t.string :refresh_token
      t.string :client_secret

      t.timestamps
    end
  end
end
