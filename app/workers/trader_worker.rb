class TraderWorker
  include Sidekiq::Worker

  def perform( trader_id )
    BotTrader.process_bot( trader_id )
  end
end
