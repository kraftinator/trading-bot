class CampaignsController < ApplicationController
  
  before_action :set_campaign, only: [:show, :edit]
  
  def edit
  end

  def index
    @campaigns = current_user.campaigns.all.to_a.sort_by( &:symbol )
  end

  def new
  end

  def show
    @traders = @campaign.traders.active.to_a.sort_by( &:show_last_fulfilled_order_date ).reverse
  end
  
  private
  
  def set_campaign
    @campaign = Campaign.find( params[:id] )
  end
  
end
