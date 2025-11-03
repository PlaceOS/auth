Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  scope :auth do
    use_doorkeeper
    use_doorkeeper_openid_connect

    get "/login", to: "auth/sessions#new" # for defining continue
    get "/logout", to: "auth/sessions#destroy" # deletes the session
    get "/:provider/callback", to: "auth/sessions#create" # omniauth route
    post "/:provider/callback", to: "auth/sessions#create" # omniauth route
    get "/:provider/callback/:strategy", to: "auth/sessions#create" # omniauth route
    post "/:provider/callback/:strategy", to: "auth/sessions#create" # omniauth route

    post "/signin", to: "auth/sessions#signin" # local account login
    post "/signup", to: "auth/signups#create" # manual account creation

    get "/failure", to: "auth/signups#show" # Auth failure message

    get "/authority", to: "auth/authorities#current"
  end

  get "/.well-known/openid-configuration(.:format)", to: "doorkeeper/openid_connect/discovery#provider"
  get "/.well-known/oauth-authorization-server(.:format)", to: "doorkeeper/openid_connect/discovery#provider"
  get "/.well-known/webfinger(.:format)", to: "doorkeeper/openid_connect/discovery#webfinger"
end
