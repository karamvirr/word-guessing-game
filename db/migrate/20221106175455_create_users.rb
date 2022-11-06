class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :slug
      t.integer :score, default: 0
      t.integer :room_id

      t.timestamps
    end
  end
end
