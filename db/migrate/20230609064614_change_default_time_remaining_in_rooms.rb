class ChangeDefaultTimeRemainingInRooms < ActiveRecord::Migration[7.0]
  def change
    change_column_default :rooms, :time_remaining, from: 60, to: 90
  end
end
