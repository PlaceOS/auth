# encoding: UTF-8

Rails.application.routes.draw do
  resources :test

  scope :auth do
      use_doorkeeper

      get  '/login', to: 'auth/sessions#new'       # for defining continue
      get  '/logout', to: 'auth/sessions#destroy'  # deletes the session
      get  '/:provider/callback', to: 'auth/sessions#create' # omniauth route
      post '/:provider/callback', to: 'auth/sessions#create' # omniauth route

      post '/signin', to: 'auth/sessions#signin'   # local account login
      post '/signup', to: 'auth/signups#create'    # manual account creation

      get  '/failure', to: 'auth/signups#show'     # Auth failure message

      get  '/authority', to: 'auth/authorities#current'
  end

  scope '/api/files/v1/' do
    resources :uploads, only: [:index, :create, :new, :update]
  end
end
