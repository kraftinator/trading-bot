Rails.application.routes.draw do

  get 'accounts/index'
  get 'accounts/inactive'

  root to: 'accounts#index'


  get 'home/index'
  get 'home/index2'
  


  devise_for :users
  
  devise_scope :user do
    authenticated :user do
      root "accounts#index", as: :authenticated_root
    end
    
    unauthenticated do
      root "devise/sessions#new", as: :unauthenticated_root
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
