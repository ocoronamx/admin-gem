Rails.application.routes.draw do

  # root 'home#index'
  # root 'demos#landing'

  root 'demos#landing'
  get 'demos/login'
  get 'demos/dashboard'
  get 'demos/index'
  get 'demos/form'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
