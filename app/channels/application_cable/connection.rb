module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    def disconnect
      cookies.delete(:user_id)
    end

    private
      def find_verified_user
        return nil if cookies.encrypted[:user_id].nil?

        User.find_by(id: cookies.encrypted[:user_id])
      end
  end
end
