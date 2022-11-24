FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User ##{n}" }
    score { 0 }
  end
end
