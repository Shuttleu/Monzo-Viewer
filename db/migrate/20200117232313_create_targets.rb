class CreateTargets < ActiveRecord::Migration[6.0]
  def change
    create_table :targets, id: :string do |t|
      t.string :pot_id
      t.integer :target
      t.string :for

      t.timestamps
    end
  end
end
