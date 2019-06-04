class IndexFund < ApplicationRecord
  
  belongs_to  :user
  belongs_to  :base_coin, :class_name => "ExchangeCoin"
  
  has_many  :index_fund_coins
  
  delegate  :exchange, :to => :base_coin
  
  validates :rebalance_trigger_pct, numericality: { greater_than: 0 }
  
  before_validation(on: [:create, :update]) do
    self.rebalance_trigger_pct = rebalance_trigger_pct.to_f/100.to_f
  end
  
  def allocations
    self.index_fund_coins
  end
  
  def allocation_pct_total
    self.index_fund_coins.sum(:allocation_pct)
  end
  
  def allocations_valid?
    allocation_pct_total == 1.0
  end
  
end
