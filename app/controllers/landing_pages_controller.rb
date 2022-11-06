class LandingPagesController < ApplicationController
  def home
  end

  def room
    @room = Room.find_by(slug: params[:slug])
    if @room.nil?
      redirect_to(root_path)
      return
    end
    render(:room)
  end
end
