class IndexFundCoin < ApplicationRecord
  
  belongs_to  :index_fund
  belongs_to  :exchange_trading_pair, optional: true
  
  has_many  :index_fund_orders
  has_many  :index_fund_deposits
  
  attr_accessor :price
  attr_accessor :base_coin_value
  attr_accessor :current_allocation_pct
  attr_accessor :allocation_diff
  
  validates :allocation_pct, numericality: { greater_than: 0 }
  
  validate :percentage_total, :unique_allocations

  before_validation(on: [:create, :update]) do
    self.allocation_pct = allocation_pct.to_f/100.to_f
  end
  
  def percentage_total
    current_total = self.allocation_pct
    self.index_fund.index_fund_coins.each { |ifc| current_total += ifc.allocation_pct if ifc.id != self.id }
    if current_total > 1.0
      errors.add(:allocation_pct, 'allocations cannot exceed 100%')
    end
  end
  
  def unique_allocations
    if self.index_fund.index_fund_coins.any? { |ifc| ifc.exchange_trading_pair == self.exchange_trading_pair if ifc.id != self.id }
      errors.add(:exchange_trading_pair, 'already exists')
    end
  end
  
  def coin
    if exchange_trading_pair
      exchange_trading_pair.coin1
    else
      index_fund.base_coin
    end
  end
  
  def base_coin?
    exchange_trading_pair.nil?
  end
  
  def coin_symbol
    coin.symbol
  end
  
  def qty_precision
    if self.exchange_trading_pair
      return exchange_trading_pair.qty_precision
    else
      return self.coin.precision
    end
  end
  
end
