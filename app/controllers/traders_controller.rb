class TradersController < ApplicationController
  
  def edit
    @trader = Trader.where(id:params[:id]).first
    @strategies = Strategy.all
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
  
  def update
    @trader = Trader.where(id:params[:id]).first
    @trader.update(trader_params)
    redirect_to :controller => "trading_pairs", :action => "show", :id => @trader.trading_pair_id
  end
  
  private
  
  def trader_params
    params.require(:trader).permit(:id, :strategy_id, :buy_pct, :sell_pct, :ceiling_pct)
  end
  
  
end
