class Campaign < ApplicationRecord
  
  belongs_to  :user
  belongs_to  :exchange_trading_pair
  has_many    :traders
  delegate    :exchange, :to => :exchange_trading_pair
  
  def load_tps
    tps = exchange_trading_pair.current_trading_pair_stat
    if tps.nil? or tps.updated_at < 1.minute.ago
      tps = TradingPairStat.refresh( user.authorization( exchange ) )
    end
  end
  
  def client
    authorization = user.authorization( exchange )
    authorization.client
  end
  
  def setup_data
    tps = exchange_trading_pair.current_trading_pair_stat
    if tps.nil? or tps.updated_at < 1.minute.ago
      tps = TradingPairStat.refresh( self )
    end
  end
  
  def trading_pair_stat
    tps = current_stat
    if tps.nil? or tps.updated_at < 1.minute.ago
      tps = TradingPairStat.refresh( self )
    end
    tps     
  end
  
  def symbol
    exchange_trading_pair.symbol
  end
  
end
