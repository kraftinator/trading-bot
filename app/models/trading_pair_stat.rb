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