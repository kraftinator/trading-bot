class ExchangeCoin < ApplicationRecord
  
  belongs_to  :exchange
  belongs_to  :coin
  has_many    :exchange_trading_pairs
  
  def fiat?
    symbol == 'USD' || symbol == 'USDT'
  end
   
end
