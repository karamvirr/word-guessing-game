class RoomChannel < ApplicationCable::Channel

  # Called when the consumer has successfully become a subscriber to
  # this channel.
  def subscribed
    stream_from "room_#{params[:slug]}"
    refresh_player_roster
    render_message({
      context: 'message',
      connection_message: true,
      message: "#{current_user.name} has joined the chat."
    })
  end

  # Called once the consumer has cut its cable connection.
  # Any cleanup needed when channel is unsubscribed.
  def unsubscribed
    # I've come to find out that if a user closes a tab, this method won't be
    # executed in its entirety if there are heavy computations, or multiple
    # successive method calls.
    # Therefore, I'm just doing the minimum.
    # The client side message recipients will parse the method, check if the
    # message ends with '... left the chat.' and use that as a signal to remove
    # the user's player card. Doing this offloads computation in this method &
    # ensures it gets to finish before the user's tab closes.

    # if current_user.room.drawer_id == current_user.id
    #   current_user.room.update_columns(
    #     drawer_id: current_user.room.where.not(id: current_user.id).first.id
    #   )
    # end

    render_message({
      context: 'message',
      connection_message: true,
      user_id: current_user.id,
      message: "#{current_user.name} has left the chat."
    })
    # current_user.delete
  end

  # Called when there's incoming data on the websocket for this channel from a
  # consumer.
  #
  # @param :data (Hash) -> payload recieved from consumer.
  def received(data)
    current_user.reload
    current_user.room.reload

    case data['context']
    when 'draw'
      puts("ALLOW DRAW? #1: #{current_user.id != current_user.room.drawer_id}")
      puts("ALLOW DRAW? #2: #{current_user.room.game_started?}")
      return unless current_user.room.can_draw?(current_user.id)
    when 'start'
      current_user.room.start_game(data['word'])
      puts("GAME STARTED: #{current_user.room.game_started?}")
      puts("CURRENT WORD: #{current_user.room.current_word}")
      return
    when 'stop'
      current_user.room.end_game
      current_user.room.set_next_drawer
      received({ context: 'clear' })
      received({ context: 'refresh_timer', seconds: 60 })
      refresh_player_roster
      return
    when 'message'
      if data['is_guess']
        if current_user.room.correct_guess?(data['message'].downcase.strip)
          current_user.set_score(current_user.score + data['point_award'])
          emit({
            context: 'message',
            correct_guess: true,
            message: "#{current_user.name} correctly guessed the word!"
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
  # Triggers all consumers of the current channel to (re)render their player
  # roster.
  def refresh_player_roster
    data = {
      context: 'refresh_player_roster',
      users: [],
      drawer_id: current_user.room.drawer_id
    }
    current_user.room.users.each do |user|
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
