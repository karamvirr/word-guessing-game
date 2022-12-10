class AddTimeRemainingToRooms < ActiveRecord::Migration[7.0]
  def change
    add_column :rooms, :time_remaining, :integer, null: false, default: 60
  end
end
