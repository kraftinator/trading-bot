require './lib/bot_trader.rb'

class CampaignWorker
  include Sidekiq::Worker

  def perform( campaign_id )
    BotTrader.process_campaign( campaign_id )
  end
  
end
