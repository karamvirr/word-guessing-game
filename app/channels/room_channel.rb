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
      room.drawer_id = next_drawer.id
      room.save!
      received({ context: 'clear' })
      received({ context: 'refresh_timer', seconds: 60 })
      refresh_player_roster
      return
    when 'message'
      if data['is_guess']
        debugger
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

  # Returns the user model record of the next drawer.
  # If room contains no users, nil is returned.
  # If room contains only one user, that user record is returned.
  def next_drawer
    return nil if room.users.empty?
    index = room.users.map(&:id).index(room.drawer_id)
    room.users[(index + 1) % room.users.count]
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




  # Called when the consumer has successfully become
  # a subscriber to this channel.
  # def subscribed
  #   stream_from "room_#{params[:slug]}"

  #   renderPlayerRoster("#{current_user.name} has joined the chat.")
  # end

  # # Called once the consumer has cut its cable connection.
  # def unsubscribed
  #   renderPlayerRoster("#{current_user.name} has left the chat.")
  # end

  # def renderPlayerRoster(message)
  #   current_user.reload
  #   room = current_user.room
  #   data = {
  #     context: 'connection',
  #     payload: {
  #       content: message,
  #       color: "%06x" % (rand * 0xffffff),
  #       host_id: room.host_id,
  #       drawer_id: room.drawer_id,
  #       users: []
  #     }
  #   }
  #   room.users.each do |user|
  #     data.dig(:payload, :users) << user
  #   end

  #   receive(data)
  # end

  # def start(data)
  #   room = current_user.room
  #   if room.update(current_word: data["current_word"], game_started: true)
  #     receive({ context: 'start' })
  #   end
  # end

  # def stop
  #   room = current_user.room

  #   room.current_word = nil
  #   room.game_started = false
  #   room.save!

  #   index = room.drawer_id
  #   index += 1
  #   new_drawer = room.users.find_by(id: index)
  #   if new_drawer.nil?
  #     new_drawer = room.users.first
  #   end
  #   room.drawer_id = new_drawer.id
  #   room.save!

  #   receive({ context: 'stop' })
  #   toggle_display
  #   renderPlayerRoster("Next up is #{new_drawer.name}")
  # end

  # def draw(payload)
  #   room = current_user.room
  #   if room.drawer_id == current_user.id && room.game_started?
  #     receive({
  #       context: 'draw',
  #       payload: payload
  #     })
  #   end
  # end

  # def toggle_display
  #   room = current_user.room
  #   receive({
  #     context: 'toggle_display',
  #     payload: {
  #       host_id: room.host_id,
  #       drawer_id: room.drawer_id
  #     }
  #   })
  # end

  # def timer(data)
  #   receive({
  #     context: 'timer',
  #     payload: data
  #   })
  # end

  # # rebroadcast a message sent by one client to any other connected clients.
  # # data - websocket message is in JSON.
  # def receive(data)
  #   ActionCable.server.broadcast("room_#{params[:slug]}", data)
  # end
end
