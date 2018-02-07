class TradingStrategyNew
  
  @current_order = nil
  
  def initialize( opts )
    @client = opts[:client]
    @trader = opts[:trader]
    @trading_pair = @trader.campaign.exchange_trading_pair
    @tps = @trading_pair.stats
    @exchange = @trader.campaign.exchange
    @eth_status = opts[:eth_status]
  end
   
  def process
     
    if @trader.current_order

      ## Retrieve order from API
      @api_order = @exchange.query_order( client: @client, symbol: @trading_pair.symbol, order_id: @trader.current_order.order_guid )

      ## Process based on order status
      if @api_order.side == 'BUY'
        case @api_order.status
        when 'FILLED'
          process_filled_buy_order
        when 'PARTIALLY_FILLED'
          process_partially_filled_buy_order
        when 'NEW'
          process_open_buy_order
        when 'CANCELED'
          process_canceled_buy_order
        end
      elsif @api_order.side == 'SELL'
        case @api_order.status
        when 'FILLED'
          process_filled_sell_order
        when 'PARTIALLY_FILLED'
          process_partially_filled_sell_order
        when 'NEW'
          process_open_sell_order
        when 'CANCELED'
          process_canceled_sell_order
        end
      end
  
    else
      
      # New bot! Create first order.
      if @trader.coin_qty > 0 and @trader.token_qty == 0
        puts "Calling create_initial_buy_order"
        create_initial_buy_order
      elsif @trader.coin_qty == 0 and @trader.token_qty > 0
        puts "Calling create_initial_sell_order"
        create_initial_sell_order
      else
        puts "WARNING: Unknown scenario for initial order for Trader #{@trader.id}."
      end
      
    end
    true
   end
   
  #############################################
  #############################################
  ## TRADING STRATEGY INTERFACE
  #############################################
  #############################################
  def create_initial_buy_order
    create_buy_order( initial_buy_order_limit_price )
  end
  
  def create_initial_sell_order
    limit_price = @tps['last_price'] * 1.005
    limit_price = limit_price.round( @trading_pair.precision )
    create_sell_order( limit_price )    
  end
   
  def create_buy_order( limit_price )
    ## Set token quantity
    qty = ( @trader.coin_qty / limit_price ).floor
    ## Create limit order via API
    new_order = @exchange.create_order( client: @client, symbol: @trading_pair.symbol, side: 'BUY', qty: qty, price: limit_price )
    ## Create local limit order
    limit_order = LimitOrder.create( trader: @trader, order_guid: new_order.uid, price: new_order.price, qty: new_order.original_qty, side: new_order.side, open: true, state: LimitOrder::STATES[:new] )
  end
   
  def create_sell_order( limit_price )
    ## Set token quantity
    qty = @trader.token_qty.floor
    ## Create limit order via API
    new_order = @exchange.create_order( client: @client, symbol: @trading_pair.symbol, side: 'SELL', qty: qty, price: limit_price )
    ## Create local limit order
    limit_order = LimitOrder.create( trader: @trader, order_guid: new_order.uid, price: new_order.price, qty: new_order.original_qty, side: new_order.side, open: true, state: LimitOrder::STATES[:new] )
  end
   
  def process_filled_buy_order
    ## Close the limit order.
    @trader.current_order.update( open: false, state: LimitOrder::STATES[:filled], filled_at: Time.current, eth_price: @eth_status['last_price'] )
    ## Update trader's coin and token quantities
    coin_qty = ( @current_order['executedQty'].to_f * @current_order['price'].to_f ).round( @trading_pair.precision )
    token_qty = @current_order['executedQty'].to_f
    
    ## Subtract trading fee
    ## NOTE: Modify to remove fee, if necessary
    token_total = current_token_balance
    if token_total < token_qty
      token_qty = ( token_qty - (token_qty * 0.001) ).floor
    end
        
    ## Update trader
    @trader.update( coin_qty: @trader.coin_qty - coin_qty, token_qty: @trader.token_qty + token_qty,  buy_count: @trader.buy_count + 1 )
    ## Create sell order
    create_sell_order( sell_order_limit_price )
  end
  
  def process_partially_filled_buy_order
    unless @trader.current_order.partially_filled_order
      PartiallyFilledOrder.create( limit_order: @trader.current_order, executed_qty: @current_order['executedQty'].to_f )
    end
  end
  
  def process_partially_filled_sell_order
    unless @trader.current_order.partially_filled_order
      PartiallyFilledOrder.create( limit_order: @trader.current_order, executed_qty: @current_order['executedQty'].to_f )
    end
  end
   
  def process_filled_sell_order
    ## Yay! The order was successfully filled!
    ## Close the limit order.
    @trader.current_order.update( open: false, state: LimitOrder::STATES[:filled], filled_at: Time.current, eth_price: @eth_status['last_price'] )
    ## Update trader's coin and token quantities
    coin_qty = ( @current_order['executedQty'].to_f * @current_order['price'].to_f ).round( @trading_pair.precision )
    token_qty = @current_order['executedQty'].to_f
    ## Update trader
    @trader.update( coin_qty: @trader.coin_qty + coin_qty, token_qty: @trader.token_qty - token_qty,  sell_count: @trader.sell_count + 1 )
    ## Create new buy order
    create_buy_order( buy_order_limit_price )
  end
   
  def process_open_buy_order
    ## Determine if limit order needs to be replaced.
    limit_order = @trader.current_order
    ## Determine new limit price
    limit_price = buy_order_limit_price
    ## If new limit price > original limit price, replace original order
    if limit_price > limit_order.price
      ## Cancel current order
      cancelled_order = @exchange.cancel_order( client: @client, symbol: @trading_pair.symbol, order_id: limit_order.order_guid )
      if cancelled_order.failed?
        puts "ERROR: #{cancelled_order.error_code} #{cancelled_order.error_msg}"
        return false
      end
      ## Cancel local limit order
      limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )
      ## Create new limit order
      create_buy_order( limit_price )
    end
  end
   
  def process_open_sell_order
    ## Get current limit order
    limit_order = @trader.current_order
    ## Lower limit price after 12 hours
    if 12.hours.ago > limit_order.created_at
      ## Get buy price
      buy_order = limit_order.buy_order
      if buy_order      
        ## Lower price to 1 percent above buy
        limit_price = buy_order.price.to_f * 1.01
        limit_price = @tps['last_price'] if limit_price < @tps['last_price']
        ## Add precision to limit price. API will reject if too long.           
        limit_price = limit_price.round( @trading_pair.precision )
        if limit_price < limit_order.price.to_f
          ## Cancel current order
          cancelled_order = @exchange.cancel_order( client: @client, symbol: @trading_pair.symbol, order_id: limit_order.order_guid )
          if cancelled_order.failed?
            puts "ERROR: #{cancelled_order.error_code} #{cancelled_order.error_msg}"
            return false
          end
          ## Cancel local limit order
          limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )        
          ## Create new limit order
          create_sell_order( limit_price )
        end
      end      
    end
  end
   
  def process_canceled_buy_order
    ## Close limit order
    limit_order = @trader.current_order
    limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )
    puts "WARNING: Buy order #{limit_order.order_guid} canceled."
    ## Create new BUY order
    create_buy_order( buy_order_limit_price )
  end
   
  def process_canceled_sell_order
    ## Close limit order
    limit_order = @trader.current_order
    limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )
    puts "WARNING: Sell order #{limit_order.order_guid} canceled."
    ## Create new SELL order
    limit_price = limit_order.price.to_f
    limit_price = @tps['last_price'] if limit_price < @tps['last_price']
    create_sell_order( limit_price )
   end
   
   #############################################
   #############################################
   ## HELPER METHODS
   #############################################
   #############################################
   def initial_buy_order_limit_price
     buy_order_limit_price
   end
   
  def buy_order_limit_price
    ## Choose last price or weighted avg price, whichever is less.
    limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
    ## Get target limit price based on percentage range.
    limit_price = limit_price * ( 1 - @trader.buy_pct.to_f )
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @trading_pair.precision )
    limit_price
  end
  
  def sell_order_limit_price
    ## Get token quantity
    qty = ( @trader.token_qty.to_f ).floor
    ## Calculate expected SELL coin total
    buy_coin_total = @current_order['executedQty'].to_f * @current_order['price'].to_f
    sell_coin_total = buy_coin_total * ( 1 + @trader.sell_pct.to_f )
    ## Calculate limit price from SELL coin total
    limit_price = sell_coin_total / qty
    ## If last price > limit price, set limit price to last price
    limit_price = @tps['last_price'] if limit_price < @tps['last_price']
    ## Add precision to limit price. API will reject if too long. 
    limit_price = limit_price.round( @trading_pair.precision )
    limit_price
  end
  
  def current_token_balance
    #account_info = @client.account_info
    #balances = account_info['balances']
    #asset = balances.select { |b| b['asset'] == @trader.trading_pair.token.symbol }.first
    #asset['free'].to_f
    @exchange.coin_balance( client: @client, coin: @trading_pair.coin1 )
  end
  
end