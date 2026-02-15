Rails.application.routes.draw do
  devise_for :users

  unauthenticated do
    root 'pages#home'
  end

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end

  get 'dashboard', to: 'dashboard#index'

  resources :financial_entries, except: [:show]
  resources :credit_card_charges, except: [:show]
  resources :categories, except: [:show]
  resources :monthly_budgets, except: [:show, :destroy]
  resources :reports, only: [:index]
  resource :profile, only: [:show, :edit, :update]
end
