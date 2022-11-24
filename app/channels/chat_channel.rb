# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  # Called when the consumer has successfully
  # become a subscriber to this channel.
  def subscribed
    stream_from "chat_#{params[:slug]}"
  end

  def message(data)
    room = current_user.room
    if room.current_word.present? && current_user.id != room.drawer_id
      if data["message"] == room.current_word
        current_user.score += data["time"]
        current_user.save
        receive({
          context: 'update_score',
          payload: {
            name: current_user.name,
            user_id: current_user.id,
            score: current_user.score
          }
        })
        return
      end
    end
    receive({
      context: 'message',
      payload: data
    })
  end

  # Rebroadcast a message sent by one client to any other connect clients.
  def receive(data)
    ActionCable.server.broadcast("chat_#{params[:slug]}", data)
  end
end
