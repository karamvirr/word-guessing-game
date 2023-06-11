require 'rails_helper'

RSpec.describe User, type: :model do
  subject { create :user, :in_room }

  it 'has valid factory.' do
    expect(subject).to(be_valid)
  end

  context 'associations' do
    it { is_expected.to(belong_to(:room)) }
  end

  context 'instance methods' do
    describe 'set_as_guessed_correctly' do
      it 'correctly sets attribute value' do
        subject.set_as_guessed_correctly
        expect(subject.guessed_correctly).to(be(true))
      end
    end

    describe 'set_score' do
      it 'correctly sets attribute value' do
        subject.set_score(25)
        expect(subject.score).to(eq(25))
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

    describe 'in_staging?' do
      it 'returns expected value' do
        subject.name = nil
        expect(subject.in_staging?).to(be(true))
        # if user name is set, it means we have made it past the staging area.
        subject.name = 'Some user...'
        expect(subject.in_staging?).to(be(false))
      end
    end
  end

  context 'callbacks' do
    describe 'room_clean_up' do
      context 'destroys room' do
        it 'if no users are left in game room after destroying user' do
          room = subject.room
          expect(room.users.count).to(eq(1))
          expect(room.users_in_staging.count).to(eq(0))
          subject.destroy
          expect(Room.exists?(room.id)).to(be(false))
        end

        it 'if room is empty and only current user is in staging area' do
          subject.name = nil
          subject.save!
          room = subject.room
          expect(room.users.count).to(eq(0))
          expect(room.users_in_staging.count).to(eq(1))
          subject.destroy
          expect(Room.exists?(room.id)).to(be(false))
        end
      end

      context 'does not destroy room' do
        it 'if users are left in game room' do
          room = subject.room
          rand(1..4).times do
            create :user, room: room
          end
          users_in_game_room = room.users.count
          expect(room.users.count).to(eq(users_in_game_room))
          expect(room.users_in_staging.count).to(eq(0))
          subject.destroy
          expect(Room.exists?(room.id)).to(be(true))
        end

        it 'if users are left in staging area' do
          room = subject.room
          users_in_staging = rand(1..4)
          users_in_staging.times do
            create :user, room: room, name: nil
          end
          expect(room.users.count).to(eq(1))
          expect(room.users_in_staging.count).to(eq(users_in_staging))
          subject.destroy
          expect(Room.exists?(room.id)).to(be(true))
        end
      end
    end
  end
end
