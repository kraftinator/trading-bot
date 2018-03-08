class CampaignsController < ApplicationController
  
  before_action :set_campaign, only: [:show, :edit, :update, :toggle_active, :revenue]
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
    #@traders = @campaign.traders.active.to_a.sort_by( &:show_last_fulfilled_order_date ).reverse
    @traders = @campaign.traders.active.to_a.sort_by( &:last_action ).reverse
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
    
    @coin_total = @campaign.campaign_coin_total
    unless @coin_total
      @campaign.calculate_coin_totals
      @coin_total = @campaign.campaign_coin_total
    end

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
