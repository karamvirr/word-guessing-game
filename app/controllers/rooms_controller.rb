class RoomsController < ApplicationController
  def create
    cookies.delete :user_id
    room = Room.create!
    redirect_to(room_path(slug: room.slug))
  end

  def staging_area
    @room = Room.find_by(slug: params[:slug])
    if @room.nil?
      flash[:error] = "Room code '#{params[:slug]}' is invalid."
      redirect_to(root_path)
      return
    end
    if @user.nil?
      @user = User.create!(room: @room)
      cookies.encrypted[:user_id] = @user.id
    end
  end

  def show
    @room = Room.find_by(slug: params[:slug])
    # Redirect user back to root path if the slug provided does not match to
    # an active room.
    if @room.nil?
      flash[:error] = "Room code '#{params[:slug]}' is invalid."
      redirect_to(root_path)
      return
    end

    @user = User.find_by(id: cookies.encrypted[:user_id])
    # Redirect user to staging area if user information is not set.
    if @user.nil? || @user.name.nil?
      @user = User.create!(room: @room)
      cookies.encrypted[:user_id] = @user.id
      redirect_to(staging_area_path(slug: @room.slug))
      return
    end
  end
end
