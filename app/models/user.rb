class User < ApplicationRecord
  belongs_to :room, optional: false
  after_commit :enter_room_broadcast, if: :saved_change_to_name?

  def clear_score
    update!(score: 0)
  end

  def set_as_guessed_correctly
    update!(guessed_correctly: true)
  end

  def set_score(score)
    update!(score: score)
  end

  def in_staging?
    self.name.nil?
  end

private
  # Once a user's name is set, they move from staging to the game room.
  def enter_room_broadcast
    room = Room.find_by(id: self.room_id)
    return if self.name.nil? || room.nil?

    ActionCable.server.broadcast(
      "staging_area_#{room.slug}",
      StagingAreaChannel.get_broadcast_data(room)
    )
  end
end
