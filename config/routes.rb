Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root "landing_pages#home"
  get "/room/:slug", to: "landing_pages#room", as: "room"
  get "/set_name/:id", to: "landing_pages#set_name", as: "set_name"
  get "/set_name/:id/:value", to: "landing_pages#set_name"
  get "/create_room", to: "landing_pages#create_room", as: "create_room"

  # Serve websocket cable requests in-process
  mount ActionCable.server => "/cable"
end
