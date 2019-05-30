class IndexFund < ApplicationRecord
  
  belongs_to  :user
  belongs_to  :base_coin, :class_name => "ExchangeCoin"
  
  has_many  :index_fund_coins
  
  delegate  :exchange, :to => :base_coin
  
  def allocations
    self.index_fund_coins
  end
  
end
