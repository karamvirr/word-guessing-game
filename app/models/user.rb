class User < ApplicationRecord
  belongs_to :room, optional: false
  after_destroy :room_clean_up

  def set_as_guessed_correctly
    update!(guessed_correctly: true)
  end

  def set_score(score)
    update!(score: score)
  end

  def clear_score
    set_score(0)
  end

  def in_staging?
    self.name.nil?
  end

private
  # Will the last person leaving the room turn out the lights!
  # This callback ensures that we don't end up with rooms with empty users.
  def room_clean_up
    if self.room.users.count == 0 && self.room.users_in_staging.count == 0
      self.room.destroy
    end
  end
end
