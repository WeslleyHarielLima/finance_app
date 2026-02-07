Rails.application.routes.draw do
  devise_for :users
  
  unauthenticated do
    root 'pages#home'
  end
  
  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end
  
  get 'dashboard', to: 'dashboard#index'
  resources :financial_entries
  get 'pages/home'
end
