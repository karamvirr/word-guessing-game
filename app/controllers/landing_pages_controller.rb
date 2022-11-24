class LandingPagesController < ApplicationController
  def home
    cookies.delete :user_id # TESTING....
    # User.destroy_all
    # Room.destroy_all
  end

  def create_room
    room = Room.create!
    redirect_to(room_path(slug: room.slug))
  end

  def set_name
    @user = User.find_by(id: params[:id])
    @room = @user.room
    if params[:value].present?
      # TODO: ensure names are unique to room.
      if @user.update(name: params[:value])
        if @room.host.nil? || @room.drawer.nil?
          @room.update!(host: @user, drawer: @user)
        end
        redirect_to("/room/#{@room.slug}")
        return
      end
      flash[:error] = "Name #{params[:value]} already taken."
      redirect_to(set_name_path(@user))
    end
  end

  def room
    @room = Room.find_by(slug: params[:slug])
    if @room.nil?
      flash[:error] = "Room code '#{params[:slug]}' is invalid."
      redirect_to(root_path)
      return
    end
    @user = User.find_by(id: cookies.encrypted[:user_id])
    if @user.nil?
      @user = User.create(room: @room)
      cookies.encrypted[:user_id] = @user.id
      redirect_to(set_name_path(@user))
      # redirect to set_name
      return
    elsif @user.name.nil?
      # redirect to set_name
      redirect_to(set_name_path(@user))
      return
    end
  end
end
