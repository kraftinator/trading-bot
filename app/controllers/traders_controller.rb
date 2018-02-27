require './lib/bot_trader.rb'

class TradersController < ApplicationController
  
  before_action :set_trader, only: [:show, :edit, :update, :order_history, :transactions]
  before_action :load_trader_attributes, only: [:new]
  
  def edit
    @strategies = Strategy.all.order( 'name' )
  end

  def index
    @traders = current_user.traders.active.to_a.sort_by( &:avg_sells_per_day ).reverse
  end

  def new
    campaign = Campaign.find( params[:campaign_id] )
    @trader = Trader.new( campaign: campaign, wait_period: 1440, active: true)
  end
  
  def create
    @trader = Trader.new( trader_params )
    @trader.user = current_user
    

    ## Validate iniital coin quantities
    error_msg = nil
    if @trader.coin_qty == 0 && @trader.token_qty == 0
      error_msg = "Coin quantity is required"
    elsif @trader.coin_qty > 0 && @trader.token_qty > 0
      error_msg = "At least one coin quantity must be 0"
    elsif @trader.coin_qty < 0 || @trader.token_qty < 0
      error_msg = "Coin quantity cannot be less than 0"
    end
    
    if error_msg
      flash[:error] = error_msg
      load_trader_attributes
      return redirect_to campaign_traders_new_path( @trader.campaign )
    end
    
    if @trader.save
      redirect_to campaign_path( @trader.campaign )
    else
      flash[:error] = @trader.errors.full_messages.to_sentence
      load_trader_attributes
      redirect_to campaign_traders_new_path( @trader.campaign )
    end
    
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
  
  def transactions
    orders = @trader.limit_orders.filled.order( "created_at desc" ).to_a
    @transactions = []
    orders.each do |order|
      transaction = {}
      if order.side == 'SELL'
        buy_order = order.previous_order
        if buy_order
          transaction[:buy_order] = buy_order
          orders.delete_if { |o| o == buy_order }
        end
        transaction[:sell_order] = order
      elsif order.side == 'BUY'
        transaction[:buy_order] = order
      end
      @transactions << transaction
    end
  end
  
  private
  
  def trader_params
    params.require(:trader).permit(:id, :strategy_id, :buy_pct, :sell_pct, :ceiling_pct, :sell_count_trigger, :coin_qty, :token_qty, :active, :campaign_id, :wait_period )
  end
  
  def set_trader
    @trader = Trader.find( params[:id] )
  end
  
  def load_trader_attributes
    @strategies = Strategy.all.order( 'name' ).to_a
  end

end
