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
    @trader = Trader.new( campaign: campaign, wait_period: 1440, active: true )
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
    
    ## Set original coin qty
    if @trader.coin_qty > 0
      @trader.original_coin_qty = @trader.coin_qty
    elsif @trader.token_qty > 0
      tps = @trader.exchange_trading_pair.tps
      @trader.original_coin_qty = @trader.token_qty * tps.last_price
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
    ## Get summary values
    @total_coin_amount = @total_profit = @total_original_coin_amount = 0
    @total_coin_amount += @trader.coin_amount
    @total_profit += @trader.profit
    @total_original_coin_amount += @trader.original_coin_qty
    ## Get fulfilled orders
    @orders = @trader.limit_orders.filled.order(' created_at desc' )
    ## Get USD value
    unless @trader.exchange_trading_pair.coin2.fiat?
      @fiat_tps = @trader.campaign.exchange.cached_fiat_stats( @trader.exchange_trading_pair.coin2 )
    end
  end

  def update
    @trader.update(trader_params)
    #redirect_to campaign_path( @trader.campaign )
    redirect_to trader_path( @trader )
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
    params.require(:trader).permit(:id, :strategy_id, :buy_pct, :sell_pct, :ceiling_pct, :loss_pct, :sell_count_trigger, :coin_qty, :token_qty, :active, :campaign_id, :wait_period, :state )
  end
  
  def set_trader
    @trader = Trader.find( params[:id] )
  end
  
  def load_trader_attributes
    @strategies = Strategy.all.order( 'name' ).to_a
  end

end
