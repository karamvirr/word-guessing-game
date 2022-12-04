Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root "landing_pages#home"
  get "/room/:slug", to: "landing_pages#room", as: "room"
  get "/staging_area/:slug", to: "landing_pages#staging_area", as: "staging_area"
  get "/create_room", to: "landing_pages#create_room", as: "create_room"

  # Redirect all 404's to root path
  get "*path" => redirect("/")

  # Serve websocket cable requests in-process
  mount ActionCable.server => "/cable"
end
