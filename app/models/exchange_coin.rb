class ExchangeCoin < ApplicationRecord
  
  belongs_to  :exchange
  belongs_to  :coin
  has_many    :exchange_trading_pairs
  has_many    :index_funds
  
  def fiat?
    symbol == 'USD' || symbol == 'USDT'
  end
  
  def self.base_coins
    ExchangeTradingPair.all.distinct.pluck(:coin2_id).map { |exchange_coin_id| ExchangeCoin.find(exchange_coin_id) }
  end
  
  def full_display_name
    "#{exchange.name} - #{symbol}"
  end
   
end
