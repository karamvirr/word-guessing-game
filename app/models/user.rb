class User < ApplicationRecord
  belongs_to :room, optional: false
end
