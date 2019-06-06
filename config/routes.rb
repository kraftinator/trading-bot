Rails.application.routes.draw do
  
  #get 'index_fund_deposits/new'

  #get 'index_fund_coins/edit'

  #get 'index_fund_coins/new'

  #get 'index_funds/edit'
  #get 'index_funds/index'
  #get 'index_funds/new'
  #get 'index_funds/show'
  
  resources :index_fund_deposits
  
  resources :index_fund_coins do
    get 'index_fund_deposits/new'
  end
  
  #resources :index_fund_coins do
  #  get 'index_fund_deposits/new'
  #end
  
  resources :index_funds do
    get :allocations, on: :member
    get :toggle_active, on: :member
    get 'index_fund_coins/new'
  end

  resources :campaigns do
    get :toggle_active, on: :member
    get :revenue, on: :member
    get :price_history, on: :member
    get 'traders/new'
    get 'revenue_report', on: :collection
    #post 'traders/create'
  end
  


  
  resources :traders do
    get :order_history, on: :member
    get :transactions, on: :member
  end

  #resources :campaigns do
  #  get :toggle_active, on: :member
  #  resources :traders do
  #    get :order_history, on: :member
  #    get :transactions, on: :member
  #  end
  #end
  


  resources :exchanges do
    resources :authorizations
  end

  get 'accounts/index'
  get 'accounts/dashboard'
  get 'accounts/dashboard2'
  get 'accounts/inactive'

  #root to: 'accounts#index'
  root to: 'accounts#dashboard'


  get 'home/index'
  get 'home/index2'
  
  
  resources :trading_pairs do
    get :revenue, on: :member
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
