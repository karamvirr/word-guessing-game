FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User ##{n}" }
    score { 0 }
  end

  trait :in_room do
    room { create :room }
  end
end
