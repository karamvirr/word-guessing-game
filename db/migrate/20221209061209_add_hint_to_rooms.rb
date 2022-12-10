class AddHintToRooms < ActiveRecord::Migration[7.0]
  def change
    add_column :rooms, :hint, :string
  end
end
