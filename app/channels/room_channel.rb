class RoomChannel < ApplicationCable::Channel
  # Called when the consumer has successfully become a subscriber to
  # this channel.
  def subscribed
    stream_from "room_#{params[:slug]}"
    refresh_player_roster
    render_message({
      context: 'message', message: "#{current_user.name} has joined the chat."
    })
  end

  # Called once the consumer has cut its cable connection.
  # Any cleanup needed when channel is unsubscribed.
  def unsubscribed
    refresh_player_roster
    render_message({
      context: 'message', message: "#{current_user.name} has left the chat."
    })
  end

  # Called when there's incoming data on the websocket for this channel from a
  # consumer.
  #
  # @param :data (Hash) -> payload recieved from consumer.
  def received(data)
    case data['context']
    when 'draw'
      return if current_user.id != room.drawer_id
      return unless room.game_started?
    when 'start'
      room.current_word = data['current_word']
      room.game_started = true
      room.save!
      return
    when 'stop'
      room.current_word = nil
      room.game_started = false
      room.set_next_drawer
      room.save!
      received({ context: 'clear' })
      received({ context: 'refresh_timer', seconds: 60 })
      refresh_player_roster
      return
    when 'message'
      if data['is_guess']
        if room.current_word == data['message'].downcase.strip
          current_user.score += data['point_award']
          current_user.save!
          emit({
            context: 'message', message: "#{current_user.name} correctly guessed the word!"
          })
          refresh_player_roster
        else
          emit({
            context: 'message', message: "#{current_user.name} guessed incorrectly."
          })
        end
        # Return from either branch because we don't want to emit the contents
        # of the user message to all consumers.
        return
      end
    end

    emit(data)
  end

  # Broadcasts the hash provided as a parameter to all subscribers/consumers of
  # the current channel.
  #
  # @param :data (Hash) -> payload to deliever to all subscribers of current
  #                        channel.
  def emit(data)
    ActionCable.server.broadcast("room_#{params[:slug]}", data)
  end

private
  # Returns the current room model.
  def room
    current_user.room
  end

  # Triggers all consumers of the current channel to (re)render their player
  # roster.
  def refresh_player_roster
    data = {
      context: 'refresh_player_roster',
      users: [],
      drawer_id: room.drawer_id
    }
    room.users.each do |user|
      data.dig(:users) << user
    end
    emit(data)
  end

  # Broadcasts a message to all subscribers/consumers of the current channel.
  # This message will be displayed in the room's chat-box.
  #
  # @param :data (Hash) -> message metadata.
  def render_message(data)
    emit(data)
  end
end
