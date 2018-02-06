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
  
end