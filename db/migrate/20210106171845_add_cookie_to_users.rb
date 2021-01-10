class AddCookieToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :cookie, :string
  end
end
