class HomeController < ApplicationController
  def index
    @traders = Trader.all
  end
end
