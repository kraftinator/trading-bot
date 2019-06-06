class IndexFundDeposit < ApplicationRecord
  
  belongs_to :index_fund_coin
  
  validates_presence_of :index_fund_coin_id, :qty
  
  after_create :update_index_fund_coin_qty
  
  def update_index_fund_coin_qty
    self.index_fund_coin.update_column(:qty, self.index_fund_coin.qty+self.qty)
  end
  
end
