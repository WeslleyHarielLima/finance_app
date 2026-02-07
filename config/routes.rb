Rails.application.routes.draw do
  devise_for :users
  root 'pages#home'
  
  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end
  
  resources :dashboard, only: [:index]
end
  resources :financial_entries
