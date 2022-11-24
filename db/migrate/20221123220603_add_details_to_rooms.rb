class AddDetailsToRooms < ActiveRecord::Migration[7.0]
  def change
    add_column :rooms, :current_word, :string
    add_column :rooms, :game_started, :boolean, default: false
    add_column :rooms, :drawer_id, :integer
    add_column :rooms, :host_id, :integer
  end
end
