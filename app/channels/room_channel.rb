class RoomChannel < ApplicationCable::Channel
  # Called when the consumer has successfully become a subscriber to
  # this channel.
  def subscribed
    stream_from user_broadcast_identifier
    stream_from room_broadcast_identifier

    refresh_components
    emit({
      context: 'message',
      server_message: true,
      color_hex: generate_random_color,
      message: "#{current_user.name} has joined the chat."
    })
  end

  # Called once the consumer has cut its cable connection.
  # Any cleanup needed when channel is unsubscribed.
  def unsubscribed
    emit({
      context: 'message',
      server_message: true,
      color_hex: generate_random_color,
      user_id: current_user.id,
      message: "#{current_user.name} has left the chat."
    })
    if current_user.id == current_user.room.drawer_id
      if current_user.room.game_started?
        emit({ context: 'end_turn' })
      else
        current_user.room.set_next_drawer
        refresh_components
      end
    end
    current_user.destroy!
  end

  # Called when there's incoming data on the websocket for this channel from a
  # consumer.
  #
  # @param :data (Hash) -> payload recieved from consumer.
  def received(data)
    emit(data)
  end

  # Broadcasts the hash provided as a parameter to all subscribers/consumers of
  # the current channel.
  #
  # @param :data (Hash) -> payload to deliever to all subscribers of current
  #                        channel.
  def emit(data)
    data = data.symbolize_keys
    current_user.reload
    current_user.room.reload

    case data[:context]
    when 'draw'
      return unless current_user.room.can_draw?(current_user.id)
    when 'start_game'
      current_user.room.start_game
      refresh_components
      emit({ context: 'hide_overlay'})
      emit({ context: 'select_word' })
      return
    when 'end_game'
      current_user.room.end_game
      refresh_components
      emit({ context: 'scoreboard', users: current_user.room.scoreboard })
      return
    when 'start_turn'
      current_user.room.start_turn(data[:word])
      emit({ context: 'clear_canvas' })
      refresh_components
      emit({
        context: 'message',
        server_message: true,
        message: "#{current_user.name} has selected a word!"
      })
      emit({
        context: 'set_header',
        hint: current_user.room.hint,
        word: current_user.room.current_word,
        drawer_id: current_user.room.drawer_id
      })
      ActionCable.server.broadcast(
        user_broadcast_identifier(current_user.room.drawer_id),
        { context: 'start_timer' }
      )
      return
    when 'end_turn'
      emit({
        context: 'set_header',
        hint: current_user.room.current_word,
        word: current_user.room.current_word,
        drawer_id: current_user.room.drawer_id
      })
      current_user.room.end_turn
      ActionCable.server.broadcast(
        user_broadcast_identifier(current_user.room.drawer_id),
        { context: 'stop_timer' }
      )
      emit({
        context: 'refresh_time_remaining_header',
        seconds: current_user.room.time_remaining
      })
      current_user.room.set_next_drawer
      refresh_components
      if (current_user.room.round > 3)
        emit({ context: 'end_game' })
      else
        emit({ context: 'select_word' })
      end
      return
    when 'decrement_time_remaining'
      current_user.room.decrement_time_remaining
      emit({
        context: 'refresh_time_remaining_header',
        seconds: current_user.room.time_remaining
      })
      if current_user.room.time_remaining == 0
        emit({
          context: 'message',
          server_message: true,
          message: "Time's up! The word was #{current_user.room.current_word}."
        })
        emit({ context: 'end_turn' })
      end
      return
    when 'times_up'
      emit({
        context: 'message',
        server_message: true,
        message: "Time's up! The word was #{current_user.room.current_word}."
      })
      emit({ context: 'end_turn' })
      return
    when 'select_word'
      emit({
        context: 'message',
        server_message: true,
        message: "#{current_user.name} is selecting a word."
      })
      ActionCable.server.broadcast(
        user_broadcast_identifier(current_user.room.drawer_id),
        { context: 'word_options', words: Word.random_option_set }
      )
      return
    when 'message'
      if current_user.id != current_user.room.drawer_id &&
        !current_user.guessed_correctly? &&
        current_user.room.current_word.present?
        # the received message is a guess.
        guess = data[:message].strip.downcase

        if current_user.room.current_word == guess
          current_user.set_score(current_user.score + current_user.room.time_remaining)
          current_user.set_as_guessed_correctly
          emit({
            context: 'message',
            server_message: true,
            color_hex: correct_guess_color,
            message: "#{current_user.name} correctly guessed the word!"
          })
          refresh_components

          if current_user.room.everyone_guessed_correctly?
            emit({ context: 'end_turn' })
          end
          return
        else
          current_user.room.update_hint(guess)
          emit({
            context: 'set_header',
            hint: current_user.room.hint,
            word: current_user.room.current_word,
            drawer_id: current_user.room.drawer_id
          })
        end
      end
    end

    ActionCable.server.broadcast(room_broadcast_identifier, data)
  end

private
  # pub/sub link for room.
  def room_broadcast_identifier
    "room_#{params[:slug]}"
  end

  # pub/sub link for user.
  def user_broadcast_identifier(user_id = current_user.id)
    "room_#{params[:slug]}_#{user_id}"
  end

  # Generates and returns a random hexadecimal color as a string.
  def generate_random_color
    "#" + SecureRandom.hex(3)
  end

  # Returns the correct guess hexadecimal color as a string.
  def correct_guess_color
    "#1EC71E"
  end

  # Triggers all consumers of the current channel to (re)render several
  # components such as the player roster, drawing-palette/start-game button
  # visibility, etc.
  def refresh_components
    current_user.room.reload
    data = {
      context: 'refresh_components',
      users: [],
      drawer_id: current_user.room.drawer_id,
      game_started: current_user.room.game_started?,
      round: current_user.room.round
    }
    current_user.room.users.each do |user|
      data.dig(:users) << user
    end
    emit(data)
  end
end
