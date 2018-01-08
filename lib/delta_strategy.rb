require './lib/trading_strategy.rb' 

class DeltaStrategy < TradingStrategy
  
  def process_open_buy_order
    ## Determine if limit order needs to be replaced.
    limit_order = @trader.current_order
    if @trader.wait_period.minutes.ago > limit_order.created_at
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
        limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )        
        ## Create new limit order
        create_buy_order( limit_price )
      end
    end    
  end

  def buy_order_limit_price
    ## Choose last price.
    limit_price = @tps['last_price']
    ## Get target limit price based on percentage range.
    limit_price = limit_price * ( 1 - @trader.percentage_range.to_f )
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
end