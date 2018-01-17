class HomeController < ApplicationController
  
  
  
  def index
  end
  
  def index2
    @traders = Trader.all
  end
  
end
