Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root "landing_pages#home"
  get "/room", to: "landing_pages#room"
end
