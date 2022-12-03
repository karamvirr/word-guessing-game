require 'rails_helper'

RSpec.describe User, type: :model do
  subject { create :user, room: (create :room) }

  it 'has valid factory.' do
    expect(subject).to(be_valid)
  end

  context 'associations' do
    # TODO
  end

  context 'validations' do
    # TODO
  end

  context 'instance methods' do
    describe 'set_score' do
      it 'correctly sets attribute value' do
        subject.set_score(50)
        expect(subject.score).to(eq(50))
      end
    end
    describe 'clear_score' do
      it 'correctly sets attribute value' do
        subject.set_score(50)
        subject.clear_score
        expect(subject.score).to(eq(0))
      end
    end
  end

  describe 'turn based mechanics' do
    it 'multiple players' do
      room = create :room, drawer_id: subject.id
      subject.room = room
      subject.save
      user_b = create :user, room: room
      expect(subject.room.users.count).to(eq(2))

      # MATCH 1
      word_a = 'orange'
      subject.room.start_game(word_a)
      subject.room.reload
      expect(subject.room.drawer_id).to(eq(subject.id))
      expect(subject.room.game_started?).to(eq(true))
      expect(subject.room.current_word).to(eq(word_a))
      expect(subject.room.can_draw?(subject.id)).to(be(true))
      expect(subject.room.can_draw?(user_b.id)).to(be(false))
      expect(subject.room.correct_guess?(word_a)).to(be(true))
      expect(subject.room.correct_guess?('something else')).to(be(false))
      subject.room.end_game
      subject.room.set_next_drawer
      subject.room.reload

      # MATCH 2
      word_b = 'apple'
      subject.room.start_game(word_b)
      subject.room.reload
      expect(subject.room.drawer_id).to(eq(user_b.id))
      expect(subject.room.game_started?).to(eq(true))
      expect(subject.room.current_word).to(eq(word_b))
      expect(subject.room.can_draw?(subject.id)).to(be(false))
      expect(subject.room.can_draw?(user_b.id)).to(be(true))
      expect(subject.room.correct_guess?(word_b)).to(be(true))
      expect(subject.room.correct_guess?('something else')).to(be(false))
      subject.room.end_game
      subject.room.set_next_drawer
      subject.room.reload

      # MATCH 3
      word_c = 'basketball'
      subject.room.start_game(word_c)
      subject.room.reload
      expect(subject.room.drawer_id).to(eq(subject.id))
      expect(subject.room.game_started?).to(eq(true))
      expect(subject.room.current_word).to(eq(word_c))
      expect(subject.room.can_draw?(subject.id)).to(be(true))
      expect(subject.room.can_draw?(user_b.id)).to(be(false))
      expect(subject.room.correct_guess?(word_c)).to(be(true))
      expect(subject.room.correct_guess?('something else')).to(be(false))
      subject.room.end_game
      subject.room.set_next_drawer
      subject.room.reload

      # MATCH 4
      word_d = 'helmet'
      subject.room.start_game(word_d)
      subject.room.reload
      expect(subject.room.drawer_id).to(eq(user_b.id))
      expect(subject.room.game_started?).to(eq(true))
      expect(subject.room.current_word).to(eq(word_d))
      expect(subject.room.can_draw?(subject.id)).to(be(false))
      expect(subject.room.can_draw?(user_b.id)).to(be(true))
      expect(subject.room.correct_guess?(word_d)).to(be(true))
      expect(subject.room.correct_guess?('something else')).to(be(false))
      subject.room.end_game
      subject.room.set_next_drawer
      subject.room.reload

      # MATCH 5
      word_e = 'skateboard'
      subject.room.start_game(word_e)
      subject.room.reload
      expect(subject.room.drawer_id).to(eq(subject.id))
      expect(subject.room.game_started?).to(eq(true))
      expect(subject.room.current_word).to(eq(word_e))
      expect(subject.room.can_draw?(subject.id)).to(be(true))
      expect(subject.room.can_draw?(user_b.id)).to(be(false))
      expect(subject.room.correct_guess?(word_e)).to(be(true))
      expect(subject.room.correct_guess?('something else')).to(be(false))
      subject.room.end_game
      subject.room.set_next_drawer
      subject.room.reload
    end
  end
end



# # MATCH 1
# word_a = 'orange'
# subject.room.start_game(word_a)
# subject.room.reload
# expect(subject.room.drawer_id).to(eq(subject.id))
# expect(subject.room.game_started?).to(eq(true))
# expect(subject.room.current_word).to(eq(word_a))
# expect(subject.room.can_draw?(subject.id)).to(be(true))
# expect(subject.room.can_draw?(user_b.id)).to(be(false))
# expect(subject.room.correct_guess?(word_a)).to(be(true))
# expect(subject.room.correct_guess?('something else')).to(be(false))
# subject.room.end_game
# subject.room.set_next_drawer
# subject.room.reload

# # MATCH 2
# word_b = 'apple'
# subject.room.start_game(word_b)
# subject.room.reload
# expect(subject.room.drawer_id).to(eq(user_b.id))
# expect(subject.room.game_started?).to(eq(true))
# expect(subject.room.current_word).to(eq(word_b))
# expect(subject.room.can_draw?(subject.id)).to(be(false))
# expect(subject.room.can_draw?(user_b.id)).to(be(true))
# expect(subject.room.correct_guess?(word_b)).to(be(true))
# expect(subject.room.correct_guess?('something else')).to(be(false))
# subject.room.end_game
# subject.room.set_next_drawer
# subject.room.reload

# # MATCH 3
# word_c = 'basketball'
# subject.room.start_game(word_c)
# subject.room.reload
# expect(subject.room.drawer_id).to(eq(subject.id))
# expect(subject.room.game_started?).to(eq(true))
# expect(subject.room.current_word).to(eq(word_c))
# expect(subject.room.can_draw?(subject.id)).to(be(true))
# expect(subject.room.can_draw?(user_b.id)).to(be(false))
# expect(subject.room.correct_guess?(word_c)).to(be(true))
# expect(subject.room.correct_guess?('something else')).to(be(false))
# subject.room.end_game
# subject.room.set_next_drawer
# subject.room.reload

# # MATCH 4
# word_d = 'helmet'
# subject.room.start_game(word_d)
# subject.room.reload
# expect(subject.room.drawer_id).to(eq(user_b.id))
# expect(subject.room.game_started?).to(eq(true))
# expect(subject.room.current_word).to(eq(word_d))
# expect(subject.room.can_draw?(subject.id)).to(be(false))
# expect(subject.room.can_draw?(user_b.id)).to(be(true))
# expect(subject.room.correct_guess?(word_d)).to(be(true))
# expect(subject.room.correct_guess?('something else')).to(be(false))
# subject.room.end_game
# subject.room.set_next_drawer
# subject.room.reload

# # MATCH 5
# word_e = 'skateboard'
# subject.room.start_game(word_e)
# subject.room.reload
# expect(subject.room.drawer_id).to(eq(subject.id))
# expect(subject.room.game_started?).to(eq(true))
# expect(subject.room.current_word).to(eq(word_e))
# expect(subject.room.can_draw?(subject.id)).to(be(true))
# expect(subject.room.can_draw?(user_b.id)).to(be(false))
# expect(subject.room.correct_guess?(word_e)).to(be(true))
# expect(subject.room.correct_guess?('something else')).to(be(false))
# subject.room.end_game
# subject.room.set_next_drawer
# subject.room.reload
