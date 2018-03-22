class ClearRecordsWorker
  include Sidekiq::Worker

  def perform
    ## Remove old trading pair stats
    stats = TradingPairStat.where( "created_at < '#{30.days.ago}'" ).all.to_a
    puts "Deleting #{stats.size} TPS records..."
    stats.each { |s| s.destroy }
    ## Remove old cancelled limit order
    orders = LimitOrder.where( "created_at < '#{30.days.ago}' and state = '#{LimitOrder::STATES[:canceled]}'" ).all.to_a
    puts "Deleting #{orders.size} cancelled orders..."
    orders.each { |o| o.destroy }
  end
  
end
