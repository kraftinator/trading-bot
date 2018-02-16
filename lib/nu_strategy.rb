require './lib/trading_strategy.rb'

### Wait period should be expressed in days and not seconds
### Like Kappa but buy and sell percentage matters
### 0 buy_pct and 5-10 sell_pct recommended

class NuStrategy < TradingStrategy
  
  def buy_order_limit_price
    ## Set limit price to wait period in days
    @klines = @client.klines(symbol:@trader.trading_pair.symbol, interval:'1d', limit: @trader.wait_period)
    @klines = @klines.sort {|a,b| a[3] <=> b[3]}
    limit_price = @klines[0][3] * (1 - @trader.buy_pct.to_f)
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
  def sell_order_limit_price
    if @tps['high_price'].to_f > @current_order['price'].to_f
      limit_price =  @tps['high_price'].to_f
    else
      limit_price = @current_order['price'].to_f * 1.01
    end
    ## If last price > limit price, set limit price to last price
    limit_price = @tps['last_price'] if limit_price < @tps['last_price']
    ## Add precision to limit price. API will reject if too long.           
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
  def process_open_sell_order
    ## Get current limit order
    limit_order = @trader.current_order
    ## If high price has moved lower, then lower limit price.
    if limit_order.price.to_f > @tps['high_price']
      ## Get buy price
      buy_order = limit_order.buy_order
      if buy_order      
        ## Lower price to current high price
        if (@tps['high_price']*(1 - (@trader.sell_pct.to_f/2))) > buy_order.price.to_f
          limit_price = @tps['high_price']*(1 - (@trader.sell_pct.to_f/2))
        end
        ## Add precision to limit price. API will reject if too long.           
        limit_price = limit_price.round( @precision )
        ## Proceed if new limit price is greater than buy price.
        if limit_price > buy_order.price.to_f
          ## Cancel current order
          result = @client.cancel_order( symbol: @trader.trading_pair.symbol, orderId: limit_order.order_guid )
          if result['code']
            puts "ERROR: #{result['code']} #{result['msg']}"
            return false
          end
          puts "Order #{limit_order.order_guid} canceled."
          ## Cancel local limit order
          limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )        
          ## Create new limit order
          create_sell_order( limit_price )
        end
      end      
    end
  end
  
end