class TradingStrategy
  
  @current_order = nil
  
  def initialize( opts={} )
    @client = opts[:client]
    @tps = opts[:tps] ## Trading Pair Stats
    @trader = opts[:trader]
    @precision = opts[:precision]
  end
   
  def process
     
    if @trader.current_order
              
      ## Retrieve order from API
      @current_order = @client.query_order( symbol: @trader.trading_pair.symbol, orderId: @trader.current_order.order_guid )
       
      ## If no order found, stop processing
      return false, "ERROR: #{@current_order['code']} #{@current_order['msg']}" if @current_order['code']
       
      ## Process based on order status
      if @current_order['side'] == 'BUY'
        case @current_order['status']
        when 'FILLED'
          process_filled_buy_order
        when 'NEW'
          process_open_buy_order
        when 'CANCELED'
          process_canceled_buy_order
        end
      elsif @current_order['side'] == 'SELL'
        case @current_order['status']
        when 'FILLED'
          process_filled_sell_order
        when 'OPEN'
          process_open_sell_order
        when 'CANCELED'
          process_canceled_sell_order
        end
      end
  
    else
      
      # New bot! Create first order.
      if @trader.coin_qty.to_f > 0 and @trader.token_qty == 0
        puts "Calling create_initial_buy_order"
        create_initial_buy_order
      elsif @trader.coin_qty.to_f == 0 and @trader.token_qty > 0
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
    limit_price = @tps['last_price'] * 1.01
    limit_price = limit_price.round( @precision )
    create_sell_order( limit_price )    
  end
   
  def create_buy_order( limit_price )
    ## Get BUY order limit price
    #limit_price = buy_order_limit_price
    ## Set token quantity
    qty = ( @trader.coin_qty.to_f / limit_price ).floor
    ## Create limit order via API
    new_order = @client.create_order( symbol: @trader.trading_pair.symbol, side: 'BUY', type: 'LIMIT', timeInForce: 'GTC', quantity: qty, price: limit_price )
    if new_order['code']
      puts "ERROR: #{new_order['code']} #{new_order['msg']}"
      return false
    end
    ## Create local limit order
    limit_order = LimitOrder.create( trader: @trader, order_guid: new_order['orderId'], price: new_order['price'], qty: new_order['origQty'], side: new_order['side'], open: true )
    puts "BUY order created for Bot #{@trader.id}."
  end
   
  def create_sell_order( limit_price )
    ## Get SELL order limit price
    #limit_price = sell_order_limit_price
    ## Set token quantity
    qty = ( @trader.token_qty.to_f ).floor
    ## Create limit SELL order
    
    ## DEBUG
    puts "limit_price = #{limit_price}"
    puts "qty = #{qty}"
    
    new_order = @client.create_order( symbol: @trader.trading_pair.symbol, side: 'SELL', type: 'LIMIT', timeInForce: 'GTC', quantity: qty, price: limit_price )
    if new_order['code']
      puts "ERROR: #{new_order['code']} #{new_order['msg']}"
      return false
    end
    limit_order = LimitOrder.create( trader: @trader, order_guid: new_order['orderId'], price: new_order['price'], qty: new_order['origQty'], side: new_order['side'], open: true )
    puts "SELL order created for Bot #{@trader.id}."
  end
   
  def process_filled_buy_order
    ## Close the limit order.
    @trader.current_order.update( open: false )
    ## Update trader's coin and token quantities
    coin_qty = ( @current_order['executedQty'].to_f * @current_order['price'].to_f ).round( @precision )
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
   
  def process_filled_sell_order
    ## Yay! The order was successfully filled!
    ## Close the limit order.
    @trader.current_order.update( open: false )
    ## Update trader's coin and token quantities
    coin_qty = ( @current_order['executedQty'].to_f * @current_order['price'].to_f ).round( @precision )
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
      result = @client.cancel_order( symbol: @trader.trading_pair.symbol, orderId: limit_order.order_guid )
      if result['code']
        puts "ERROR: #{result['code']} #{result['msg']}"
        return false
      end
      puts "Order #{limit_order.order_guid} canceled."
      ## Cancel local limit order
      limit_order.update( open: false )        
      ## Create new limit order
      create_buy_order( limit_price )
    end
  end
   
  def process_open_sell_order
    ## Do nothing. Sell orders are never canceled.
  end
   
  def process_canceled_buy_order
    ## Close limit order
    limit_order = @trader.current_order
    limit_order.update( open: false )
    puts "WARNING: Buy order #{limit_order.order_guid} canceled."
    ## Create new BUY order
    create_buy_order( buy_order_limit_price )
  end
   
  def process_canceled_sell_order
    ## Close limit order
    limit_order = @trader.current_order
    limit_order.update( open: false )
    puts "WARNING: Sell order #{limit_order.order_guid} canceled."
    ## Create new SELL order
    limit_price = limit_order.price.to_f
    limit_price = @tps['last_price'] if limit_price < @tps['last_price']
    ## If last price > limit price, set limit price to last price
    #limit_price = @tps['last_price'] if limit_price < @tps['last_price']
    ## Add precision to limit price. API will reject if too long.           
    #limit_price = limit_price.round( @precision )
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
    limit_price = limit_price * ( 1 - @trader.percentage_range.to_f )
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
  def sell_order_limit_price
    ## Get token quantity
    qty = ( @trader.token_qty.to_f ).floor
    ## Calculate expected SELL coin total
    buy_coin_total = @current_order['executedQty'].to_f * @current_order['price'].to_f
    sell_coin_total = buy_coin_total * ( 1 + @trader.percentage_range.to_f )
    #sell_coin_total = sell_coin_total.floor( @precision )
    sell_coin_total = sell_coin_total #.round( @precision )
    ## Calculate limit price from SELL coin total
    limit_price = sell_coin_total / qty
    ## If last price > limit price, set limit price to last price
    limit_price = @tps['last_price'] if limit_price < @tps['last_price']
    ## Add precision to limit price. API will reject if too long. 
    #limit_price = limit_price.floor( @precision )
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
  def old_sell_order_limit_price
    ## Get initial limit price.
    limit_price = @current_order['price'].to_f * ( 1 + @trader.percentage_range.to_f )
    ## If last price > limit price, set limit price to last price
    limit_price = @tps['last_price'] if limit_price < @tps['last_price']
    ## Add precision to limit price. API will reject if too long.           
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
  def current_token_balance
    account_info = @client.account_info
    balances = account_info['balances']
    asset = balances.select { |b| b['asset'] == @trader.trading_pair.token.symbol }.first
    asset['free'].to_f
  end
  
end