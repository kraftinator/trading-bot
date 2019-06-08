class IndexFund < ApplicationRecord
  
  belongs_to  :user
  belongs_to  :base_coin, :class_name => "ExchangeCoin"
  
  has_many  :index_fund_coins
  has_many  :index_fund_snapshots
  
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
  
  def base_coin_asset
    self.index_fund_coins.where(exchange_trading_pair: nil).first
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
        #asset.price = asset.exchange_trading_pair.cached_stats.last_price
        asset.base_coin_value = asset.qty*asset.price
      end
    end
    ## Calculate fund total
    total_base_coin_value = 0
    assets.each { |asset| total_base_coin_value+=asset.base_coin_value }
    ## Return values
    return assets, total_base_coin_value
  end
  
  def rebalance
    
    assets, fund_total = self.calculate_fund_stats
    assets.each do |asset| 
      asset.current_allocation_pct = fund_total == 0 ? 0 : asset.base_coin_value/fund_total
      asset.allocation_diff = asset.current_allocation_pct-asset.allocation_pct
    end
    assets = assets.sort_by(&:allocation_diff).reverse
    
    base_coin_asset = self.base_coin_asset
    
    ## Find sell orders
    assets.each do |asset|
      next if asset.base_coin?
      if asset.allocation_diff > 0 && asset.allocation_diff >= self.rebalance_trigger_pct
        
        puts "********** SELL ORDER FOR #{asset.coin.symbol}"
        
        
        ## Place sell order
        base_coin_sell_qty = fund_total*asset.allocation_diff
        puts "********** base_coin_sell_qty = #{base_coin_sell_qty.to_s}"
        asset_coin_sell_qty = base_coin_sell_qty/asset.price
        puts "********** asset_coin_sell_qty = #{asset_coin_sell_qty.to_s}"
        
        ## TODO: Perform market sell order
        asset.update_column(:qty, asset.qty-asset_coin_sell_qty)
        base_coin_asset.update_column(:qty, base_coin_asset.qty+base_coin_sell_qty) ## Add amount
        puts "#{asset.coin.symbol}"
      end
    end
    
    ## Find buy orders
    assets.each do |asset|
      next if asset.base_coin?
      if asset.allocation_diff < 0 && asset.allocation_diff.abs >= self.rebalance_trigger_pct
        ## Place buy order
        base_coin_buy_qty = fund_total*asset.allocation_diff.abs
        asset_coin_buy_qty = base_coin_buy_qty/asset.price
        
        ## TODO: Perform market buy order
        asset.update_column(:qty, asset.qty+asset_coin_buy_qty)
        base_coin_asset.update_column(:qty, base_coin_asset.qty-base_coin_buy_qty) ## Subtract amount
        puts "#{asset.coin.symbol}"
      end
    end

  end
  
  def deposit_total
    total = 0
    self.index_fund_coins.each do |asset|
      total+=asset.index_fund_deposits.sum(:base_coin_qty)
    end
    total
  end
  
  def deposits
    @deposits = []
    self.index_fund_coins.each { |asset| @deposits.concat(asset.index_fund_deposits) }
    @deposits = @deposits.sort_by(&:created_at).reverse
  end
  
  def snapshot_by_date(target_date)
    self.index_fund_snapshots.where("created_at < '#{target_date}'").order('created_at desc').first    
  end
  
end
