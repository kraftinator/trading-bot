require './lib/strategies/trading_strategy_new.rb'

class TauStrategyNew < TradingStrategyNew
  
  def buy_order_limit_price
    ## Choose last price or weighted avg price, whichever is less.
    limit_price = ( @tps.last_price < @tps.weighted_avg_price ) ? @tps.last_price : @tps.weighted_avg_price    
    if @trader.sell_count_trigger > 0 && @trader.sell_count > 0 && @trader.sell_count % @trader.sell_count_trigger == 0
      ## Sell Count Trigger activated. Enter Iota mode.
      limit_price = limit_price * ( 1 - @trader.buy_pct - 0.05 )
    else
      ## Get target limit price based on percentage range.
      limit_price = limit_price * ( 1 - @trader.buy_pct )
    end
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @trading_pair.price_precision )
    limit_price
  end

end