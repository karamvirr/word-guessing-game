class StagingAreaChannel < ApplicationCable::Channel
  # Called when the consumer has successfully become a subscriber to
  # this channel.
  def subscribed
    stream_from "staging_area_#{params[:slug]}"
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
    current_user.save!
    room = current_user.room
    room.drawer_id = current_user.id if room.users.empty? || room.drawer_id.nil?
    room.save!
  end
end
