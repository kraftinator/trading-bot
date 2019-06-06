class IndexFundDeposit < ApplicationRecord
  
  belongs_to :index_fund_coin
  
  validates_presence_of :index_fund_coin_id, :qty, :base_coin_qty
  
  before_create :set_base_coin_qty
  after_create :update_index_fund_coin_qty
  
  def set_base_coin_qty
    if index_fund_coin.base_coin?
      self.base_coin_qty = qty
    else
      price = index_fund_coin.exchange_trading_pair.tps.last_price
      self.base_coin_qty = qty*price
    end
  end
  
  def update_index_fund_coin_qty
    self.index_fund_coin.update_column(:qty, self.index_fund_coin.qty+self.qty)
  end
  
end
