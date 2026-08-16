Rails.application.routes.draw do
  mount Fosm::Engine => "/fosm"

  root "home#index"

  get  "signup", to: "registrations#new",    as: :new_registration
  post "signup", to: "registrations#create",  as: :registrations

  get "dashboard", to: "dashboard#index", as: :dashboard

  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check
end
