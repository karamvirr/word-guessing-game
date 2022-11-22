class LandingPagesController < ApplicationController
  def home
  end

  def set_name
    @user = User.find_by(id: params[:id])
    @room = @user.room
    if params[:value].present?
      if @user.update(name: params[:value])
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
    else

  end
    if @user.nil? || @user&.name.nil?
    end
    render(:room)
  end
end
