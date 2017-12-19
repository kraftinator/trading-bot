class TradingPair < ApplicationRecord
  
  belongs_to  :coin
  belongs_to  :token
  
  has_many  :traders
  
  def symbol
    "#{token.symbol}#{coin.symbol}"
  end
  
end
