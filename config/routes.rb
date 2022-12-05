Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root "landing_pages#home"

  get "/create_room", to: "rooms#create", as: "create_room"
  get "/staging_areas/:slug", to: "rooms#staging_area", as: "staging_area"
  get "/rooms/:slug", to: "rooms#show", as: "room"

  # Redirect all 404's to root path
  get "*path" => redirect("/")

  # Serve websocket cable requests in-process
  mount ActionCable.server => "/cable"
end
