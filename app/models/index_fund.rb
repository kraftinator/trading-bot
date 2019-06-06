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
  
  def fund_total
    
    assets = self.index_fund_coins
    assets.each do |asset|
      if asset.base_coin?
        asset.price = 1.0
        asset.base_coin_value = asset.qty
      else
        asset.price = self.exchange.cached_fiat_stats(asset.coin).last_price
        asset.base_coin_value = asset.qty*asset.price
      end
    end
    
    total_base_coin_value = 0
    assets.each { |asset| total_base_coin_value+=asset.base_coin_value }
    
    total_base_coin_value
  end
  
  def calculate_fund_stats
    ## Set virtual attributes of assets
    assets = self.index_fund_coins
    assets.each do |asset|
      if asset.base_coin?
        asset.price = 1.0
        asset.base_coin_value = asset.qty
      else
        #asset.price = self.exchange.cached_fiat_stats(asset.coin).last_price
        #asset.price = self.exchange.fiat_stats(asset.coin).last_price
        asset.price = asset.exchange_trading_pair.tps.last_price
        asset.base_coin_value = asset.qty*asset.price
      end
    end
    ## Calculate fund total
    total_base_coin_value = 0
    assets.each { |asset| total_base_coin_value+=asset.base_coin_value }
    ## Return values
    return assets, total_base_coin_value
  end
  
  def deposit_total
    total = 0
    self.index_fund_coins.each do |asset|
      total+=asset.index_fund_deposits.sum(:base_coin_qty)
    end
    total
  end
  
end
