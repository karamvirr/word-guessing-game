class AddGuessedCorrectlyToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :guessed_correctly, :boolean, null: false, default: false
  end
end
