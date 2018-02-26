require './lib/strategies/trading_strategy_new.rb' 

class KappaStrategyNew < TradingStrategyNew
  
  def buy_order_limit_price
    ## Set limit price to low price
    limit_price =  @tps.low_price
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @trading_pair.price_precision )
    limit_price
  end
  
  def sell_order_limit_price
    if @tps.high_price > @api_order.price
      limit_price =  @tps.high_price
    else
      limit_price = @api_order.price * 1.01
    end
    ## If last price > limit price, set limit price to last price
    limit_price = @tps.last_price if limit_price < @tps.last_price
    ## Add precision to limit price. API will reject if too long.           
    limit_price = limit_price.round( @trading_pair.price_precision )
    limit_price
  end
  
  def process_open_sell_order
    ## Get current limit order
    limit_order = @trader.current_order
    ## If high price has moved lower, then lower limit price.
    if limit_order.price > @tps.high_price
      ## Get buy price
      buy_order = limit_order.buy_order
      if buy_order      
        ## Lower price to current high price
        limit_price = @tps.high_price
        ## Add precision to limit price. API will reject if too long.           
        limit_price = limit_price.round( @trading_pair.price_precision )
        ## Proceed if new limit price is greater than buy price.
        if limit_price > buy_order.price
          ## Cancel current order
          @trader.cancel_current_order   
          ## Create new limit order
          create_sell_order( limit_price )
        end
      end      
    end
  end
  
end