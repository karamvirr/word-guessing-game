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
end
