class Room < ApplicationRecord
  has_many :users
  validates_uniqueness_of :slug
end
