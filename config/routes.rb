Rails.application.routes.draw do
  # Root route for the home page
  root 'home#index'

  # Custom routes for scanning and updating users via QR
  get 'users/scan'
  post 'users/update_from_qr'
  get 'users/qr_code_generator', to: 'users#qr_code_generator', as: 'qr_code_generator_users'
  post 'users/generate_qr_code', to: 'users#generate_qr_code', as: 'generate_qr_code'

  # Resourceful routes for users (index, new, create, update)
  resources :users, only: [:index, :new, :create, :update]
end
