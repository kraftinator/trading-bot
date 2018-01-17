class ApplicationController < ActionController::Base
  
  protect_from_forgery with: :exception
  #before_action :authenticate_user!
  
  def active_required
    return true if current_user and current_user.active?
    redirect_to accounts_inactive_path
    return false
  end
  
  #def active_required
  #  if current_user and current_user.active?
  #    return true
  #  else
  #    redirect_to accounts_inactive_path
  #    return false
  #  end
  #end
  
end
