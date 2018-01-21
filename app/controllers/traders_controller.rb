class TradersController < ApplicationController
  
  def edit
  end

  def index
    #@traders = current_user.traders.active.to_a.sort_by( &:show_last_fulfilled_order_date ).reverse
    #@traders = current_user.traders.active.order( 'sell_count desc' )
    @traders = current_user.traders.active.to_a.sort_by( &:avg_sells_per_day ).reverse
  end

  def new
  end

  def show
  end
  
  
end
