require 'rails_helper'

RSpec.describe Room, type: :model do
  subject { create :room }

  it 'has valid factory.' do
    expect(subject).to(be_valid)
  end

  context 'associations' do
    it { is_expected.to(have_many(:users)) }
    it { is_expected.to(have_many(:users_in_staging)) }
  end

  context 'validations' do
    it { is_expected.to(validate_uniqueness_of(:slug)) }
  end

  context 'instance methods' do
    describe 'scoreboard' do
      it 'sorts based on score' do
        scores = [25, 50, 75]
        scores.each do |score|
          create :user, room: subject, score: score
        end
        subject.scoreboard.zip(scores.reverse) do |element, expected_score|
          expect(element.score).to(eq(expected_score))
        end
      end
    end

    describe 'update_hint' do
      it 'correctly updates hint based on guess' do
        word = 'Orange'
        subject.update_hint('current word is nil')
        expect(subject.hint).to(be_nil)
        subject.start_turn(word)
        subject.update_hint('Hmm, orange?')
        expect(subject.hint).to(eq(word.gsub(/[\w]/, '-')))
        # ensuring case-insensitivity
        subject.update_hint(' OrAcL3')
        expect(subject.hint).to(eq('ora---'))
        # if guess contains current word, don't update hint.
        subject.update_hint('ORANGES ')
        expect(subject.hint).to(eq('ora---'))
      end
    end

    describe 'start_game' do
      it 'correctly sets attribute values' do
        create :user, room: subject
        create :user, room: subject, score: 50
        create :user, room: subject, score: 100

        subject.start_game
        subject.users.each do |user|
          expect(user.score).to(eq(0))
        end
        expect(subject.game_started).to(eq(true))
      end
    end

    describe 'end_game' do
      it 'correctly sets attribute values' do
        subject.start_game
        subject.round = 3
        subject.end_game
        expect(subject.round).to(eq(1))
        expect(subject.game_started).to(eq(false))
      end
    end

    describe 'start_turn' do
      it 'correctly sets attribute values' do
        word = 'BICYCLE '
        create :user, room: subject
        # user guessed correctly on a previous turn
        create :user, room: subject, guessed_correctly: true

        subject.start_turn(word)
        subject.users.each do |user|
          expect(user.guessed_correctly).to(be(false))
        end
        expect(subject.current_word).to(eq(word.strip.downcase))
        expect(subject.hint).to(eq(word.strip.gsub(/[\w]/, '-')))
      end
    end

    describe 'end_turn' do
      it 'correctly sets attribute values' do
        user_a = create :user, room: subject
        user_b = create :user, room: subject

        subject.start_turn('dog')
        subject.end_turn
        expect(subject.current_word).to(be_nil)
        expect(subject.hint).to(be_nil)
        expect(subject.time_remaining).to(eq(Room::TIME_LIMIT))
      end
    end

    describe 'everyone_guessed_correctly?' do
      it 'correctly returns value' do
        user = create :user, room: subject
        create :user, name: 'Drawing Player', room: subject
        3.times do
          create :user, guessed_correctly: true, room: subject
        end
        expect(subject.everyone_guessed_correctly?).to(eq(false))
        user.guessed_correctly = true
        user.save!
        subject.reload
        expect(subject.everyone_guessed_correctly?).to(eq(true))
      end
    end

    describe 'can_draw?' do
      it 'correctly returns value' do
        user_a = create :user, room: subject
        user_b = create :user, room: subject
        subject.set_next_drawer
        # no one can draw until turn has started.
        subject.start_game
        [user_a, user_b].each do |user|
          expect(subject.can_draw?(user.id)).to(be(false))
        end
        subject.start_turn('coffee')
        expect(subject.can_draw?(user_a.id)).to(be(true))
        expect(subject.can_draw?(user_b.id)).to(be(false))
      end
    end

    describe 'correct_guess?' do
      it 'correctly returns value' do
        word = 'plane'
        expect(subject.correct_guess?('current word is nil')).to(be(false))
        subject.current_word = word
        expect(subject.correct_guess?('airplane')).to(eq(false))
        expect(subject.correct_guess?(word)).to(eq(true))
      end
    end

    describe 'decrement_time_remaining' do
      it 'correctly sets attribute value' do
        10.times do |count|
          expect(subject.time_remaining).to(eq(Room::TIME_LIMIT - count))
          subject.decrement_time_remaining
        end
      end
    end

    describe 'remove_user' do
      describe 'correctly handles user removal when' do
        it 'given user is nil' do
          expect(subject.remove_user(nil)).to(eq(nil))
        end

        it 'given user is not a user in the room' do
          some_other_room = create :room
          create :user, room: some_other_room

          expect(subject.remove_user(nil)).to(eq(nil))
        end

        it 'given user is a user in the room' do
          user = create :user, room: subject
          count = subject.users.count
          result = subject.remove_user(user)

          expect(result).to(eq(user))
          expect(subject.users.count).to(eq(count - 1))
        end
      end
    end

    describe 'set_next_drawer' do
      describe 'correctly sets attribute value when' do
        it 'there are no users in the room' do
          subject.set_next_drawer
          expect(subject.drawer_id).to(be_nil)
        end

        it 'there is only one user in the room' do
          user_a = create :user, room: subject
          3.times do
            subject.set_next_drawer
            expect(subject.drawer_id).to(eq(user_a.id))
          end
        end

        it 'there are multiple users in the room' do
          user_a = create :user, room: subject
          user_b = create :user, room: subject

          2.times { subject.set_next_drawer }
          expect(subject.drawer_id).to(eq(user_b.id))

          # user joins room
          user_c = create :user, room: subject
          subject.reload
          subject.set_next_drawer
          expect(subject.drawer_id).to(eq(user_c.id))

          # ensure next drawer is first user if current drawer is last user.
          subject.set_next_drawer
          expect(subject.drawer_id).to(eq(user_a.id))
        end
      end
    end
  end
end
