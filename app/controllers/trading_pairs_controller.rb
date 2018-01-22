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
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
    response = HTTParty.get("https://api.etherscan.io/api?module=stats&action=ethprice")
    @current_price = response.parsed_response['result']['ethusd'].to_f
    @coin_total = 0.0
    @profit_total = 0.0
    @original_total = 0.0
    
    @traders.each do |trader|
      @coin_total += trader.coin_amount
      @profit_total +=trader.profit
      @original_total += trader.original_coin_qty
    end
    
    @coin_total_dollars = formatted_currency(@coin_total * @current_price)
    @profit_total_dollars = formatted_currency(@profit_total * @current_price)
    @original_total_dollars = formatted_currency(@original_total * @current_price)
    
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
  
  def formatted_currency( amount )
    amount = '%.2f' % amount
    '$' + amount
  end
  
end
