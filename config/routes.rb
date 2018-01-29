Rails.application.routes.draw do

  #get 'exchanges/index'
  get "exchanges", to: 'exchanges#index'

  #get 'traders/edit'

  #get 'traders/index'

  #get 'traders/new'

  #get 'traders/show'

  #get 'trading_pairs/edit'
  #get 'trading_pairs/index'
  #get 'trading_pairs/new'
  #get 'trading_pairs/show'

  get 'accounts/index'
  get 'accounts/inactive'

  root to: 'accounts#index'


  get 'home/index'
  get 'home/index2'
  
  
  resources :trading_pairs do
    get :revenue, on: :member
  end
  
  resources :traders do
    get :order_history, on: :member
  end

  devise_for :users
  
  #add devise_scope :user do get '/users/sign_out' => 'devise/sessions#destroy'
  
  devise_scope :user do
    
    authenticated :user do
      root "accounts#index", as: :authenticated_root
    end
    
    unauthenticated do
      root "devise/sessions#new", as: :unauthenticated_root
    end
    
    get '/users/sign_out' => 'devise/sessions#destroy'
    
  end
  

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
