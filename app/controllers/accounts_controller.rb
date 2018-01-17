class AccountsController < ApplicationController
  
  before_action :authenticate_user!
  before_action :active_required, :except => [:inactive]
  
  def index
    @traders = current_user.traders.all
  end
  
  def inactive
  end
  
end
