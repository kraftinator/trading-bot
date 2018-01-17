class AccountsController < ApplicationController
  
  before_action :authenticate_user!
  before_action :active_required, :except => [:inactive]
  
  def index
  end
  
  def inactive
  end
  
end
