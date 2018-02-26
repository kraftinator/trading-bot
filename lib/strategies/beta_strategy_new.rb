require './lib/strategies/trading_strategy_new.rb' 

class BetaStrategyNew < TradingStrategyNew
  
  def process_open_buy_order
    ## Determine if limit order needs to be replaced.
    limit_order = @trader.current_order
    if @trader.wait_period.minutes.ago > limit_order.created_at
      ## Determine new limit price
      limit_price = buy_order_limit_price
      ## If new limit price > original limit price, replace original order
      if limit_price > limit_order.price
        ## Cancel current order
        @trader.cancel_current_order
        ## Create new limit order
        create_buy_order( limit_price )
      end
    end    
  end
  
end