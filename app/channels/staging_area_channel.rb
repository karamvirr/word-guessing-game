class StagingAreaChannel < ApplicationCable::Channel
  # Called when the consumer has successfully become a subscriber to
  # this channel.
  def subscribed
    stream_from "staging_area_#{params[:slug]}"
    broadcast_room_data
  end

  # Called once the consumer has cut its cable connection.
  # Any cleanup needed when channel is unsubscribed.
  def unsubscribed
  end

  # Broadcasts information for all users currently in the game room
  # to everyone in the staging area (lobby) for that room.
  def broadcast_room_data
    data = {
      slug: room.slug,
      users: []
    }
    room.users.each do |user|
      if (user.name.present? && user != current_user)
        data.dig(:users) << user
      end
    end
    emit(data)
  end

  # @param :name (String) -> name to assign to current user.
  def set_name(data)
    room.drawer_id = current_user.id if room.users.empty?
    room.save!
    current_user.name = data['name']
    current_user.save!
  end

  # Broadcasts the hash provided as a parameter to all subscribers/consumers of
  # the current channel.
  #
  # @param :data (Hash) -> payload to deliever to all subscribers of current
  #                        channel.
  def emit(data)
    ActionCable.server.broadcast("staging_area_#{params[:slug]}", data)
  end

private
  # Returns the current room model.
  def room
    current_user.room
  end
end
