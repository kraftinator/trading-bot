require './lib/bot_trader.rb'

class TradingPairsController < ApplicationController
  
  before_action :set_trading_pair, only: [:show, :edit, :revenue]
  
  def edit
  end

  def index
     @trading_pairs = TradingPair.all.to_a.sort_by( &:symbol )
  end

  def new
  end

  def show
    @traders = @trading_pair.traders.active.to_a.sort_by( &:show_last_fulfilled_order_date ).reverse
  end
  
  def revenue
    ## Get bots
    @traders = @trading_pair.traders.active.to_a.sort_by( &:coin_amount ).reverse
    ## Get USD value
    client = BotTrader.client
    twenty_four_hour = client.twenty_four_hour( symbol: 'ETHUSDT' )
    @eth_price = twenty_four_hour['lastPrice'].to_f
    ## Get summary values
    @total_coin_amount = @total_profit = @total_original_coin_amount = 0
    @traders.each do |trader|
      @total_coin_amount += trader.coin_amount
      @total_profit += trader.profit
      @total_original_coin_amount += trader.original_coin_qty
    end
  end
  
  private
  
  def set_trading_pair
    @trading_pair = TradingPair.find( params[:id] )
  end
  
end
