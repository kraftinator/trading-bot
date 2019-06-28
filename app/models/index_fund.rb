class IndexFund < ApplicationRecord
  
  belongs_to  :user
  belongs_to  :base_coin, :class_name => "ExchangeCoin"
  
  has_many  :index_fund_coins
  has_many  :index_fund_snapshots
  
  delegate  :exchange, :to => :base_coin
  
  validates :rebalance_trigger_pct, numericality: { greater_than: 0 }
  
  scope :active, -> { where( active: true ) }
  scope :inactive, -> { where( active: false ) }
  
  before_validation(on: [:create, :update]) do
    self.rebalance_trigger_pct = rebalance_trigger_pct.to_f/100.to_f
  end
  
  def allocations
    self.index_fund_coins
  end
  
  def assets
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
  
  def client
    authorization = self.user.authorization(self.exchange)
    authorization.client
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
        
        #asset.price = asset.exchange_trading_pair.tps.last_price
        asset.price = self.exchange.last_price(client: client, trading_pair: asset.exchange_trading_pair)
        ## Get asset prices

        #prices = self.exchange.prices(client: client, trading_pair: asset.exchange_trading_pair)
        #asset.price = (prices[:ask_price]+prices[:bid_price])/2

        asset.base_coin_value = asset.qty*asset.price
      end
    end
    ## Calculate fund total
    total_base_coin_value = 0
    assets.each { |asset| total_base_coin_value+=asset.base_coin_value }
    ## Return values
    return assets, total_base_coin_value
  end
  
  def rebalance_list
    
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

  end # rebalance
    
  def process_open_buy_orders(asset)
    return if asset.base_coin?
    @client = client
    base_coin_asset = self.base_coin_asset
    trading_pair = asset.exchange_trading_pair
    asset.index_fund_orders.where(open: true, side: 'BUY').each do |order|
      api_order = self.exchange.query_order(client: @client, trading_pair: trading_pair, order_id: order.order_uid)
      if api_order.status == LimitOrder::STATES[:filled] || api_order.status == LimitOrder::STATES[:partially_filled]
        
        order.update(open: false, state: LimitOrder::STATES[:filled], filled_at: Time.current)
        base_coin_buy_qty = ((api_order.executed_qty*api_order.price)+api_order.fee).truncate(trading_pair.price_precision)
        asset_coin_buy_qty = api_order.executed_qty
        
        asset.update_column(:qty, asset.qty+asset_coin_buy_qty)
        base_coin_asset.update_column(:qty, base_coin_asset.qty-base_coin_buy_qty)
        
        if api_order.status == LimitOrder::STATES[:partially_filled]
          cancelled_order = self.exchange.cancel_order(client: @client, trading_pair: trading_pair, order_id: order.order_uid)
          if cancelled_order.success?
            order.update(open: false, state: LimitOrder::STATES[:canceled])
          else
            puts cancelled_order.print_error_msg
          end
        end
        
      else
        cancelled_order = self.exchange.cancel_order(client: @client, trading_pair: trading_pair, order_id: order.order_uid)
        if cancelled_order.success?
          order.update(open: false, state: LimitOrder::STATES[:canceled])
        else
          puts cancelled_order.print_error_msg
        end
      end
      
    end    
  end
  
  def process_open_sell_orders(asset)
    return if asset.base_coin?
    @client = client
    base_coin_asset = self.base_coin_asset
    trading_pair = asset.exchange_trading_pair
    asset.index_fund_orders.where(open: true, side: 'SELL').each do |order|
      api_order = self.exchange.query_order(client: @client, trading_pair: trading_pair, order_id: order.order_uid)
      if api_order.status == LimitOrder::STATES[:filled] || api_order.status == LimitOrder::STATES[:partially_filled]
        
        order.update(open: false, state: LimitOrder::STATES[:filled], filled_at: Time.current)
        base_coin_sell_qty = ((api_order.executed_qty*api_order.price)-api_order.fee).round(trading_pair.price_precision)
        asset_coin_sell_qty = api_order.executed_qty
        
        asset.update_column(:qty, asset.qty-asset_coin_sell_qty)
        base_coin_asset.update_column(:qty, base_coin_asset.qty+base_coin_sell_qty)
        
        if api_order.status == LimitOrder::STATES[:partially_filled]
          cancelled_order = self.exchange.cancel_order(client: @client, trading_pair: trading_pair, order_id: order.order_uid)
          if cancelled_order.success?
            order.update(open: false, state: LimitOrder::STATES[:canceled])
          else
            puts cancelled_order.print_error_msg
          end
        end
        
      else
        cancelled_order = self.exchange.cancel_order(client: @client, trading_pair: trading_pair, order_id: order.order_uid)
        if cancelled_order.success?
          order.update(open: false, state: LimitOrder::STATES[:canceled])
        else
          puts cancelled_order.print_error_msg
        end
      end
      
    end    
  end
  
  def rebalance
    
    
    assets, fund_total = self.calculate_fund_stats
    
    assets.each do |asset| 
      asset.current_allocation_pct = fund_total == 0 ? 0 : asset.base_coin_value/fund_total
      asset.allocation_diff = asset.current_allocation_pct-asset.allocation_pct
    end
    assets = assets.sort_by(&:allocation_diff).reverse
    
    base_coin_asset = self.base_coin_asset
    @client = client
    
    ## Find sell orders
    assets.each do |asset|
      next if asset.base_coin?
      if asset.allocation_diff > 0 && asset.allocation_diff >= self.rebalance_trigger_pct
        puts "------------------------------"
        puts "Creating SELL Order: #{asset.coin.symbol}"
        puts "asset.allocation_diff = #{asset.allocation_diff}"
        puts "self.rebalance_trigger_pct = #{self.rebalance_trigger_pct}"
        ## Place sell order
        trading_pair = asset.exchange_trading_pair
        prices = self.exchange.prices(client: @client, trading_pair: trading_pair)
        base_coin_sell_qty = fund_total*asset.allocation_diff
        asset_coin_sell_qty = (base_coin_sell_qty/prices[:ask_price]).truncate(trading_pair.qty_precision)
        
        ## TODO: Perform market sell order
        ## Get prices
        #trading_pair = asset.exchange_trading_pair
        #@client = client
        #new_order = self.exchange.create_order(client: @client, trading_pair: trading_pair, side: 'SELL', qty: qty, price: limit_price )
        new_order = self.exchange.create_order(client: @client, trading_pair: trading_pair, side: 'SELL', qty: asset_coin_sell_qty, price: prices[:ask_price])
        new_order.show
        if new_order.success?
          ## Create local limit order
          index_fund_order = IndexFundOrder.create(index_fund_coin: asset, order_uid: new_order.uid, price: new_order.price, qty: new_order.original_qty, side: new_order.side, open: true, state: LimitOrder::STATES[:new])
        else
          puts new_order.print_error_msg
          return false
        end
        
        #asset.update_column(:qty, asset.qty-asset_coin_sell_qty)
        #base_coin_asset.update_column(:qty, base_coin_asset.qty+base_coin_sell_qty) ## Add amount
        #puts "#{asset.coin.symbol}"
      end
    end
    
    ## Find buy orders
    assets.each do |asset|
      next if asset.base_coin?
      if asset.allocation_diff < 0 && asset.allocation_diff.abs >= self.rebalance_trigger_pct
        puts "------------------------------"
        puts "Creating BUY Order: #{asset.coin.symbol}"
        puts "asset.allocation_diff.abs = #{asset.allocation_diff.abs}"
        puts "self.rebalance_trigger_pct = #{self.rebalance_trigger_pct}"
        
        ## Place buy order
        trading_pair = asset.exchange_trading_pair
        prices = self.exchange.prices(client: @client, trading_pair: trading_pair)
        base_coin_buy_qty = fund_total*asset.allocation_diff.abs
        #asset_coin_buy_qty = (base_coin_buy_qty/asset.price).truncate(trading_pair.qty_precision)
        asset_coin_buy_qty = (base_coin_buy_qty/prices[:bid_price]).truncate(trading_pair.qty_precision)
        new_order = self.exchange.create_order(client: @client, trading_pair: trading_pair, side: 'BUY', qty: asset_coin_buy_qty, price: prices[:bid_price] )
        new_order.show
        if new_order.success?
          ## Create local limit order
          #limit_order = LimitOrder.create( trader: @trader, order_uid: new_order.uid, price: new_order.price, qty: new_order.original_qty, side: new_order.side, open: true, state: LimitOrder::STATES[:new] )
          index_fund_order = IndexFundOrder.create(index_fund_coin: asset, order_uid: new_order.uid, price: new_order.price, qty: new_order.original_qty, side: new_order.side, open: true, state: LimitOrder::STATES[:new])
        else
          puts new_order.print_error_msg
          return false
        end
        
        
        #asset.update_column(:qty, asset.qty+asset_coin_buy_qty)
        #base_coin_asset.update_column(:qty, base_coin_asset.qty-base_coin_buy_qty) ## Subtract amount
        #puts "#{asset.coin.symbol}"
      end
    end

  end # rebalance
  
  def liquidate
    @client = client
    self.update_column(:active, false)
    self.assets.each do |asset|
      next if asset.base_coin? || asset.qty <= 0
      ## Place sell order
      trading_pair = asset.exchange_trading_pair
      prices = self.exchange.prices(client: @client, trading_pair: trading_pair)
      asset_coin_sell_qty = asset.qty.truncate(trading_pair.qty_precision)
      new_order = self.exchange.create_order(client: @client, trading_pair: trading_pair, side: 'SELL', qty: asset_coin_sell_qty, price: prices[:ask_price])
      new_order.show
      if new_order.success?
        ## Create local limit order
        index_fund_order = IndexFundOrder.create(index_fund_coin: asset, order_uid: new_order.uid, price: new_order.price, qty: new_order.original_qty, side: new_order.side, open: true, state: LimitOrder::STATES[:new])
      else
        puts new_order.print_error_msg
        return false
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
  
  def orders
    orders = []
    self.index_fund_coins.each { |asset| orders.concat(asset.index_fund_orders.non_canceled) }
    orders.sort_by(&:created_at).reverse
  end
  
  def snapshot_by_date(target_date)
    self.index_fund_snapshots.where("created_at < '#{target_date}'").order('created_at desc').first    
  end
  
end
