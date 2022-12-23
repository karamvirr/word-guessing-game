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
end
