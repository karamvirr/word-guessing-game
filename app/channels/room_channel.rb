class RoomChannel < ApplicationCable::Channel
  # Called when the consumer has successfully become
  # a subscriber to this channel.
  def subscribed
    #room = Room.find_by(slug: params[:slug])
    #stream_for room
    stream_from "room_#{params[:slug]}"
    # stream_from "chat:#{room.slug}"
    # receive({
    #   context: "connection",
    #   payload: {
    #     name: current_user.name,
    #     score: current_user.score,
    #     content: "#{current_user.name} has joined the chat."
    #   }
    # })
    renderPlayerRoster("#{current_user.name} has joined the chat.")
  end

  # Called once the consumer has cut its cable connection.
  def unsubscribed
    # receive({
    #   context: "connection",
    #   payload: {
    #     content: "#{current_user.name} has left the chat."
    #   }
    # })
    room = current_user.room
    if current_user.id == room.drawer_id
      # stop
    end
    # renderPlayerRoster("#{current_user.name} has left the chat.")
  end

  def renderPlayerRoster(message)
    current_user.reload
    room = current_user.room
    data = {
      context: 'connection',
      payload: {
        content: message,
        color: "%06x" % (rand * 0xffffff),
        host_id: room.host_id,
        drawer_id: room.drawer_id,
        users: []
      }
    }
    room.users.each do |user|
      data.dig(:payload, :users) << user
    end

    receive(data)
  end

  def start(data)
    room = current_user.room
    if room.update(current_word: data["current_word"], game_started: true)
      receive({ context: 'start' })
    end
  end

  def stop
    room = current_user.room

    room.current_word = nil
    room.game_started = false
    room.save!

    index = room.drawer_id
    index += 1
    new_drawer = room.users.find_by(id: index)
    if new_drawer.nil?
      new_drawer = room.users.first
    end
    room.drawer_id = new_drawer.id
    room.save!

    receive({ context: 'stop' })
    toggle_display
    renderPlayerRoster("Next up is #{new_drawer.name}")
  end

  def draw(payload)
    room = current_user.room
    if room.drawer_id == current_user.id && room.game_started?
      receive({
        context: 'draw',
        payload: payload
      })
    end
  end

  def toggle_display
    room = current_user.room
    receive({
      context: 'toggle_display',
      payload: {
        host_id: room.host_id,
        drawer_id: room.drawer_id
      }
    })
  end

  def timer(data)
    receive({
      context: 'timer',
      payload: data
    })
  end

  # rebroadcast a message sent by one client to any other connected clients.
  # data - websocket message is in JSON.
  def receive(data)
    #room = Room.find_by(slug: params[:slug])
    #ActionCable.server.broadcast(room, data)
    ActionCable.server.broadcast("room_#{params[:slug]}", data)
  end

  ##
  # player joins empty room:
  #   - display all users using @room.users.each { ... }
  #   - display user joined message.
  #   - trigger a player roster for all other connections. (none)
  #
  # player joins non-empty room:
  #   - display all users using @room.users.each { ... }
  #   - display user joined message.
  #   - trigger a player roster for all other connections.
  #
  # player leaves room & room becomes empty:
  #   - delete room.
  #
  # player leaves room & room becomes non-empty:
  #   - display user left meseage.
  #   - trigger a player roster for all other connections.
  ##
end
