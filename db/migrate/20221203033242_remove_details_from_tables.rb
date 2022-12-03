class RemoveDetailsFromTables < ActiveRecord::Migration[7.0]
  def change
    remove_column :rooms, :host_id, :integer
    add_column :rooms, :round, :integer, default: 0, null: false

    remove_column :users, :slug, :string

    rename_column :words, :slug, :difficulty
  end
end
