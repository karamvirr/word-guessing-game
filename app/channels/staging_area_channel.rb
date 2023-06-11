class StagingAreaChannel < ApplicationCable::Channel
  # Called when the consumer has successfully become a subscriber to
  # this channel.
  def subscribed
    stream_from room_broadcast_identifier
    stream_from user_broadcast_identifier
  end

  # Called once the consumer has cut its cable connection.
  # Any cleanup needed when channel is unsubscribed.
  def unsubscribed
    # TODO
  end

  # NOTE: This method is also called from a user model callback.
  # @param :room (Room)
  def self.get_broadcast_data(room)
    data = {
      slug: room.slug,
      users: []
    }
    room.users.each do |user|
      data.dig(:users) << user
    end
    data
  end

  # @param :name (String) -> name to assign to current user.
  def set_name(data)
    current_user.name = data['name']
    # Once a user's name is set, they move from staging to the game room.
    if current_user.save
      room = current_user.room
      if room.users.count == 1 || room.drawer_id.nil?
        room.drawer_id = current_user.id
        room.save!
      end
      ActionCable.server.broadcast(
        room_broadcast_identifier,
        {
          context: 'refresh_players',
          payload: StagingAreaChannel.get_broadcast_data(room)
        }
      )
      ActionCable.server.broadcast(
        user_broadcast_identifier,
        { context: 'usher_to_game_room', slug: room.slug }
      )
    end
  end

private
  # pub/sub link for room.
  def room_broadcast_identifier(room_slug = params[:slug])
    "staging_area_#{room_slug}"
  end

  # pub/sub link for user.
  def user_broadcast_identifier(room_slug = params[:slug], user_id = current_user.id)
    "staging_area_#{room_slug}_#{user_id}"
  end
end
