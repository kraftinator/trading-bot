class CampaignsController < ApplicationController
  
  before_action :set_campaign, only: [:show, :edit, :update, :toggle_active, :revenue, :price_history]
  before_action :load_campaign_attributes, only: [:new, :edit]

  def index
    @campaigns = current_user.campaigns.all.to_a.sort_by( &:symbol )
  end

  def new
    @campaign = Campaign.new
  end
  
  def create
    @campaign = Campaign.new( campaign_params )
    @campaign.user = current_user
    if @campaign.save
      redirect_to campaigns_path
    else
      flash.now[:alert] = @campaign.errors.full_messages.to_sentence
      load_campaign_attributes
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @campaign.update( campaign_params )
      redirect_to campaign_path( @campaign )
    else
      flash.now[:alert] = @campaign.errors.full_messages.to_sentence
      load_campaign_attributes
      render :edit
    end
  end

  def show
    ## Get traders
    @traders = @campaign.traders.active.to_a.sort_by( &:last_action ).reverse
    ## Revenue stats
    unless @campaign.exchange_trading_pair.coin2.fiat?
      fiat_tps = @campaign.exchange.cached_fiat_stats( @campaign.exchange_trading_pair.coin2 )
      @fiat_price = fiat_tps.last_price      
    end
    
    #@coin_total = @campaign.campaign_coin_total
    #unless @coin_total
    #  @campaign.calculate_coin_totals
    #  @coin_total = @campaign.campaign_coin_total
    #end
    @coin_total = @campaign.cached_stats
    
    ##########
    one_day_coin_total = @campaign.historical_stats( 1.day.ago )
    three_day_coin_total = @campaign.historical_stats( 3.days.ago )
    seven_day_coin_total = @campaign.historical_stats( 7.days.ago )
    
    ## init variables
    @one_day_pct_change = @three_day_pct_change = @seven_day_pct_change = 0
    ##########
    if one_day_coin_total
      @one_day_pct_change = ( ( @coin_total.projected_coin2_total / one_day_coin_total.projected_coin2_total - 1 ) * 100 )
    end
    if three_day_coin_total
      @three_day_pct_change = ( ( @coin_total.projected_coin2_total / three_day_coin_total.projected_coin2_total - 1 ) * 100 )
    end
    if seven_day_coin_total
      @seven_day_pct_change = ( ( @coin_total.projected_coin2_total / seven_day_coin_total.projected_coin2_total - 1 ) * 100 )
    end
    ##########
    
    ## Get stats
    @tps = @campaign.exchange_trading_pair.cached_stats
    ## Get highest buy order
    buy_bots = @traders.select{ |bot| bot.current_order.side == 'BUY' if bot.current_order }
    max_buy_bot = buy_bots.max_by{ |bot| bot.current_order.price }
    @highest_buy_price = max_buy_bot.current_order.price if max_buy_bot
    ## Get lowest sell order
    sell_bots = @traders.select{ |bot| bot.current_order.side == 'SELL' if bot.current_order }
    min_sell_bot = sell_bots.min_by{ |bot| bot.current_order.price if bot.current_order and bot.current_order.side == 'SELL' }
    @lowest_sell_price = min_sell_bot.current_order.price if min_sell_bot
    ## Get spread pct
    if @highest_buy_price and @lowest_sell_price
      @spread_pct = ( @lowest_sell_price - @highest_buy_price ) / @highest_buy_price
    end
  end
  
  
  def toggle_active
    if @campaign.active?
      @campaign.disable
    else
      @campaign.enable
    end
    redirect_to campaigns_path
  end
  
  def revenue
    
    ## Get bots
    @traders = @campaign.traders.active.to_a.sort_by( &:coin_amount ).reverse
    
    ## Get USD value
    unless @campaign.exchange_trading_pair.coin2.fiat?
      fiat_tps = @campaign.exchange.cached_fiat_stats( @campaign.exchange_trading_pair.coin2 )
      @fiat_price = fiat_tps.last_price      
    end
    
    ## Get summary values
    #@total_coin_amount = @total_profit = @total_original_coin_amount = 0
    #@traders.each do |trader|
    #  @total_coin_amount += trader.coin_amount
    #  @total_profit += trader.profit
    #  @total_original_coin_amount += trader.original_coin_qty
    #end
    
    @coin_total = @campaign.cached_stats
    #@coin_total = @campaign.campaign_coin_total
    #unless @coin_total
    #  @campaign.calculate_coin_totals
    #  @coin_total = @campaign.campaign_coin_total
    #end

  end
  
  def revenue_report
    campaigns = current_user.campaigns.active.all.to_a
    @revenue_report = []
    campaigns.each do |campaign|
      row = {}
      row[:campaign] = campaign
      
      coin_total = campaign.cached_stats
      ##########
      fiat_value = coin_total.projected_coin2_total
      unless campaign.exchange_trading_pair.coin2.fiat?
        fiat_tps = campaign.exchange.cached_fiat_stats( campaign.exchange_trading_pair.coin2 )
        fiat_value = fiat_value * fiat_tps.last_price
      end
      row[:fiat_value] = fiat_value
      ##########
      one_day_coin_total = campaign.historical_stats( 1.day.ago )
      three_day_coin_total = campaign.historical_stats( 3.days.ago )
      seven_day_coin_total = campaign.historical_stats( 7.days.ago )
      ##########
      if one_day_coin_total
        row[:one_day_pct_change] = ( ( coin_total.projected_coin2_total / one_day_coin_total.projected_coin2_total - 1 ) * 100 )
      else
        row[:one_day_pct_change] = 0
      end
      if three_day_coin_total  
        row[:three_day_pct_change] = ( ( coin_total.projected_coin2_total / three_day_coin_total.projected_coin2_total - 1 ) * 100 )
      else
        row[:three_day_pct_change] = 0
      end
      if seven_day_coin_total
        row[:seven_day_pct_change] = ( ( coin_total.projected_coin2_total / seven_day_coin_total.projected_coin2_total - 1 ) * 100 )
      else
        row[:seven_day_pct_change] = 0
      end
      ##########
      if coin_total.profit > 0 and coin_total.initial_coin2_total > 0
        row[:profit_ratio] = ( ( coin_total.profit / coin_total.initial_coin2_total ) * 100 )
      else
        row[:profit_ratio] = 0
      end
      
      @revenue_report << row
      
      ## Sort
      @revenue_report = @revenue_report.sort_by { |rr| rr[:fiat_value] }.reverse
      
    end
  end
  
  def price_history
    @stats = @campaign.exchange_trading_pair.trading_pair_stats.where( "created_at > '#{24.hours.ago}'" ).order( 'created_at asc' ).all.to_a
    #@stats = @campaign.exchange_trading_pair.trading_pair_stats.order( 'created_at asc' ).all.to_a
  end

  private
  
  def set_campaign
    @campaign = Campaign.find( params[:id] )
  end
  
  def campaign_params
    params.require( :campaign ).permit( :exchange_trading_pair_id, :max_price )
  end
  
  def load_campaign_attributes
    @exchange_trading_pairs = ExchangeTradingPair.all.to_a.sort_by( &:full_display_name )
  end
  
end
