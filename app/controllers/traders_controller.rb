require './lib/bot_trader.rb'

class TradersController < ApplicationController
  
  before_action :set_trader, only: [:show, :edit, :update, :order_history]
  
  def edit
    @strategies = Strategy.all.order( 'name' )
  end

  def index
    @traders = current_user.traders.active.to_a.sort_by( &:avg_sells_per_day ).reverse
  end

  def new
  end

  def show

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
    @trader.update(trader_params)
    redirect_to trading_pair_path( @trader.trading_pair )
  end
  
  def order_history
    @orders = @trader.limit_orders.order( 'created_at desc' )
  end
  
  private
  
  def trader_params
    params.require(:trader).permit(:id, :strategy_id, :buy_pct, :sell_pct, :ceiling_pct, :sell_count_trigger)
  end
  
  def set_trader
    @trader = Trader.find( params[:id] )
  end
  
  
end
