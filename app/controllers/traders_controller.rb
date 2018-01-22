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
    @trader = Trader.where(id:params[:id]).first
    ## Get USD value
    client = BotTrader.client
    twenty_four_hour = client.twenty_four_hour( symbol: 'ETHUSDT' )
    @eth_price = twenty_four_hour['lastPrice'].to_f
    ## Get summary values
    @total_coin_amount = @total_profit = @total_original_coin_amount = 0
    @total_coin_amount += @trader.coin_amount
    @total_profit += @trader.profit
    @total_original_coin_amount += @trader.original_coin_qty
    
    @orders = LimitOrder.where("trader_id = #{params[:id]} AND filled_at IS NOT NULL").order('created_at DESC')
    
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
