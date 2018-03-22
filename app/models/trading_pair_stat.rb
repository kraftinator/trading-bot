class TradingPairStat < ApplicationRecord
  
  belongs_to  :exchange_trading_pair
  
  def stale?
    updated_at < 1.minute.ago
  end
  
  def self.refresh( exchange_trading_pair )
    exchange = exchange_trading_pair.exchange
    authorization = exchange.authorization( User.first )
    client = authorization.client
  end
  
  def self.standard_deviation( etp, time_period )
    stats = etp.trading_pair_stats.where( "created_at > '#{time_period.hours.ago}'" ).order( 'created_at asc' ).all.to_a
    mean = stats.sum( &:last_price ) / stats.size
    distance_squared_list = []
    stats.each do |tps|
      distance = tps.last_price - mean
      distance_squared_list << ( distance * distance )
    end
    distance_squared_sum = distance_squared_list.sum
    distance_squared_avg = distance_squared_sum / stats.size
    sd = Math.sqrt( distance_squared_avg )
    sd
  end
  
  ## Print trading pair stats
  def show
    output = []
    output << "----------------------------"
    output << "Trading Pair:       #{exchange_trading_pair.display_name}"
    output << "Last Price:         #{last_price}"
    output << "Low Price:          #{low_price}"
    output << "High Price:         #{high_price}"
    output << "Weighted Avg Price: #{weighted_avg_price}"
    output << "Price Pct Change:   #{price_change_pct}"
    output << "Volume:             #{volume}"
    output << "Bid Total:          #{bid_total}"
    output << "Ask Total:          #{ask_total}"
    output << "----------------------------"
    puts output
  end
  
  
end