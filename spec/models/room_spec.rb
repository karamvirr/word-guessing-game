require 'rails_helper'

RSpec.describe Room, type: :model do
  subject { create :room }

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
    describe 'start_game' do
      it 'correctly sets attribute values' do
        user_a = create :user, room: subject
        user_b = create :user, room: subject
        subject.start_game('orange')

        expect(subject.current_word).to(eq('orange'))
        expect(subject.game_started?).to(be(true))
      end
    end

    describe 'end_game' do
      it 'correctly sets attribute values' do
        user_a = create :user, room: subject
        user_b = create :user, room: subject

        subject.start_game('orange')
        subject.end_game
        expect(subject.current_word).to(be_nil)
        expect(subject.game_started?).to(be(false))
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

    # describe 'remove_user!' do
    #   describe 'correctly handles user removal when' do
    #     it 'given user is nil' do
    #       expect(subject.remove_user!(nil)).to(eq(nil))
    #     end

    #     it 'given user is not a user in the room' do
    #       some_other_room = create :room
    #       create :user, room: some_other_room

    #       expect(subject.remove_user!(nil)).to(eq(nil))
    #     end

    #     it 'given user is a user in the room' do
    #       user = create :user, room: subject
    #       count = subject.users.count
    #       result = subject.remove_user!(user)

    #       expect(result).to(eq(user))
    #       expect(subject.users.count).to(eq(count - 1))
    #     end
    #   end
    # end
  end
end
