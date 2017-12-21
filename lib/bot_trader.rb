module BotTrader

  module_function
  
  TradingPairStatus = Struct.new( :last_price, :weighted_avg_price, :high_price )
  
  def process( trading_pair )
    
    ## Get client
    api_key    = ENV['BINANCE_API_KEY']
    secret_key = ENV['BINANCE_SECRET_KEY']
    @client = Binance::Client::REST.new( api_key: api_key, secret_key: secret_key )
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
    
    ## Run bots
    traders = Trader.where( trading_pair: trading_pair, active: true ).to_a
    
    ## Any active bots found?
    if traders.any?
      ## Set precision
      @precision = 8
      ## Load 24 hour trading pair stats.
      twenty_four_hour = @client.twenty_four_hour( symbol: trading_pair.symbol )
      @tps = TradingPairStatus.new( twenty_four_hour['lastPrice'].to_f, twenty_four_hour['weightedAvgPrice'].to_f, twenty_four_hour['highPrice'].to_f )
    else
      puts "No active bots found."
      return false
    end
    
    traders.each do |trader|
      
      ## trading_strategy.new
      ## trading_strategy.process
      
      if trader.limit_orders.any?
        ## Get current order
        limit_order = trader.current_order
        ## Retrieve order from Binance
        order = @client.query_order( symbol: trader.trading_pair.symbol, orderId: limit_order.order_guid )
        ## If no order found, log and skip to next trader
        if order['code']
          puts "ERROR: #{order['code']} #{order['msg']}"
          next
        end
        
        ###############
        ## BUY ORDER
        ###############
        if order['side'] == 'BUY'
          
          ## FILLED
          if order['status'] == 'FILLED'
            ## TODO
            ## Close the limit order.
            limit_order.update_attribute( :open, false )
            ## Update trader's coin and token quantities
            coin_qty = ( order['executedQty'].to_f * order['price'].to_f ).round( precision )
            token_qty = order['executedQty'].to_f
            ## Update trader
            trader.update( coin_qty: trader.coin_qty - coin_qty, token_qty: trader.coin_qty + token_qty,  buy_count: trader.buy_count + 1 )
            ###############
            ## Create sell order
            ###############
            limit_price = order['price'].to_f * ( 1 + trader.percentage_range.to_f )
            limit_price = @tps['last_price'] if limit_price < @tps['last_price']              
            limit_price = limit_price.round( @precision )
            qty = ( trader.token_qty.to_f ).floor

            ## Create limit SELL order
            order = @client.create_order( symbol: trader.trading_pair.symbol, side: 'SELL', type: 'LIMIT', timeInForce: 'GTC', quantity: qty, price: limit_price )
            unless order['code']
              limit_order = LimitOrder.create( trader: trader, order_guid: order['orderId'], price: order['price'], qty: order['origQty'], side: order['side'], open: true )
              puts "SELL order created for Bot #{trader.id}."
            else
              puts "ERROR: #{order['msg']}"
            end
            
          ## OPEN
          elsif order['status'] == 'OPEN'
            ## Determine if limit order needs to be replaced.
            if trader.wait_period.minutes.ago > limit_order.created_at
              ## Determine new limit price
              limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
              limit_price = limit_price * ( 1 - trader.percentage_range.to_f )
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
          ## CANCELED
          elsif order['status'] == 'CANCELED'
            ## TODO
          else
            ## Other status. Do nothing.
          end
        
        ###############
        ## SELL ORDER
        ###############
        elsif order['side'] == 'SELL'
          if order['status'] == 'FILLED'
            ## Yay! The order was successfully filled!
            ## Close the limit order.
            limit_order.update_attribute( :open, false )
            ## Update trader's coin and token quantities
            coin_qty = ( order['executedQty'].to_f * order['price'].to_f ).round( precision )
            token_qty = order['executedQty'].to_f
            ## Update trader
            trader.update( coin_qty: trader.coin_qty + coin_qty, token_qty: trader.coin_qty - token_qty  sell_count: trader.sell_count + 1 )
            ## Create new buy order
            initial_order( trader )
          elsif order['status'] == 'OPEN'
            ## Do nothing. Sell orders are NEVER canceled.
          elsif order['status'] == 'CANCELED'
            ## Close limit order and create new sell order.
            limit_order.update_attribute( :open, false )
            puts "WARNING: Sell order #{limit_order.order_guid} canceled."
          else
            ## Do nothing
          end
          
        else
          ## Neither SELL nor BUY. Do nothing.
        end
        
      else
        ## New bot! 
        initial_order( trader )
      end

    end
    
  end
  
=begin
Get 24 hour weighted average

If lastPrice < weightedAvgPrice
  limitPrice = lastPrice - percentage  ## percentage might need to be algorithmic
else
  limitPrice = weightedAvgPrice - percentage
end

Create limit buy order
  

    
order = @client.create_order( symbol: trader.trading_pair.symbol, side: 'BUY', type: 'LIMIT', timeInForce: 'GTC', quantity: qty, price: limit_price )
  
 => {"symbol"=>"REQETH", "orderId"=>2758488, "clientOrderId"=>"ZhqCndMu8vsIBw5WpSoGPh", "transactTime"=>1513782398591, "price"=>"0.00032954", 
  "origQty"=>"151.00000000", "executedQty"=>"0.00000000", "status"=>"NEW", "timeInForce"=>"GTC", "type"=>"LIMIT", "side"=>"BUY"}   

#####
@client.query_order( symbol: trader.trading_pair.symbol, orderId: "2758488" )
 => {"code"=>-2013, "msg"=>"Order does not exist."}
#####
  
=end  
  
  #client.create_order symbol: 'XRPETH', side: 'BUY', type: 'LIMIT', timeInForce: 'GTC', quantity: '100.00000000', price: '0.00055000'
  
  def initial_order( trader )
    limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
    limit_price = limit_price * ( 1 - trader.percentage_range.to_f )
    limit_price = limit_price.round( @precision )
    qty = ( trader.coin_qty.to_f / limit_price ).floor
    ## Create limit order
    order = @client.create_order( symbol: trader.trading_pair.symbol, side: 'BUY', type: 'LIMIT', timeInForce: 'GTC', quantity: qty, price: limit_price )
    unless order['code']
      limit_order = LimitOrder.create( trader: trader, order_guid: order['orderId'], price: order['price'], qty: order['origQty'], side: order['side'], open: true )
      puts "BUY order created for Bot #{trader.id}."
    else
      puts "ERROR: #{order['msg']}"
    end
  end
  

  
end