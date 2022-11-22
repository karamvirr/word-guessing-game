class User < ApplicationRecord
  belongs_to :room, optional: false
  validates_uniqueness_of :name
end
