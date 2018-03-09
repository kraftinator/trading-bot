class CampaignCoinTotalWorker
  include Sidekiq::Worker

  def perform( campaign_id )
    campaign = Campaign.find( campaign_id )
    puts "Calculating coin totals for Campaign #{campaign.id}."
    campaign.calculate_coin_totals
  end
  
end
