class CampaignsController < ApplicationController
  
  before_action :set_campaign, only: [:show, :edit, :update, :toggle_active]
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
    @traders = @campaign.traders.active.to_a.sort_by( &:show_last_fulfilled_order_date ).reverse
  end
  
  def toggle_active
    if @campaign.active?
      @campaign.disable
    else
      @campaign.enable
    end
    redirect_to campaigns_path
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
