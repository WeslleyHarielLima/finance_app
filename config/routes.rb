Rails.application.routes.draw do
  devise_for :users
  
  # Rota raiz baseada no login
  unauthenticated do
    root 'pages#home'
  end
  
  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end
  
  # Rotas do app
  get 'dashboard', to: 'dashboard#index'
  resources :financial_entries
  
  # Rota fallback para desenvolvimento
  get 'pages/home'
end
