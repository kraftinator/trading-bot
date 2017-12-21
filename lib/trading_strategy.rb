class TradingStrategy
  
  @current_order = nil
  
  def initialize( opts={} )
    @client = opts[:client]
    @tps = opts[:client] ## Trading Pair Stats
    @trader = opts[:trader]
    @precision = opts[:precision]
  end
   
   def process
     
     #if @trader.limit_orders.any?
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
         when 'OPEN'
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
       # New bot! Create first buy order.
       create_initial_buy_order
     end
     true
   end
   
  #############################################
  #############################################
  ## TRADING STRATEGY INTERFACE
  #############################################
  #############################################
  def create_initial_buy_order
    weighted_avg_buy_order
  end
   
  def create_buy_order
    #TODO
  end
   
  def create_sell_order
    ## Get initial limit price.
    limit_price = @current_order['price'].to_f * ( 1 + @trader.percentage_range.to_f )
    ## If last price > limit price, set limit price to last price
    limit_price = @tps['last_price'] if limit_price < @tps['last_price']
    ## Add precision to limit price. API will reject if too long.           
    limit_price = limit_price.round( @precision )
    ## Set token quantity.
    qty = ( @trader.token_qty.to_f ).floor
    ## Create limit SELL order
    new_order = @client.create_order( symbol: @trader.trading_pair.symbol, side: 'SELL', type: 'LIMIT', timeInForce: 'GTC', quantity: qty, price: limit_price )
    unless new_order['code']
      limit_order = LimitOrder.create( trader: @trader, order_guid: new_order['orderId'], price: new_order['price'], qty: new_order['origQty'], side: new_order['side'], open: true )
      puts "SELL order created for Bot #{@trader.id}."
    else
      puts "ERROR: #{new_order['msg']}"
    end
  end
   
  def process_filled_buy_order
    ## Close the limit order.
    @trader.current_order.update( open: false )
    ## Update trader's coin and token quantities
    coin_qty = ( @current_order['executedQty'].to_f * @current_order['price'].to_f ).round( @precision )
    token_qty = @current_order['executedQty'].to_f
    ## Update trader
    @trader.update( coin_qty: @trader.coin_qty - coin_qty, token_qty: @trader.coin_qty + token_qty,  buy_count: @trader.buy_count + 1 )
    ## Create sell order
    create_sell_order
  end
   
  def process_filled_sell_order
    ## Yay! The order was successfully filled!
    ## Close the limit order.
    @trader.current_order.update( open: false )
    ## Update trader's coin and token quantities
    coin_qty = ( @current_order['executedQty'].to_f * @current_order['price'].to_f ).round( @precision )
    token_qty = @current_order['executedQty'].to_f
    ## Update trader
    @trader.update( coin_qty: @trader.coin_qty + coin_qty, token_qty: @trader.coin_qty - token_qty  sell_count: @trader.sell_count + 1 )
    ## Create new buy order
    create_buy_order
  end
   
  def process_open_buy_order
    
    ## Determine if limit order needs to be replaced.
    limit_order = @trader.current_order
    if @trader.wait_period.minutes.ago > limit_order.created_at
      ## Determine new limit price
      limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
      limit_price = limit_price * ( 1 - @trader.percentage_range.to_f )
      limit_price = limit_price.round( @precision )
      ## If new limit price is greater then original limit price, replace original order
      if limit_price > limit_order.price
        ## Cancel current order
        result = @client.cancel_order( symbol: trader.trading_pair.symbol, orderId: limit_order.order_guid )
        if result['code']
          puts "ERROR: #{result['code']} #{result['msg']}"
          next
        end
        limit_price.update( open: false )
        
        ## Create new limit order
        qty = ( trader.coin_qty.to_f / limit_price ).floor
        order = @client.create_order( symbol: trader.trading_pair.symbol, side: 'BUY', type: 'LIMIT', timeInForce: 'GTC', quantity: qty, price: limit_price )
        unless order['code']
          limit_order = LimitOrder.create( trader: trader, order_guid: order['orderId'], price: order['price'], qty: order['origQty'], side: order['side'], open: true )
          puts "BUY order created for Bot #{trader.id}."
        else
          puts "ERROR: #{order['msg']}"
        end
        
      else
        ## Do nothing. New limit price is greater than original limit price.
      end
      
    else
      ## Do nothing. Wait period hasn't expired.
    end
    
  end
   
   def process_open_sell_order
      ## Do nothing. Sell orders are never canceled.
    end
   
   def process_canceled_buy_order
     ## Close limit order and create new BUY order.
     limit_order = @trader.current_order
     limit_order.update( open: false )
     puts "WARNING: Buy order #{limit_order.order_guid} canceled."
     create_buy_order
   end
   
   def process_canceled_sell_order
     ## Close limit order and create new SELL order.
     limit_order = @trader.current_order
     limit_order.update( open: false )
     puts "WARNING: Sell order #{limit_order.order_guid} canceled."
     create_sell_order
   end
   
   #############################################
   #############################################
   ## HELPER METHODS
   #############################################
   #############################################
   
   def weighted_avg_buy_order
     ## Get initial limit price. Choose last price or weighted avg price, whichever is less.
     limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
     ## Get target limit price based on percentage range.
     limit_price = limit_price * ( 1 - @trader.percentage_range.to_f )
     ## Add precision to limit price. API will reject if too long.
     limit_price = limit_price.round( @precision )
     ## Get token quantity by dividing coin quantity by limit price.
     qty = ( @trader.coin_qty.to_f / limit_price ).floor
     ## Create limit order via API
     order = @client.create_order( symbol: @trader.trading_pair.symbol, side: 'BUY', type: 'LIMIT', timeInForce: 'GTC', quantity: qty, price: limit_price )
     unless order['code']
       ## Create local limit order
       limit_order = LimitOrder.create( trader: @trader, order_guid: order['orderId'], price: order['price'], qty: order['origQty'], side: order['side'], open: true )
       puts "BUY order created for Bot #{@trader.id}."
     else
       puts "ERROR: #{order['msg']}"
     end
   end
   
end