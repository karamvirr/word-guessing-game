class LandingPagesController < ApplicationController
  def home
    cookies.delete :user_id
  end
end
