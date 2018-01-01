require './lib/trading_strategy.rb' 

class BetaStrategy < TradingStrategy
  
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
        ## Cancel local limit order
        limit_order.update( open: false )        
        ## Create new limit order
        create_buy_order( limit_price )
      end
    end    
  end
  
end