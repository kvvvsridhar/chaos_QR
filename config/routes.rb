Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'users/scan', to: 'users#scan'
  post 'users/update_from_qr', to: 'users#update_from_qr'

  resources :users, only: [:index]
end
