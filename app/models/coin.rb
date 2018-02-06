class Coin < ApplicationRecord
  
  has_many  :trading_pairs
  has_many  :exchange_coins
  
end
