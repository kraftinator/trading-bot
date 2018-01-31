class ExchangesController < ApplicationController
  
  def index
    @exchanges = Exchange.all.to_a
  end
  
end
