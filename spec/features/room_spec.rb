require 'rails_helper'

RSpec.describe("Game Room", type: :feature, js: true) do
  let!(:room) { create :room }

  let!(:user_name_a) { "Jack" }
  let!(:user_name_b) { "Joe" }
  let!(:word_a) { create :word, name: "Apple", difficulty: "Easy"  }
  let!(:word_b) { create :word, name: "Tree", difficulty: "Medium"  }
  let!(:word_c) { create :word, name: "House", difficulty: "Hard"  }

  scenario "user can join a game room" do
    enter_room(user_name_a)

    expect(page).to(have_content("#{user_name_a} (you)"))
    expect(page).to(have_content("#{user_name_a} has joined the chat."))
    expect(room.users.count).to(eq(1))
  end

  scenario "user can leave a game room" do
    enter_room(user_name_a)
    leave_room

    expect(room.users).to(be_empty)
  end

  scenario "multiple users can join a game room" do
    using_session(:user_name_a) do
      enter_room(user_name_a)
    end
    using_session(:user_name_b) do
      enter_room(user_name_b)
    end
    expect(room.users.count).to(eq(2))
  end

  scenario "last player leaving mid-game ends the game" do
    enter_room(user_name_a)

    find("#start-game").click
    choose_word("Easy")

    expect(room.game_started).to(be(true))
    expect(room.current_word.titlecase).to(eq(word_a.name))
    expect(room.drawer_id).to(eq(room.users.first.id))

    leave_room

    room.reload
    expect(room.round).to(eq(1))
    expect(room.game_started).to(be(false))
    expect(room.current_word).to(eq(nil))
    expect(room.time_remaining).to(eq(Room::TIME_LIMIT))
    expect(room.drawer_id).to(eq(nil))
  end

private
  # Chooses a word to draw with the given difficulty.
  # @param :difficulty (String) -> difficulty of word to choose.
  def choose_word(difficulty)
    words = find_all(".c-card")
    case difficulty
    when "Easy" then words[0].click
    when "Medium" then words[1].click
    when "Hard" then words[2].click
    else raise("Invalid argument: #{difficulty}")
    end
    room.reload
    sleep 1
  end

  # Joins a room from a staging area with the given user name.
  # @param :name (String) -> name of user to join room with.
  def enter_room(user_name)
    visit("/rooms/#{room.slug}")
    fill_in("name_input", with: user_name)
    find("form button").click
  end

  def leave_room
    # leaving the room is simulated by visiting the root path and then going back
    # to the staging area for the room, which will ensure the user session has
    # been cleared.
    visit(root_path)
    visit("/staging_areas/#{room.slug}")
  end
end
